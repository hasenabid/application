import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/zones/presentation/zones_controller.dart';

final tempRequestRepositoryProvider = Provider<TempRequestRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return TempRequestRepository(dio);
});

final pendingRequestsProvider =
    FutureProvider.autoDispose<List<TempRequest>>((ref) async {
  final repo = ref.watch(tempRequestRepositoryProvider);
  return repo.fetchRequests(status: 'PENDING');
});

final pendingCountProvider = FutureProvider.autoDispose<int>((ref) async {
  final repo = ref.watch(tempRequestRepositoryProvider);
  try {
    final response = await repo._dio.get('/temp-requests/pending-count');
    return (response.data['count'] as num).toInt();
  } catch (_) {
    return 0;
  }
});

class TempRequestRepository {
  final Dio _dio;
  TempRequestRepository(this._dio);

  Future<TempRequest> submitRequest({
    required String zoneId,
    required String zoneName,
    required String workerName,
    required double currentMaxTemp,
    required double requestedMaxTemp,
  }) async {
    final response = await _dio.post('/temp-requests', data: {
      'zoneId': zoneId,
      'zoneName': zoneName,
      'workerName': workerName,
      'currentMaxTemp': currentMaxTemp,
      'requestedMaxTemp': requestedMaxTemp,
    });
    return TempRequest.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<TempRequest>> fetchRequests({String? status}) async {
    try {
      final response = await _dio.get(
        '/temp-requests',
        queryParameters: status != null ? {'status': status} : null,
      );
      final list = response.data as List<dynamic>;
      return list
          .map((e) => TempRequest.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> approve(int id) async {
    await _dio.put('/temp-requests/$id/approve');
  }

  Future<void> reject(int id) async {
    await _dio.put('/temp-requests/$id/reject');
  }
}

class TempRequest {
  final int id;
  final String zoneId;
  final String zoneName;
  final String workerName;
  final double currentMaxTemp;
  final double requestedMaxTemp;
  final String status;
  final String createdAt;

  TempRequest({
    required this.id,
    required this.zoneId,
    required this.zoneName,
    required this.workerName,
    required this.currentMaxTemp,
    required this.requestedMaxTemp,
    required this.status,
    required this.createdAt,
  });

  factory TempRequest.fromJson(Map<String, dynamic> json) => TempRequest(
        id:               (json['id'] as num).toInt(),
        zoneId:           json['zoneId'] as String,
        zoneName:         json['zoneName'] as String,
        workerName:       json['workerName'] as String,
        currentMaxTemp:   (json['currentMaxTemp'] as num).toDouble(),
        requestedMaxTemp: (json['requestedMaxTemp'] as num).toDouble(),
        status:           json['status'] as String,
        createdAt:        json['createdAt'] as String? ?? '',
      );
}
