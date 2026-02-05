import 'dart:convert';
import 'dart:io';
import 'package:dartssh2/dartssh2.dart';
import '../models/host.dart';

class SshService {
  Future<String> executeCommand(Host host, String command) async {
    final client = await _connect(host);
    try {
      final result = await client.run(command);
      return utf8.decode(result);
    } finally {
      client.close();
      await client.done;
    }
  }

  Future<void> deployPublicKey(Host host, String publicKey) async {
    // Sanitize the key slightly to avoid command injection, though it should be a valid key.
    if (publicKey.contains("'")) {
       throw Exception("Invalid public key format");
    }

    final command = "mkdir -p ~/.ssh && echo '$publicKey' >> ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys && chmod 700 ~/.ssh";
    await executeCommand(host, command);
  }

  Future<SSHClient> _connect(Host host) async {
    final socket = await SSHSocket.connect(host.address, 22, timeout: const Duration(seconds: 10));
    final identities = await _loadIdentities();
    
    final client = SSHClient(
      socket,
      username: host.username,
      onPasswordRequest: () => host.password,
      identities: identities,
    );
    
    await client.authenticated;
    return client;
  }

  Future<List<SSHKeyPair>> _loadIdentities() async {
    final identities = <SSHKeyPair>[];
    final home = Platform.environment['HOME'] ?? Platform.environment['USERPROFILE'];

    if (home == null) return identities;

    final keyFiles = ['id_rsa', 'id_ed25519', 'id_ecdsa'];

    for (final name in keyFiles) {
      final path = '$home/.ssh/$name';
      final file = File(path);
      if (await file.exists()) {
        try {
          final pem = await file.readAsString();
          // TODO: Handle encrypted keys by prompting for passphrase
          identities.addAll(SSHKeyPair.fromPem(pem));
        } catch (e) {
          print('Failed to load key $name: $e');
        }
      }
    }
    return identities;
  }
}
