import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';
import '../models/host.dart';
import '../utils/ssh_utils.dart';

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
    final identities = await SshUtils.loadIdentities();
    
    final client = SSHClient(
      socket,
      username: host.username,
      onPasswordRequest: () => host.password,
      identities: identities,
    );
    
    await client.authenticated;
    return client;
  }
}
