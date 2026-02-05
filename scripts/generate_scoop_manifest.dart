import 'dart:convert';
import 'dart:io';

void main(List<String> args) {
  final version = args.isNotEmpty ? args[0] : 'nightly';
  final baseUrl = 'https://github.com/Sammyalhashe/homebase-manager/releases/download/$version';
  final zipName = 'homebase-windows.zip';
  final url = '$baseUrl/$zipName';

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
