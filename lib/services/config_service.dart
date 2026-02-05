import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
import 'package:yaml_edit/yaml_edit.dart';
import 'package:path/path.dart' as p;
import '../models/host.dart';

class ConfigService {
  Future<List<Host>> loadFromUrl(String url, {String? ageKey}) async {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      return parseYaml(response.body, ageKey: ageKey);
    } else {
      throw Exception('Failed to load config from $url');
    }
  }

  Future<List<Host>> loadFromFile(String path, {String? ageKey}) async {
    final file = File(path);
    if (await file.exists()) {
      final content = await file.readAsString();
      return parseYaml(content, ageKey: ageKey);
    } else {
      throw Exception('File not found: $path');
    }
  }

  Future<String> getDefaultConfigPath() async {
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];
    if (home == null) return '';

    if (Platform.isLinux || Platform.isMacOS) {
      return p.join(home, '.config', 'homebase-manager', 'config.yaml');
    } else if (Platform.isWindows) {
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        return p.join(appData, 'homebase-manager', 'config.yaml');
      }
      return p.join(home, 'AppData', 'Roaming', 'homebase-manager', 'config.yaml');
    }
    return '';
  }

  Future<void> createDefaultConfig(String path) async {
    final file = File(path);
    if (!await file.parent.exists()) {
      await file.parent.create(recursive: true);
    }

    const template = '''
hosts:
  - name: "Example Host"
    address: "192.168.1.100"
    username: "user"
    root_access: true
    actions:
      - name: "Check Storage"
        command: "df -h"
''';
    
    await file.writeAsString(template);
  }

  Future<void> saveHostAuthorizedKey(String filePath, String hostId, String publicKey) async {
    final file = File(filePath);
    if (!await file.exists()) {
      throw Exception('Config file not found: $filePath');
    }

    final content = await file.readAsString();
    final doc = YamlEditor(content);

    final hosts = doc.parseAt(['hosts']);
    final hostsList = hosts.value as List;
    
    int index = -1;
    for (int i = 0; i < hostsList.length; i++) {
      final h = hostsList[i];
      final id = h['id']?.toString() ?? h['name']?.toString();
      if (id == hostId) {
        index = i;
        break;
      }
    }

    if (index != -1) {
       // Check if authorized_keys exists
       final hostPath = ['hosts', index];
       final hostMap = hostsList[index] as Map;
       
       if (hostMap.containsKey('authorized_keys')) {
         final currentKeys = (hostMap['authorized_keys'] as List).cast<String>();
         if (!currentKeys.contains(publicKey)) {
           doc.appendToList([...hostPath, 'authorized_keys'], publicKey);
         }
       } else {
         // Create the list
         doc.update([...hostPath, 'authorized_keys'], [publicKey]);
       }

       await file.writeAsString(doc.toString());
    } else {
      throw Exception('Host with ID $hostId not found in config');
    }
  }

  List<Host> parseYaml(String content, {String? ageKey}) {
    String finalContent = content;

    // Basic SOPS detection
    if (content.contains('sops:') && content.contains('version:')) {
      if (ageKey != null && ageKey.isNotEmpty) {
        // TODO: Call native SOPS binary on Desktop or use a library
        print('Attempting to decrypt SOPS content with Age key...');
      } else {
        print('SOPS content detected but no Age key provided.');
      }
    }

    final doc = loadYaml(finalContent);
    if (doc is! Map) return [];

    final hostsList = doc['hosts'];
    if (hostsList is! List) return [];

    return hostsList.map((h) => Host.fromYaml(h as Map)).toList();
  }
}
