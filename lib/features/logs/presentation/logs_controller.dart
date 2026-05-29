import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/audit_log.dart';
import '../../auth/presentation/auth_controller.dart';
import 'package:uuid/uuid.dart';

final logsControllerProvider =
    StateNotifierProvider<LogsNotifier, List<AuditLog>>((ref) {
      return LogsNotifier(ref);
    });

class LogsNotifier extends StateNotifier<List<AuditLog>> {
  final Ref _ref;
  final _uuid = const Uuid();

  LogsNotifier(this._ref) : super([]) {
    // Initialiser avec quelques logs fictifs
    state = [
      AuditLog(
        id: _uuid.v4(),
        action: 'System Start',
        timestamp: DateTime.now().subtract(const Duration(hours: 2)),
        userName: 'System',
        details: 'Initialisation de l\'application Aura.',
      ),
    ];
  }

  void addLog(String action, String details) {
    // Récupérer l'utilisateur connecté via authControllerProvider
    final authState = _ref.read(authControllerProvider);
    final user = authState.valueOrNull;
    final userName = user?.name ?? 'Utilisateur inconnu';

    final newLog = AuditLog(
      id: _uuid.v4(),
      action: action,
      timestamp: DateTime.now(),
      userName: userName,
      details: details,
    );

    state = [newLog, ...state];
  }
}
