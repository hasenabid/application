import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../domain/models/thermoplay_zone.dart';

// 🛠️ FIX REQUIS : On garde le nom générique 'dioProvider' pour que tous les autres fichiers de l'application compilent sans erreur !
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio();
  dio.options.baseUrl = 'http://192.168.1.111:8081';
  dio.options.connectTimeout = const Duration(seconds: 2);
  dio.options.receiveTimeout = const Duration(seconds: 2);
  return dio;
});

final zonesControllerProvider = AsyncNotifierProvider.autoDispose<ZonesNotifier, List<ThermoplayZone>>(
  () => ZonesNotifier(),
);

class ZonesNotifier extends AutoDisposeAsyncNotifier<List<ThermoplayZone>> {
  Timer? _pollingTimer;

  @override
  Future<List<ThermoplayZone>> build() async {
    _startSensorPolling();
    
    ref.onDispose(() {
      _pollingTimer?.cancel();
    });

    return _generateBaseZones(31.5, 0.0, 0.0);
  }

  void _startSensorPolling() {
    _pollingTimer?.cancel();
    
    _pollingTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      // 🛠️ FIX 'isMounted' : Dans un AsyncNotifier, on utilise 'ref.keepAlive()' ou une vérification sur l'état actif du state
      if (!ref.exists(zonesControllerProvider)) {
        timer.cancel();
        return;
      }

      final dio = ref.read(dioProvider);

      try {
        final response = await dio.get('/api/sensor/latest');
        
        if (response.statusCode == 200 && response.data != null) {
          final Map<String, dynamic> sensorData = response.data;
          
          final double liveTemperature = double.parse(sensorData['temperature']?.toString() ?? '31.5');
          final double liveCurrent = double.parse(sensorData['current']?.toString() ?? '0.0');
          final double livePressure = double.parse(sensorData['pressure']?.toString() ?? '0.0');

          state = AsyncData(_generateBaseZones(liveTemperature, liveCurrent, livePressure));
        }
      } catch (e) {
        // Reste silencieux en arrière-plan pour éviter les flashs à l'écran
      }
    });
  }

  List<ThermoplayZone> _generateBaseZones(double liveTemp, double liveCurrent, double livePressure) {
    final now = DateTime.now();
    int computedPower = (liveCurrent * 5).clamp(0, 100).toInt(); 

    return [
      ThermoplayZone(
        id: '1',
        name: 'Zone 1 - Chauffage principal',
        currentTemperature: liveTemp, // Lié à l'ESP32 en direct !
        setpointTemperature: 150,
        status: liveTemp > 155 ? ZoneStatus.high : (liveTemp < 145 ? ZoneStatus.low : ZoneStatus.ok),
        mode: ZoneMode.auto,
        powerPercent: computedPower > 0 ? computedPower : 16, // Lié au capteur de courant !
        isSSR: liveCurrent > 0.1,
        isFu: false,
        isR: false,
        lastUpdated: now,
      ),
      ThermoplayZone(
        id: '2',
        name: 'Zone 2 - Cylindre injection',
        currentTemperature: 152,
        setpointTemperature: 150,
        status: ZoneStatus.ok,
        mode: ZoneMode.auto,
        powerPercent: 22,
        isSSR: true,
        isFu: false,
        isR: false,
        lastUpdated: now,
      ),
      ThermoplayZone(
        id: '3',
        name: 'Zone 3 - Moule buse',
        currentTemperature: 148,
        setpointTemperature: 150,
        status: ZoneStatus.ok,
        mode: ZoneMode.auto,
        powerPercent: 10,
        isSSR: false,
        isFu: true,
        isR: false,
        lastUpdated: now,
      ),
      ThermoplayZone(
        id: '4',
        name: 'Zone 4 - Canal chaud',
        currentTemperature: 150,
        setpointTemperature: 150,
        status: ZoneStatus.ok,
        mode: ZoneMode.auto,
        powerPercent: 14,
        isSSR: true,
        isFu: false,
        isR: false,
        lastUpdated: now,
      ),
    ];
  }

  Future<void> updateSetpoints(Map<String, double> newSetpoints) async {
    final currentZones = state.valueOrNull;
    if (currentZones == null) return;
    
    final updatedZones = currentZones.map((z) {
      if (newSetpoints.containsKey(z.id)) {
        double newSet = newSetpoints[z.id]!;
        ZoneStatus newStatus = ZoneStatus.ok;
        if (z.currentTemperature > newSet + 5) {
          newStatus = ZoneStatus.high;
        } else if (z.currentTemperature < newSet - 5) {
          newStatus = ZoneStatus.low;
        }
        
        return z.copyWith(
          setpointTemperature: newSet,
          status: newStatus,
        );
      }
      return z;
    }).toList();
    
    state = AsyncData(updatedZones);
  }
}
