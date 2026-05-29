import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../domain/models/thermoplay_zone.dart';

final dioProvider = Provider((ref) {
  final dio = Dio();
  dio.options.baseUrl = 'http://10.0.2.2:8081/api'; // Mettre 10.0.2.2 si émulateur Android
  dio.options.connectTimeout = const Duration(seconds: 2);
  dio.options.receiveTimeout = const Duration(seconds: 2);
  return dio;
});

final zonesControllerProvider = AsyncNotifierProvider.autoDispose<ZonesNotifier, List<ThermoplayZone>>(
  () => ZonesNotifier(),
);

class ZonesNotifier extends AutoDisposeAsyncNotifier<List<ThermoplayZone>> {
  @override
  Future<List<ThermoplayZone>> build() async {
    final dio = ref.watch(dioProvider);

    try {
      final response = await dio.get('/zones');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        return data.map((json) => ThermoplayZone.fromJson(json)).toList();
      }
    } catch (e) {
      print('Erreur connexion API Spring Boot, utilisation du mock : $e');
    }

    // Fallback si le backend Spring Boot n'est pas encore démarré
    final now = DateTime.now();
    return [
      ThermoplayZone(
        id: '1',
        name: 'Zone 1',
        currentTemperature: 150,
        setpointTemperature: 150,
        status: ZoneStatus.ok,
        mode: ZoneMode.auto,
        powerPercent: 16,
        isSSR: true,
        isFu: false,
        isR: false,
        lastUpdated: now,
      ),
      ThermoplayZone(
        id: '2',
        name: 'Zone 2',
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
        name: 'Zone 3',
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
        name: 'Zone 4',
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
    // Dans un vrai projet, faire un PUT API ici
    // Exemple : await ref.read(dioProvider).put('/zones/setpoints', data: newSetpoints);
    
    final currentZones = state.valueOrNull;
    if (currentZones == null) return;
    
    final updatedZones = currentZones.map((z) {
      if (newSetpoints.containsKey(z.id)) {
        double newSet = newSetpoints[z.id]!;
        // Calcul dynamique du statut
        ZoneStatus newStatus = ZoneStatus.ok;
        if (z.currentTemperature > newSet + 5) {
          newStatus = ZoneStatus.high; // Rouge
        } else if (z.currentTemperature < newSet - 5) {
          newStatus = ZoneStatus.low; // Orange
        }
        
        return z.copyWith(
          setpointTemperature: newSet,
          status: newStatus,
        );
      }
      return z;
    }).toList();
    
    // Assigner un nouvel AsyncData force le rafraîchissement immédiat de l'UI
    state = AsyncData(updatedZones);
  }
}
