import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/auth_controller.dart';
import '../../zones/presentation/zones_controller.dart';
import '../../zones/domain/models/thermoplay_zone.dart';

class HardwareDashboardScreen extends ConsumerWidget {
  const HardwareDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final zonesState = ref.watch(zonesControllerProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context, ref),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: zonesState.when(
                  data: (zones) => _buildFrontPanel(context, zones),
                  loading: () => _buildFrontPanel(context, []),
                  error: (e, _) => Center(
                    child: Text('Erreur: $e',
                        style: const TextStyle(color: AppColors.error)),
                  ),
                ),
              ),
            ),
            _buildBottomNav(context),
          ],
        ),
      ),
    );
  }

  // ─── Top bar ──────────────────────────────────────────────────────────────
  Widget _buildTopBar(BuildContext context, WidgetRef ref) {
    return Container(
      height: 44,
      color: AppColors.panelBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.primary, width: 1.5),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Text(
              'THERMOPLAY',
              style: GoogleFonts.shareTechMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'TH-M6',
            style: GoogleFonts.shareTechMono(
              fontSize: 11,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          _buildStatusDot('SYS', AppColors.ledOk),
          const SizedBox(width: 12),
          _buildStatusDot('NET', AppColors.ledOk),
          const SizedBox(width: 16),
          InkWell(
            onTap: () {
              ref.read(authControllerProvider.notifier).logout();
              context.go('/login');
            },
            child: const Icon(Icons.power_settings_new,
                size: 18, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.6), blurRadius: 4)],
          ),
        ),
        const SizedBox(width: 3),
        Text(label,
            style: const TextStyle(
                fontSize: 9,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ─── Front panel ──────────────────────────────────────────────────────────
  Widget _buildFrontPanel(BuildContext context, List<ThermoplayZone> zones) {
    final List<ThermoplayZone?> displayZones = List.generate(
      4,
      (i) => i < zones.length ? zones[i] : null,
    );

    return Container(
      decoration: BoxDecoration(
        color: AppColors.panelBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFCCCCCC), width: 1),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          _buildLCDScreen(displayZones),
          const Divider(height: 1, color: Color(0xFFCCCCCC)),
          Expanded(child: _buildLEDMatrix(displayZones)),
          _buildPanelFooter(context),
        ],
      ),
    );
  }

  // ─── LCD Screen ───────────────────────────────────────────────────────────
  Widget _buildLCDScreen(List<ThermoplayZone?> zones) {
    return Container(
      margin: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.lcdBackground,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF7A9CC0), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x22000000), blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(60, 4, 4, 0),
            child: Row(
              children: List.generate(4, (i) {
                return Expanded(
                  child: Center(
                    child: Text(
                      'zone ${i + 1}',
                      style: GoogleFonts.shareTechMono(
                        fontSize: 10, // Un peu plus grand pour 4 zones
                        color: AppColors.lcdText,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          _buildLCDRow('temperature', zones, (z) {
            if (z == null) return '---';
            return '${z.currentTemperature.toInt()}';
          }, fontSize: 26, bold: true), // Plus grand pour 4 zones
          _buildLCDRow('set point', zones, (z) {
            if (z == null) return '---';
            return '${z.setpointTemperature.toInt()}°C';
          }, fontSize: 10),
          _buildLCDRow('status', zones, (z) {
            if (z == null) return 'OFF';
            return z.mode.name.toUpperCase();
          }, fontSize: 10),
          _buildLCDRow('power', zones, (z) {
            if (z == null) return '--';
            return 'P% ${z.powerPercent}';
          }, fontSize: 10),
          _buildLCDRow('messages', zones, (z) {
            if (z == null) return '';
            if (z.isHigh) return 'Hi';
            if (z.isLow) return 'Low';
            if (z.isOk) return 'Ok';
            return 'Off';
          }, fontSize: 10),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildLCDRow(
    String label,
    List<ThermoplayZone?> zones,
    String Function(ThermoplayZone?) getValue, {
    double fontSize = 10,
    bool bold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Padding(
              padding: const EdgeInsets.only(left: 6),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 8,
                  color: AppColors.lcdText.withValues(alpha: 0.7),
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
          ...List.generate(4, (i) {
            final zone = zones[i];
            Color color = AppColors.lcdText;
            if (zone != null && label == 'temperature') {
              if (zone.isHigh) color = AppColors.ledHigh;
              if (zone.isLow) color = AppColors.ledLow;
            }
            return Expanded(
              child: Center(
                child: Text(
                  getValue(zone),
                  style: GoogleFonts.shareTechMono(
                    fontSize: fontSize,
                    color: color,
                    fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── LED Matrix ───────────────────────────────────────────────────────────
  Widget _buildLEDMatrix(List<ThermoplayZone?> zones) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildSidePanelLeft(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: List.generate(4, (i) {
                    return Expanded(
                      child: Center(
                        child: Text(
                          'TC${i + 1}',
                          style: const TextStyle(
                              fontSize: 12, // Plus grand
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 8),
                ..._buildLEDRows(zones),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildDialKnob(),
        ],
      ),
    );
  }

  List<Widget> _buildLEDRows(List<ThermoplayZone?> zones) {
    // Dynamic color logic:
    // Green (ok) if zone is normal
    // Orange (low/attention) if temp is low
    // Red (high/problem) if temp is high
    Color getDynamicColor(ThermoplayZone? z) {
      if (z == null) return Colors.transparent;
      if (z.isHigh || z.isOffline) return AppColors.ledHigh; // Rouge
      if (z.isLow) return Colors.orange; // Orange
      return AppColors.ledOk; // Vert
    }

    final rows = <(String Function(int), bool Function(ThermoplayZone?), Color Function(ThermoplayZone?))>[
      ((_) => 'Hi', (ThermoplayZone? z) => z?.isHigh ?? false, getDynamicColor),
      ((_) => 'Ok', (ThermoplayZone? z) => z?.isOk ?? false, getDynamicColor),
      ((_) => 'Low', (ThermoplayZone? z) => z?.isLow ?? false, getDynamicColor),
      ((i) => 'Fu${i + 1}', (ThermoplayZone? z) => z?.isFu ?? false, getDynamicColor),
      ((i) => 'R${i + 1}', (ThermoplayZone? z) => z?.isR ?? false, getDynamicColor),
      ((i) => 'SSR${i + 1}', (ThermoplayZone? z) => z?.isSSR ?? false, getDynamicColor),
    ];

    return rows.map((row) {
      final labelBuilder = row.$1;
      final getter = row.$2;
      final colorGetter = row.$3;

      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: List.generate(4, (i) {
            final zone = zones[i];
            final isActive = getter(zone);
            return Expanded(
              child: Center(
                child: _buildLED(
                  label: labelBuilder(i),
                  active: isActive,
                  color: colorGetter(zone),
                ),
              ),
            );
          }),
        ),
      );
    }).toList();
  }

  Widget _buildLED({
    required String label,
    required bool active,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: active ? color : AppColors.ledOff.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(2),
            boxShadow: active
                ? [BoxShadow(color: color.withValues(alpha: 0.8), blurRadius: 6, spreadRadius: 1)]
                : null,
            border: Border.all(
              color: active ? color : const Color(0xFF666666),
              width: 1,
            ),
          ),
        ),
        const SizedBox(width: 3),
        SizedBox(
          width: 18,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 8,
              color: AppColors.textPrimary,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.visible,
          ),
        ),
      ],
    );
  }

  // ─── Side panel gauche ────────────────────────────────────────────────────
  Widget _buildSidePanelLeft() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('[SP1]', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                Text('[SP2]', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(width: 6),
            // Ajout d'interaction
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  // Navigation vers un futur écran de réglages
                  // context.go('/settings');
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bouton SP cliqué')));
                },
                child: _buildConnectorPort(),
              )
            ),
          ],
        ),
        const SizedBox(height: 30),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('ONE | ALL', style: TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
            const SizedBox(width: 6),
            // Ajout d'interaction
            Builder(
              builder: (context) => GestureDetector(
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mode ONE/ALL cliqué')));
                },
                child: _buildConnectorPort(),
              )
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectorPort() {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF151515),
        border: Border.all(color: const Color(0xFF888888), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Color(0x66000000), blurRadius: 4, offset: Offset(1, 1)),
        ],
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF000000),
            boxShadow: [
              BoxShadow(color: Color(0x33FFFFFF), blurRadius: 2, spreadRadius: -1),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Dial / Knob droit ────────────────────────────────────────────────────
  Widget _buildDialKnob() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('PRESS',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
            Text('to SET',
                style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary)),
          ],
        ),
        const SizedBox(height: 12),
        Builder(
          builder: (context) => GestureDetector(
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Molette cliquée : Ouverture des réglages...')));
            },
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const RadialGradient(
                  center: Alignment(-0.2, -0.2),
                  radius: 0.7,
                  colors: [Color(0xFFE5E5E5), Color(0xFFAAAAAA), Color(0xFF777777)],
                  stops: [0.0, 0.6, 1.0],
                ),
                boxShadow: const [
                  BoxShadow(
                      color: Color(0x66000000), blurRadius: 8, offset: Offset(3, 4)),
                  BoxShadow(
                      color: Color(0x44FFFFFF), blurRadius: 4, offset: Offset(-2, -2)),
                ],
                border: Border.all(color: const Color(0xFF666666), width: 1),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFFAAAAAA),
                            Color(0xFFE5E5E5),
                            Color(0xFFAAAAAA),
                            Color(0xFFE5E5E5),
                            Color(0xFFAAAAAA),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Container(
                        width: 2.5,
                        height: 12,
                        decoration: BoxDecoration(
                          color: const Color(0xFF222222),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Panel footer ─────────────────────────────────────────────────────────
  Widget _buildPanelFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFFCCCCCC), width: 1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            'THERMOPLAY',
            style: GoogleFonts.shareTechMono(
              fontSize: 9,
              color: AppColors.primary,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'TH-M6',
            style: GoogleFonts.shareTechMono(
              fontSize: 9,
              color: AppColors.textSecondary,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Bottom navigation ────────────────────────────────────────────────────
  Widget _buildBottomNav(BuildContext context) {
    return Container(
      height: 48,
      color: AppColors.panelBackground,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navButton(context, icon: Icons.dashboard, label: 'Tableau', route: '/dashboard', active: true),
          _navButton(context, icon: Icons.notifications_outlined, label: 'Alertes', route: '/alerts'),
          _navButton(context, icon: Icons.build_outlined, label: 'Maintenance', route: '/maintenance'),
          _navButton(context, icon: Icons.show_chart, label: 'Historique', route: '/dashboard'),
          _navButton(context, icon: Icons.settings_outlined, label: 'Réglages', route: '/settings'),
        ],
      ),
    );
  }

  Widget _navButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String route,
    bool active = false,
  }) {
    final color = active ? AppColors.primary : AppColors.textSecondary;
    return InkWell(
      onTap: () => context.go(route),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 8,
                    color: color,
                    fontWeight: active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      ),
    );
  }
}
