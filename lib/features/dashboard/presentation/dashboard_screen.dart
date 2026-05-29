import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import 'dashboard_controller.dart';
import '../domain/models/dashboard_summary.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
            },
          )
        ],
      ),
      body: dashboardState.when(
        data: (summary) => _buildDashboard(context, summary),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err', style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, DashboardSummary summary) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'System Overview',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Active Zones',
                  '${summary.activeZonesCount}/${summary.totalZonesCount}',
                  Icons.thermostat,
                  AppColors.success,
                  () => context.go('/zones'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Alerts',
                  '${summary.activeAlertsCount}',
                  Icons.warning_amber_rounded,
                  summary.activeAlertsCount > 0 ? AppColors.error : AppColors.success,
                  () => context.go('/alerts'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'System Status',
            summary.systemStatus.name.toUpperCase(),
            summary.systemStatus == SystemStatus.normal ? Icons.check_circle_outline : Icons.error_outline,
            summary.systemStatus == SystemStatus.normal ? AppColors.success : AppColors.warning,
            null,
          ),
          const SizedBox(height: 32),
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => context.go('/zones'),
            icon: const Icon(Icons.list),
            label: const Text('View All Zones'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.secondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, VoidCallback? onTap) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
              const SizedBox(height: 4),
              Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }
}
