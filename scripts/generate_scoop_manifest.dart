import 'dart:convert';
import 'dart:io';

void main(List<String> args) async {
  var version = args.isNotEmpty ? args[0] : 'nightly';
  final baseUrl = 'https://github.com/Sammyalhashe/homebase-manager/releases/download/nightly';
  final zipName = 'homebase-windows.zip';
  final url = '$baseUrl/$zipName';

  if (version == 'nightly') {
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final timeStr = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    version = "nightly-$dateStr-$timeStr"; 
  }

  // Download the file to calculate hash
  final tempFile = File(pJoin(Directory.systemTemp.path, zipName));
  stderr.writeln('// Downloading $url to calculate hash...');
  
  final client = HttpClient();
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  await response.pipe(tempFile.openWrite());
  client.close();

  // Calculate SHA256
  final process = await Process.run('sha256sum', [tempFile.path]);
  final hash = process.stdout.toString().split(' ')[0].trim();
  
  // Cleanup
  await tempFile.delete();

  final manifest = {
    "version": version,
    "description": "Homebase Manager - SSH & Health Dashboard",
    "homepage": "https://github.com/Sammyalhashe/homebase-manager",
    "license": "MIT",
    "architecture": {
        "64bit": {
            "url": url,
            "hash": hash
        }
    },
    "bin": "homebase_manager.exe",
    "shortcuts": [
        ["homebase_manager.exe", "Homebase Manager"]
    ],
    "checkver": {
        "url": "https://api.github.com/repos/Sammyalhashe/homebase-manager/releases/tags/nightly",
        "jsonpath": r"$.assets[?(@.name=='homebase-windows.zip')].updated_at"
    },
    "autoupdate": {
        "architecture": {
            "64bit": {
                "url": "https://github.com/Sammyalhashe/homebase-manager/releases/download/nightly/homebase-windows.zip"
            }
        }
    }
  };

  final encoder = JsonEncoder.withIndent('    ');
  print(encoder.convert(manifest));
}

String pJoin(String part1, String part2) {
  return part1.endsWith('/') || part1.endsWith('\\') ? '$part1$part2' : '$part1/$part2';
}

