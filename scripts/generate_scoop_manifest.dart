import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  var version = args.isNotEmpty ? args[0] : 'nightly';
  final baseUrl = 'https://github.com/Sammyalhashe/homebase-manager/releases/download/$version';
  final zipName = 'homebase-windows.zip';
  final url = '$baseUrl/$zipName';

  if (version == 'nightly') {
    final now = DateTime.now();
    final dateStr = "${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}";
    final timeStr = "${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}${now.second.toString().padLeft(2, '0')}";
    // Use a version that Scoop can parse as newer
    version = "nightly-$dateStr-$timeStr"; 
  }

  final manifest = {
    "version": version,
    "description": "Homebase Manager - SSH & Health Dashboard",
    "homepage": "https://github.com/Sammyalhashe/homebase-manager",
    "license": "MIT",
    "architecture": {
      "64bit": {
        "url": url,
        "hash": "HEAD" // For nightly, we can't easily pin hash unless we download it.
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
