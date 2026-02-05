import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import 'package:path/path.dart' as p;

class SshUtils {
  static Future<List<SSHKeyPair>> loadIdentities() async {
    final identities = <SSHKeyPair>[];
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

    if (home == null) return identities;

    final sshDir = p.join(home, '.ssh');
    final keyFiles = ['id_rsa', 'id_ed25519', 'id_ecdsa'];

    print('Looking for SSH keys in $sshDir');

    for (final name in keyFiles) {
      final path = p.join(sshDir, name);
      final file = File(path);
      if (await file.exists()) {
        try {
          final pem = await file.readAsString();
          print('Found key: $path');
          // TODO: Handle encrypted keys by prompting for passphrase if possible
          identities.addAll(SSHKeyPair.fromPem(pem));
          print('Loaded key: $name');
        } catch (e) {
          print('Failed to load key $name: $e');
        }
      }
    }
    
    if (identities.isEmpty) {
      print('No valid SSH keys found in standard locations.');
    }
    
    return identities;
  }
}
