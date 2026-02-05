import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/host.dart';
import '../services/config_service.dart';
import '../services/health_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

final configServiceProvider = Provider((ref) => ConfigService());
final healthServiceProvider = Provider((ref) => HealthService());

final configUrlProvider = StateProvider<String?>((ref) => null);

final hostsProvider = StateNotifierProvider<HostsNotifier, List<Host>>((ref) {
  final configService = ref.watch(configServiceProvider);
  return HostsNotifier(configService);
});

class HostsNotifier extends StateNotifier<List<Host>> {
  final ConfigService _configService;

  HostsNotifier(this._configService) : super([]);

  Future<void> loadHosts() async {
    final prefs = await SharedPreferences.getInstance();
    final mode = prefs.getString('config_mode') ?? 'url';
    final url = prefs.getString('config_url');
    final filePath = prefs.getString('config_file_path');
    final ageKey = prefs.getString('age_key');

    try {
      if (mode == 'url' && url != null && url.isNotEmpty) {
        state = await _configService.loadFromUrl(url, ageKey: ageKey);
      } else if (mode == 'file' && filePath != null && filePath.isNotEmpty) {
        state = await _configService.loadFromFile(filePath, ageKey: ageKey);
      }
    } catch (e) {
      print('Error loading hosts: $e');
      // Optionally handle error state here
    }
  }

  Future<void> setConfigUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('config_url', url);
    await loadHosts();
  }
}

final hostHealthProvider = StateProvider.family<HostHealth, String>((ref, hostId) {
  return HostHealth.checking();
});

final healthCheckTriggerProvider = FutureProvider.family<void, Host>((ref, host) async {
  final healthService = ref.read(healthServiceProvider);
  final health = await healthService.checkHealth(
    host.address,
    host.username,
    password: host.password,
  );
  ref.read(hostHealthProvider(host.id).notifier).state = health;
});
