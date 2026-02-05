import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/host.dart';
import '../../providers/hosts_provider.dart';
import '../../providers/ssh_provider.dart';
import '../../services/health_service.dart';
import '../screens/ssh_screen.dart';

class HealthPopup extends ConsumerWidget {
  final Host host;

  const HealthPopup({super.key, required this.host});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(hostHealthProvider(host.id));

    return AlertDialog(
      title: Text(host.name),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildInfoRow('Address', host.address),
            _buildInfoRow('User', host.username),
            _buildInfoRow('Root Enabled', host.rootAccess ? 'Yes' : 'No'),
            const Divider(),
            const Text('Status:', style: TextStyle(fontWeight: FontWeight.bold)),
            _buildStatusContent(health),
            const Divider(),
            const Text('Actions:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildActions(context, ref),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        ElevatedButton.icon(
          onPressed: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SshScreen(host: host)),
            );
          },
          icon: const Icon(Icons.terminal),
          label: const Text('SSH'),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  Widget _buildStatusContent(HostHealth health) {
    if (health.status == HealthStatus.checking) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (health.status == HealthStatus.offline) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text('Offline: ${health.message ?? "Unknown error"}',
            style: const TextStyle(color: Colors.red)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Uptime: ${health.uptime ?? "Unknown"}'),
        const SizedBox(height: 8),
        const Text('Failed Services:', style: TextStyle(fontWeight: FontWeight.bold)),
        if (health.failedServices.isEmpty)
          const Text('  None', style: TextStyle(color: Colors.green))
        else
          ...health.failedServices.map((s) => Text('  • $s', style: const TextStyle(color: Colors.red))),
        const SizedBox(height: 8),
        const Text('Cron Jobs:', style: TextStyle(fontWeight: FontWeight.bold)),
        if (health.cronJobs.isEmpty)
          const Text('  None found')
        else
          ...health.cronJobs.map((j) => Text('  • $j')),
      ],
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ActionChip(
          avatar: const Icon(Icons.refresh, size: 16),
          label: const Text('Refresh Health'),
          onPressed: () {
            ref.invalidate(hostHealthProvider(host.id));
            // Trigger check
            ref.read(healthCheckTriggerProvider(host));
          },
        ),
        ActionChip(
          avatar: const Icon(Icons.key, size: 16),
          label: const Text('Authorize Device'),
          onPressed: () => _authorizeDevice(context, ref),
        ),
        ActionChip(
          avatar: const Icon(Icons.restart_alt, size: 16),
          label: const Text('Reboot'),
          onPressed: () => _confirmAndExecute(
            context,
            ref,
            'Reboot',
            'Are you sure you want to reboot ${host.name}?',
            'sudo reboot',
          ),
        ),
        ActionChip(
          avatar: const Icon(Icons.power_settings_new, size: 16),
          label: const Text('Power Off'),
          onPressed: () => _confirmAndExecute(
            context,
            ref,
            'Power Off',
            'Are you sure you want to power off ${host.name}?',
            'sudo poweroff',
          ),
        ),
        ...host.actions.map(
          (action) => ActionChip(
            avatar: const Icon(Icons.play_arrow, size: 16),
            label: Text(action.name),
            onPressed: () => _executeAction(context, ref, action.name, action.command),
          ),
        ),
      ],
    );
  }

  Future<void> _authorizeDevice(BuildContext context, WidgetRef ref) async {
    // 1. Get Public Key
    String? publicKey;
    try {
      // Try standard Linux/Mac paths
      final home = Platform.environment['HOME'];
      if (home != null) {
        final rsaPath = '$home/.ssh/id_rsa.pub';
        final ed25519Path = '$home/.ssh/id_ed25519.pub';
        
        if (await File(ed25519Path).exists()) {
          publicKey = await File(ed25519Path).readAsString();
        } else if (await File(rsaPath).exists()) {
          publicKey = await File(rsaPath).readAsString();
        }
      }
    } catch (e) {
      print('Error finding local key: $e');
    }

    // If not found, ask user to paste it
    if (publicKey == null || publicKey.trim().isEmpty) {
      if (!context.mounted) return;
      publicKey = await showDialog<String>(
        context: context,
        builder: (context) {
          final controller = TextEditingController();
          return AlertDialog(
            title: const Text('Provide Public Key'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Could not automatically find id_rsa.pub or id_ed25519.pub. Please paste your public key below:'),
                const SizedBox(height: 8),
                TextField(
                  controller: controller,
                  maxLines: 3,
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                child: const Text('Use Key'),
              ),
            ],
          );
        },
      );
    }

    if (publicKey == null || publicKey.trim().isEmpty) return;
    publicKey = publicKey.trim();

    if (!context.mounted) return;

    // 2. Deploy to Host
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Deploying key to host...')),
    );

    try {
      await ref.read(sshServiceProvider).deployPublicKey(host, publicKey!);
      
      // 3. Update Config
      if (!context.mounted) return;
      
      final prefs = await SharedPreferences.getInstance();
      final mode = prefs.getString('config_mode');

      if (mode == 'file') {
        try {
                    await ref.read(hostsProvider.notifier).addAuthorizedKey(host, publicKey);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Key deployed and config updated!')),
                    );
                  } catch (e) {
          
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Key deployed but config update failed: $e'), backgroundColor: Colors.orange),
          );
        }
      } else {
        // Remote config
        showDialog(
           context: context,
           builder: (context) => AlertDialog(
             title: const Text('Update Remote Config'),
             content: Column(
               mainAxisSize: MainAxisSize.min,
               children: [
                 const Text('The key was successfully added to the host\'s authorized_keys.'),
                 const SizedBox(height: 8),
                 const Text('However, since you are using a remote config URL, you must manually update it to persist this change.'),
                 const SizedBox(height: 8),
                 const Text('Add this to your config for this host:'),
                 const SizedBox(height: 8),
                 SelectableText('authorized_keys:\n  - $publicKey'),
                 const SizedBox(height: 8),
                 ElevatedButton.icon(
                   icon: const Icon(Icons.copy),
                   label: const Text('Copy Key'),
                   onPressed: () {
                     Clipboard.setData(ClipboardData(text: publicKey!));
                   },
                 ),
               ],
             ),
             actions: [
               TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done')),
             ],
           ),
        );
      }

    } catch (e) {
       if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deploying key: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _confirmAndExecute(
    BuildContext context,
    WidgetRef ref,
    String actionName,
    String message,
    String command,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm $actionName'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      if (context.mounted) {
        _executeAction(context, ref, actionName, command);
      }
    }
  }

  Future<void> _executeAction(
    BuildContext context,
    WidgetRef ref,
    String name,
    String command,
  ) async {
    final sshService = ref.read(sshServiceProvider);
    
    // Show loading
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Executing $name...')),
    );

    try {
      final result = await sshService.executeCommand(host, command);
      
      if (context.mounted) {
        // Show result
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('$name Result'),
            content: SingleChildScrollView(
              child: Text(result.isEmpty ? '(No output)' : result),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error executing $name: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}