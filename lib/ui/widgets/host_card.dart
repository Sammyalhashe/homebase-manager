import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/host.dart';
import '../../providers/hosts_provider.dart';
import '../../services/health_service.dart';
import 'health_popup.dart';

class HostCard extends ConsumerWidget {
  final Host host;

  const HostCard({super.key, required this.host});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final health = ref.watch(hostHealthProvider(host.id));

    // Trigger health check if it's still "checking"
    if (health.status == HealthStatus.checking) {
      ref.watch(healthCheckTriggerProvider(host));
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showHealthPopup(context, host),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.dns,
                size: 48,
                color: _getStatusColor(health.status),
              ),
              const SizedBox(height: 8),
              Text(
                host.name,
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                host.address,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const Spacer(),
              _buildStatusIndicator(health.status),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(HealthStatus status) {
    switch (status) {
      case HealthStatus.online:
        return Colors.green;
      case HealthStatus.offline:
        return Colors.red;
      case HealthStatus.error:
        return Colors.orange;
      case HealthStatus.checking:
        return Colors.grey;
    }
  }

  Widget _buildStatusIndicator(HealthStatus status) {
    if (status == HealthStatus.checking) {
      return const SizedBox(
        height: 12,
        width: 12,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getStatusColor(status),
      ),
    );
  }

  void _showHealthPopup(BuildContext context, Host host) {
    showDialog(
      context: context,
      builder: (context) => HealthPopup(host: host),
    );
  }
}
