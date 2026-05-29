import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/alert.dart';

final alertsControllerProvider = FutureProvider.autoDispose<List<Alert>>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));
  
  // Return mocked alerts list
  return [
    Alert(
      id: '1',
      zoneId: '2',
      message: 'Temperature exceeds safety threshold (+15°C)',
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
      severity: AlertSeverity.critical,
      status: AlertStatus.active,
    ),
    Alert(
      id: '2',
      zoneId: '1',
      message: 'Sensor communication timeout',
      timestamp: DateTime.now().subtract(const Duration(hours: 1)),
      severity: AlertSeverity.warning,
      status: AlertStatus.resolved,
    ),
  ];
});
