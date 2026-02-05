import 'dart:convert';
import 'package:dartssh2/dartssh2.dart';

enum HealthStatus { online, offline, error, checking }

class HostHealth {
  final HealthStatus status;
  final String? message;
  final String? uptime;
  final List<String> failedServices;
  final List<String> cronJobs;

  HostHealth({
    required this.status,
    this.message,
    this.uptime,
    this.failedServices = const [],
    this.cronJobs = const [],
  });

  factory HostHealth.offline() => HostHealth(status: HealthStatus.offline);
  factory HostHealth.checking() => HostHealth(status: HealthStatus.checking);
}

class HealthService {
  Future<HostHealth> checkHealth(String address, String username, {String? password}) async {
    try {
      final socket = await SSHSocket.connect(address, 22, timeout: const Duration(seconds: 10));
      final client = SSHClient(
        socket,
        username: username,
        onPasswordRequest: () => password,
      );

      await client.authenticated;

      // Check uptime
      final uptime = await client.run('uptime -p');
      
      // Check failed services
      final failedServicesOutput = await client.run('systemctl list-units --state=failed --no-legend');
      final failedServices = utf8.decode(failedServicesOutput).split('\n').where((s) => s.isNotEmpty).toList();

      // Check cron jobs
      final cronOutput = await client.run('ls /etc/cron.d');
      final cronJobs = utf8.decode(cronOutput).split('\n').where((s) => s.isNotEmpty).toList();

      client.close();
      await client.done;

      return HostHealth(
        status: HealthStatus.online,
        uptime: utf8.decode(uptime).trim(),
        failedServices: failedServices,
        cronJobs: cronJobs,
      );
    } catch (e) {
      return HostHealth(status: HealthStatus.offline, message: e.toString());
    }
  }
}
