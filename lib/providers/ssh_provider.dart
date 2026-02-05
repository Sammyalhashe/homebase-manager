import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/ssh_service.dart';

final sshServiceProvider = Provider((ref) => SshService());
