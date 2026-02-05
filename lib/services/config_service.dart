import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:yaml/yaml.dart';
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
