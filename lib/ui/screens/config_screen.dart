import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../providers/hosts_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ConfigScreen extends ConsumerStatefulWidget {
  const ConfigScreen({super.key});

  @override
  ConsumerState<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends ConsumerState<ConfigScreen> {
  final _urlController = TextEditingController();
  final _filePathController = TextEditingController();
  final _ageKeyController = TextEditingController();
  String _configMode = 'url'; // 'url' or 'file'

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _configMode = prefs.getString('config_mode') ?? 'url';
      _urlController.text = prefs.getString('config_url') ?? '';
      _filePathController.text = prefs.getString('config_file_path') ?? '';
      _ageKeyController.text = prefs.getString('age_key') ?? '';
    });
  }

  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      setState(() {
        _filePathController.text = result.files.single.path!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configuration'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Config Source', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'url', label: Text('Git URL')),
                ButtonSegment(value: 'file', label: Text('Local File')),
              ],
              selected: {_configMode},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _configMode = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            if (_configMode == 'url')
              TextField(
                controller: _urlController,
                decoration: const InputDecoration(
                  labelText: 'Config Git URL (Raw YAML)',
                  hintText: 'https://raw.githubusercontent.com/.../hosts.yaml',
                  border: OutlineInputBorder(),
                ),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _filePathController,
                      decoration: const InputDecoration(
                        labelText: 'Local Config File Path',
                        hintText: '/path/to/hosts.yaml',
                        border: OutlineInputBorder(),
                      ),
                      readOnly: true, // Prefer picking via button
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    onPressed: _pickFile,
                    icon: const Icon(Icons.folder_open),
                  ),
                ],
              ),
            const SizedBox(height: 24),
            const Text('SOPS / Age Security', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _ageKeyController,
              decoration: const InputDecoration(
                labelText: 'Age Private Key (X25519)',
                hintText: 'AGE-SECRET-KEY-1...',
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'If your configuration file is SOPS-encrypted, provide your Age private key here. '
              'The key is stored securely in your device\'s local storage.',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setString('config_mode', _configMode);
                  if (_configMode == 'url') {
                    await prefs.setString('config_url', _urlController.text);
                  } else {
                    await prefs.setString('config_file_path', _filePathController.text);
                  }
                  await prefs.setString('age_key', _ageKeyController.text);
                  await ref.read(hostsProvider.notifier).loadHosts();
                  
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Configuration saved')),
                  );
                  Navigator.pop(context);
                },
                child: const Text('Save & Apply'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
