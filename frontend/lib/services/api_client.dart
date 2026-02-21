import 'package:dio/dio.dart';

class ApiClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://10.0.2.2:3000/api',
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 8),
      headers: {'Content-Type': 'application/json'},
    ),
  );

  static Dio get instance => _dio;
}
