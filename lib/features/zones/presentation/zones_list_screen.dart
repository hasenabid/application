import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../domain/models/thermoplay_zone.dart';
import 'zones_controller.dart';

class ZonesListScreen extends ConsumerWidget {
  const ZonesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesState = ref.watch(zonesControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zones Monitor'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/dashboard'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.refresh(zonesControllerProvider),
          )
        ],
      ),
      body: zonesState.when(
        data: (zones) => ListView.builder(
          padding: const EdgeInsets.all(12.0),
          itemCount: zones.length,
          itemBuilder: (context, index) {
            final zone = zones[index];
            return _buildZoneCard(zone);
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) =>
            Center(child: Text('Erreur: $err')),
      ),
    );
  }

  Widget _buildZoneCard(ThermoplayZone zone) {
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (zone.status) {
      case ZoneStatus.ok:
        statusColor = AppColors.ledOk;
        statusIcon = Icons.check_circle;
        statusLabel = 'OK';
        break;
      case ZoneStatus.high:
        statusColor = AppColors.ledHigh;
        statusIcon = Icons.arrow_upward;
        statusLabel = 'HIGH';
        break;
      case ZoneStatus.low:
        statusColor = AppColors.ledLow;
        statusIcon = Icons.arrow_downward;
        statusLabel = 'LOW';
        break;
      case ZoneStatus.offline:
        statusColor = AppColors.ledOff;
        statusIcon = Icons.power_off;
        statusLabel = 'OFF';
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 10.0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            // Status indicator bar on left
            Container(
              width: 4,
              height: 54,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            // Zone info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(zone.name,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: statusColor, width: 0.8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon, size: 10, color: statusColor),
                            const SizedBox(width: 3),
                            Text(statusLabel,
                                style: TextStyle(
                                    fontSize: 9,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _infoChip('Temp', '${zone.currentTemperature.toInt()}°C',
                          statusColor),
                      const SizedBox(width: 8),
                      _infoChip('Consigne',
                          '${zone.setpointTemperature.toInt()}°C',
                          AppColors.textSecondary),
                      const SizedBox(width: 8),
                      _infoChip('Puissance', '${zone.powerPercent}%',
                          AppColors.primary),
                      const SizedBox(width: 8),
                      _infoChip(
                          'Mode',
                          zone.mode.name.toUpperCase(),
                          AppColors.textSecondary),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 8, color: AppColors.textSecondary)),
        Text(value,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color)),
      ],
    );
  }
}
