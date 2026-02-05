import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:xterm/xterm.dart';
import 'package:dartssh2/dartssh2.dart';
import '../../models/host.dart';

class SshScreen extends StatefulWidget {
  final Host host;

  const SshScreen({super.key, required this.host});

  @override
  State<SshScreen> createState() => _SshScreenState();
}

class _SshScreenState extends State<SshScreen> {
  late final Terminal terminal;
  final terminalController = TerminalController();
  SSHClient? client;

  @override
  void initState() {
    super.initState();
    terminal = Terminal();
    _connect();
  }

  Future<void> _connect() async {
    terminal.write('Connecting to ${widget.host.address}...\r\n');
    try {
      final socket = await SSHSocket.connect(widget.host.address, 22);
      final identities = await _loadIdentities();
      
      client = SSHClient(
        socket,
        username: widget.host.username,
        onPasswordRequest: () => widget.host.password,
        identities: identities,
      );

      await client!.authenticated;
      terminal.write('Connected.\r\n');

      final session = await client!.shell();

      session.stdout.listen((data) {
        terminal.write(utf8.decode(data));
      });

      session.stderr.listen((data) {
        terminal.write(utf8.decode(data));
      });

      terminal.onOutput = (data) {
        session.write(utf8.encode(data));
      };
      
      await session.done;
      terminal.write('\r\nConnection closed.\r\n');
    } catch (e) {
      terminal.write('\r\nError: $e\r\n');
    }
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
          identities.addAll(SSHKeyPair.fromPem(pem));
        } catch (e) {
          // Ignore errors (e.g., encrypted keys without handled passphrase)
        }
      }
    }
    return identities;
  }

  @override
  void dispose() {
    client?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SSH: ${widget.host.name}'),
      ),
      body: SafeArea(
        child: TerminalView(
          terminal,
          controller: terminalController,
          autofocus: true,
        ),
      ),
    );
  }
}
