import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  /// 🔐 Fallback form login method
  Future<User> login(String email, String password) async {
    try {
      // Return a temporary mock user to bypass the credentials screen manually during testing
      await Future.delayed(const Duration(milliseconds: 500));
      return const User(
        id: '123',
        email: 'admin@thermoplay.com',
        name: 'Admin User',
        token: 'mock_jwt_token',
        role: 'ADMIN',
      );
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  /// 🕒 FIXED: Background short-polling method querying Spring Boot every 2 seconds
  Future<User?> checkPendingRfidScan() async {
    try {
      // Hits the exact @GetMapping("/pending") inside your RfidController.java
      final response = await _dio.get('/api/rfid/pending');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        // If the server confirms an unconsumed authorized card scan exists in memory
        if (data['found'] == true && data['authorized'] == true) {
          return User(
            id: data['id']?.toString() ?? '',
            email: '${data['role'].toString().toLowerCase()}@aura.com',
            name: data['name'] ?? 'Utilisateur RFID',
            token: data['token'] ?? '',
            role: data['role'] ?? 'WORKER', // Extracts 'ADMIN' or 'WORKER' directly from Java
          );
        }
      }
      return null;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Erreur lors du sondage du serveur backend RFID.');
    }
  }

  Future<void> logout() async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
