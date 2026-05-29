import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/zones/presentation/zones_controller.dart';

final sensorRepositoryProvider = Provider<SensorRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return SensorRepository(dio);
});

final latestSensorProvider = FutureProvider.autoDispose<SensorReading>((ref) async {
  final repo = ref.watch(sensorRepositoryProvider);
  return repo.fetchLatest();
});

class SensorRepository {
  final Dio _dio;
  SensorRepository(this._dio);

  Future<SensorReading> fetchLatest() async {
    try {
      final response = await _dio.get('/sensor/latest');
      final data = response.data as Map<String, dynamic>;
      return SensorReading(
        temperature: (data['temperature'] as num).toDouble(),
        current:     (data['current']     as num).toDouble(),
        pressure:    (data['pressure']    as num).toDouble(),
        receivedAt:  data['receivedAt']   as String,
      );
    } catch (_) {
      return SensorReading(
        temperature: 0,
        current: 0,
        pressure: 0,
        receivedAt: '',
      );
    }
  }
}

class SensorReading {
  final double temperature;
  final double current;
  final double pressure;
  final String receivedAt;

  SensorReading({
    required this.temperature,
    required this.current,
    required this.pressure,
    required this.receivedAt,
  });
}
