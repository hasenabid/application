import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/models/dashboard_summary.dart';

final dashboardControllerProvider = FutureProvider.autoDispose<DashboardSummary>((ref) async {
  // Simulate network delay
  await Future.delayed(const Duration(seconds: 1));
  
  // Return mocked dashboard stats
  return const DashboardSummary(
    activeZonesCount: 12,
    totalZonesCount: 12,
    activeAlertsCount: 2,
    systemStatus: SystemStatus.warning,
  );
});
