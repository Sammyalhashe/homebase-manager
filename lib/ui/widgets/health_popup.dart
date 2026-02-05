import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/host.dart';
import '../../providers/hosts_provider.dart';
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
}
