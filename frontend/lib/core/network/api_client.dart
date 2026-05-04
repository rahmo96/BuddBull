import 'package:buddbull/core/error/app_exception.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient();
});

// ── ApiClient ─────────────────────────────────────────────────────────────────
class ApiClient {
  ApiClient({void Function()? onSessionExpired}) : _onSessionExpired = onSessionExpired {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 12),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.addAll([
      _AuthInterceptor(_onSessionExpired),
      _LoggingInterceptor(),
    ]);
  }

  late final Dio _dio;
  final void Function()? _onSessionExpired;
  final Logger _log = Logger();

  // ── HTTP helpers ─────────────────────────────────────────────
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>(
        path,
        queryParameters: queryParams,
        options: options,
      );
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> post(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    Options? options,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> put(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        path,
        data: data,
        queryParameters: queryParams,
      );
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    dynamic data,
  }) async {
    try {
      final res = await _dio.patch<Map<String, dynamic>>(path, data: data);
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<void> delete(String path, {dynamic data}) async {
    try {
      await _dio.delete<void>(path, data: data);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<Map<String, dynamic>> postMultipart(
    String path,
    FormData formData,
  ) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        path,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return _unwrap(res);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────
  Map<String, dynamic> _unwrap(Response<Map<String, dynamic>> res) {
    if (res.data == null) return {};
    return res.data!;
  }

  /// Top-level message from API (e.g. "Validation failed").
  static String? _extractErrorMessage(dynamic body) {
    if (body is! Map) return null;
    final m = body['message'];
    return m is String ? m : null;
  }

  /// For 422: build one string from backend's errors[] (field + message).
  static String? _extractValidationMessage(dynamic body) {
    if (body is! Map) return null;
    final errors = body['errors'];
    if (errors is! List || errors.isEmpty) return null;
    final parts = <String>[];
    for (final e in errors) {
      if (e is Map && e['message'] is String) {
        parts.add(e['message'] as String);
      }
    }
    return parts.isEmpty ? null : parts.join(' ');
  }

  AppException _mapDioError(DioException e) {
    _log.e('API error', error: e);

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return const AppException.network();
    }

    final statusCode = e.response?.statusCode ?? 0;
    final body = e.response?.data;
    final String? message = _extractErrorMessage(body);
    final String? validationMessage =
        statusCode == 422 ? _extractValidationMessage(body) ?? message : null;

    return switch (statusCode) {
      400 => AppException.badRequest(message),
      401 => AppException.unauthorised(message),
      403 => AppException.forbidden(message),
      404 => AppException.notFound(message),
      409 => AppException.conflict(message),
      422 => AppException.validation(validationMessage),
      429 => const AppException.rateLimited(),
      >= 500 => AppException.server(message),
      _ => AppException.unknown(message),
    };
  }
}

// ── Auth interceptor ─────────────────────────────────────────────────────────
class _AuthInterceptor extends Interceptor {
  _AuthInterceptor(this._onSessionExpired);

  final void Function()? _onSessionExpired;

  void _sessionExpired() {
    final callback = _onSessionExpired;
    if (callback == null) return;
    // Run on next frame so router redirect happens reliably from UI thread
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final idToken = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (idToken != null) options.headers['Authorization'] = 'Bearer $idToken';
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401) _sessionExpired();
    handler.next(err);
  }
}

// ── Logging interceptor ──────────────────────────────────────────────────────
class _LoggingInterceptor extends Interceptor {
  final Logger _log = Logger();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _log.d('[→] ${options.method} ${options.path}');
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    _log.d('[←] ${response.statusCode} ${response.requestOptions.path}');
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _log.e('[✗] ${err.response?.statusCode} ${err.requestOptions.path}');
    handler.next(err);
  }
}
