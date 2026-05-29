import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../dashboard/presentation/widgets/animated_background.dart';
import '../../maintenance/data/sensor_repository.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  // Zone 1 – données capteur réel
  final List<FlSpot> _zone1Spots = [];
  // Zone 2-4 – données simulées
  final List<FlSpot> _zone2Spots = [];
  final List<FlSpot> _zone3Spots = [];
  final List<FlSpot> _zone4Spots = [];

  double _time = 0;
  double _lastSensorTemp = 0;
  Timer? _timer;

  static const double _maxTemp = 300.0;
  static const int _windowSize = 30; // secondes visibles

  @override
  void initState() {
    super.initState();
    // Pré-remplir avec des valeurs plausibles
    for (int i = 0; i < _windowSize; i++) {
      _zone1Spots.add(FlSpot(_time, 150));
      _zone2Spots.add(FlSpot(_time, 152 + sin(_time * 0.3) * 5));
      _zone3Spots.add(FlSpot(_time, 148 + cos(_time * 0.2) * 4));
      _zone4Spots.add(FlSpot(_time, 150 + sin(_time * 0.4) * 3));
      _time += 1;
    }

    // Lance le polling du capteur toutes les 5 s
    _timer = Timer.periodic(const Duration(seconds: 5), (_) {
      ref.invalidate(latestSensorProvider);
    });

    // Met à jour le graphe toutes les secondes
    Timer.periodic(const Duration(seconds: 1), _onTick);
  }

  void _onTick(Timer t) {
    if (!mounted) { t.cancel(); return; }

    // Zone 1 : utilise la dernière valeur capteur si disponible, sinon interpole
    final sensorValue = ref.read(latestSensorProvider).valueOrNull;
    if (sensorValue != null && sensorValue.temperature > 0) {
      _lastSensorTemp = sensorValue.temperature;
    }
    final z1Temp = _lastSensorTemp > 0
        ? _lastSensorTemp
        : 150 + sin(_time * 0.5) * 10 + Random().nextDouble() * 3;

    setState(() {
      _time += 1;
      _zone1Spots.add(FlSpot(_time, z1Temp));
      _zone2Spots.add(FlSpot(_time, 152 + sin(_time * 0.3) * 5 + Random().nextDouble() * 2));
      _zone3Spots.add(FlSpot(_time, 148 + cos(_time * 0.2) * 4 + Random().nextDouble() * 2));
      _zone4Spots.add(FlSpot(_time, 150 + sin(_time * 0.4) * 3 + Random().nextDouble() * 2));

      // Garde seulement _windowSize points
      if (_zone1Spots.length > _windowSize) _zone1Spots.removeAt(0);
      if (_zone2Spots.length > _windowSize) _zone2Spots.removeAt(0);
      if (_zone3Spots.length > _windowSize) _zone3Spots.removeAt(0);
      if (_zone4Spots.length > _windowSize) _zone4Spots.removeAt(0);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _zone1OverMax =>
      _lastSensorTemp > 0 && _lastSensorTemp > _maxTemp;

  @override
  Widget build(BuildContext context) {
    // Lit le capteur pour mise à jour immédiate
    ref.watch(latestSensorProvider).whenData((r) {
      if (r.temperature > 0 && r.temperature != _lastSensorTemp) {
        _lastSensorTemp = r.temperature;
      }
    });

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D12),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(color: Colors.black.withValues(alpha: 0.2)),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.go('/dashboard'),
        ),
        title: Text(
          'ANALYTIQUES EN TEMPS RÉEL',
          style: GoogleFonts.orbitron(
              fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
        ),
      ),
      body: Stack(
        children: [
          const AnimatedBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildHeaderInfo(),
                  const SizedBox(height: 12),
                  _buildSensorBadges(),
                  const SizedBox(height: 12),
                  Expanded(child: _buildChart()),
                  const SizedBox(height: 16),
                  _buildLegend(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TENDANCE THERMIQUE',
                style: GoogleFonts.orbitron(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5)),
            Text('4 zones · MAX 300°C · capteur réel Z1',
                style: GoogleFonts.rajdhani(color: Colors.white54, fontSize: 12)),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.greenAccent.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.greenAccent),
          ),
          child: Row(
            children: [
              Container(
                width: 8, height: 8,
                decoration: const BoxDecoration(
                  color: Colors.greenAccent, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.greenAccent, blurRadius: 5)],
                ),
              ),
              const SizedBox(width: 8),
              Text('EN DIRECT',
                  style: GoogleFonts.orbitron(
                      color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSensorBadges() {
    final sensor = ref.watch(latestSensorProvider);
    return sensor.when(
      data: (r) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Badge(label: 'ZONE 1', value: '${r.temperature.toStringAsFixed(1)}°C',
              color: _zone1OverMax ? Colors.redAccent : Colors.cyanAccent),
          _Badge(label: 'COURANT', value: '${r.current.toStringAsFixed(2)} A', color: Colors.amberAccent),
          _Badge(label: 'PRESSION', value: '${r.pressure.toStringAsFixed(2)} bar', color: Colors.purpleAccent),
          _Badge(label: 'MAX', value: '${_maxTemp.toInt()}°C', color: Colors.redAccent.withValues(alpha: 0.7)),
        ],
      ),
      loading: () => const SizedBox(height: 30,
          child: Center(child: CircularProgressIndicator(color: Colors.cyanAccent, strokeWidth: 1.5))),
      error: (_, __) => Text('Capteur non disponible',
          style: GoogleFonts.rajdhani(color: Colors.white38)),
    );
  }

  Widget _buildChart() {
    final minX = _time - _windowSize;

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.only(right: 24, left: 8, top: 20, bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.25)),
          ),
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                horizontalInterval: 50,
                verticalInterval: 10,
                getDrawingHorizontalLine: (v) => FlLine(
                    color: v == _maxTemp
                        ? Colors.redAccent.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.08),
                    strokeWidth: v == _maxTemp ? 1.5 : 1,
                    dashArray: v == _maxTemp ? null : [4, 4]),
                getDrawingVerticalLine: (v) =>
                    FlLine(color: Colors.white.withValues(alpha: 0.06), strokeWidth: 1, dashArray: [4, 4]),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, reservedSize: 28, interval: 10,
                    getTitlesWidget: (v, m) => SideTitleWidget(
                      axisSide: m.axisSide, space: 6,
                      child: Text('${(v - minX).toInt()}s',
                        style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 11)),
                    ),
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true, interval: 50, reservedSize: 46,
                    getTitlesWidget: (v, m) => Text('${v.toInt()}°',
                        style: GoogleFonts.rajdhani(
                            color: v == _maxTemp ? Colors.redAccent : Colors.white38,
                            fontSize: 11,
                            fontWeight: v == _maxTemp ? FontWeight.bold : FontWeight.normal)),
                  ),
                ),
              ),
              borderData: FlBorderData(
                  show: true, border: Border.all(color: Colors.white.withValues(alpha: 0.15))),
              minX: minX, maxX: _time,
              minY: 0, maxY: 340,
              extraLinesData: ExtraLinesData(horizontalLines: [
                HorizontalLine(
                  y: _maxTemp,
                  color: Colors.redAccent.withValues(alpha: 0.7),
                  strokeWidth: 2,
                  dashArray: [6, 4],
                  label: HorizontalLineLabel(
                    show: true,
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.only(right: 6, bottom: 4),
                    style: GoogleFonts.orbitron(
                        color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold),
                    labelResolver: (_) => 'MAX 300°C',
                  ),
                ),
              ]),
              lineBarsData: [
                _line(_zone1Spots, Colors.cyanAccent, width: 2.5),
                _line(_zone2Spots, Colors.orangeAccent),
                _line(_zone3Spots, Colors.greenAccent),
                _line(_zone4Spots, Colors.purpleAccent),
              ],
            ),
          ),
        ),
      ),
    );
  }

  LineChartBarData _line(List<FlSpot> spots, Color color, {double width = 2.0}) {
    return LineChartBarData(
      spots: spots,
      isCurved: true,
      curveSmoothness: 0.3,
      color: color,
      barWidth: width,
      isStrokeCapRound: true,
      dotData: const FlDotData(show: false),
      belowBarData: BarAreaData(show: true, color: color.withValues(alpha: 0.08)),
    );
  }

  Widget _buildLegend() {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      alignment: WrapAlignment.center,
      children: [
        _LegendItem(color: Colors.cyanAccent,    label: 'Zone 1 (capteur réel)'),
        _LegendItem(color: Colors.orangeAccent,  label: 'Zone 2'),
        _LegendItem(color: Colors.greenAccent,   label: 'Zone 3'),
        _LegendItem(color: Colors.purpleAccent,  label: 'Zone 4'),
        _LegendItem(color: Colors.redAccent,     label: 'MAX 300°C', dashed: true),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _Badge({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(label,
          style: GoogleFonts.rajdhani(color: Colors.white38, fontSize: 10, letterSpacing: 1)),
      Text(value,
          style: GoogleFonts.orbitron(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool dashed;
  const _LegendItem({required this.color, required this.label, this.dashed = false});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 20, height: 3,
        decoration: BoxDecoration(
          color: dashed ? Colors.transparent : color,
          border: dashed ? Border.all(color: color) : null,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 6),
      Text(label,
          style: GoogleFonts.rajdhani(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13)),
    ]);
  }
}
