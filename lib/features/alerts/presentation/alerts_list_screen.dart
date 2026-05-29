import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/models/alert.dart';
import 'alerts_controller.dart';

class AlertsListScreen extends ConsumerWidget {
  const AlertsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsState = ref.watch(alertsControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertes Système'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(alertsControllerProvider),
          )
        ],
      ),
      body: alertsState.when(
        data: (alerts) => alerts.isEmpty
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline,
                        size: 48, color: AppColors.ledOk),
                    SizedBox(height: 12),
                    Text('Aucune alerte active',
                        style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12.0),
                itemCount: alerts.length,
                itemBuilder: (context, index) {
                  final alert = alerts[index];
                  return _buildAlertCard(alert);
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
            child: Text('Erreur: $err',
                style: const TextStyle(color: AppColors.error))),
      ),
    );
  }

  Widget _buildAlertCard(Alert alert) {
    Color severityColor;
    IconData severityIcon;

    switch (alert.severity) {
      case AlertSeverity.critical:
        severityColor = AppColors.ledHigh;
        severityIcon = Icons.error;
        break;
      case AlertSeverity.warning:
        severityColor = AppColors.ledLow;
        severityIcon = Icons.warning_amber_rounded;
        break;
      case AlertSeverity.info:
        severityColor = AppColors.primary;
        severityIcon = Icons.info;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6),
        side: BorderSide(
          color: alert.status == AlertStatus.active
              ? severityColor
              : Colors.transparent,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left color bar
            Container(
              width: 4,
              height: 60,
              decoration: BoxDecoration(
                color: severityColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Icon(severityIcon, color: severityColor, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(alert.message,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(
                    'Zone: ${alert.zoneId} • ${alert.timestamp.toString().substring(0, 16)}',
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 11),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: alert.status == AlertStatus.active
                          ? severityColor.withValues(alpha: 0.15)
                          : AppColors.divider,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: alert.status == AlertStatus.active
                            ? severityColor
                            : AppColors.divider,
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      alert.status.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: alert.status == AlertStatus.active
                            ? severityColor
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
