import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../domain/models/user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioProvider);
  return AuthRepository(dio);
});

class AuthRepository {
  // ignore: unused_field
  final Dio _dio;

  AuthRepository(this._dio);

  Future<User> login(String email, String password) async {
    try {
      // In a real app, you would uncomment this:
      // final response = await _dio.post('/login', data: {
      //   'email': email,
      //   'password': password,
      // });
      // return User.fromJson(response.data);

      // Mock implementation
      await Future.delayed(const Duration(seconds: 1));
      return const User(
        id: '123',
        email: 'admin@thermoplay.com',
        name: 'Admin User',
        token: 'mock_jwt_token',
        role: 'admin',
      );
    } catch (e) {
      throw Exception('Failed to login: $e');
    }
  }

  Future<void> logout() async {
    // In a real app: await _dio.post('/logout');
    await Future.delayed(const Duration(milliseconds: 500));
  }
}
