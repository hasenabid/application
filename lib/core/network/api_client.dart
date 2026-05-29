import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/api_constants.dart';

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: ApiConstants.baseUrl,
    connectTimeout: const Duration(milliseconds: ApiConstants.connectTimeout),
    receiveTimeout: const Duration(milliseconds: ApiConstants.receiveTimeout),
    contentType: 'application/json',
  ));

  // Interceptor for logging and auth headers
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) {
      // e.g. options.headers['Authorization'] = 'Bearer token';
      return handler.next(options);
    },
    onResponse: (response, handler) {
      return handler.next(response);
    },
    onError: (DioException e, handler) {
      return handler.next(e);
    },
  ));

  return dio;
});
