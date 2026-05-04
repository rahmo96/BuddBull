import 'package:buddbull/core/constants/app_strings.dart';

/// Typed, user-facing exceptions that the UI can display cleanly.
class AppException implements Exception {
  const AppException({
    required this.message,
    required this.type,
    this.statusCode,
  });

  final String message;
  final AppExceptionType type;
  final int? statusCode;

  // ── Named constructors ────────────────────────────────────────
  const AppException.network()
      : message = AppStrings.networkError,
        type = AppExceptionType.network,
        statusCode = null;

  const AppException.unauthorised([String? msg])
      : message = msg ?? AppStrings.sessionExpired,
        type = AppExceptionType.unauthorised,
        statusCode = 401;

  const AppException.forbidden([String? msg])
      : message = msg ?? AppStrings.unauthorised,
        type = AppExceptionType.forbidden,
        statusCode = 403;

  const AppException.notFound([String? msg])
      : message = msg ?? 'Resource not found.',
        type = AppExceptionType.notFound,
        statusCode = 404;

  const AppException.conflict([String? msg])
      : message = msg ?? 'A conflict occurred.',
        type = AppExceptionType.conflict,
        statusCode = 409;

  const AppException.badRequest([String? msg])
      : message = msg ?? 'Invalid request.',
        type = AppExceptionType.badRequest,
        statusCode = 400;

  const AppException.validation([String? msg])
      : message = msg ?? 'Validation failed.',
        type = AppExceptionType.validation,
        statusCode = 422;

  const AppException.rateLimited()
      : message = 'Too many requests. Please slow down.',
        type = AppExceptionType.rateLimited,
        statusCode = 429;

  const AppException.server([String? msg])
      : message = msg ?? AppStrings.serverError,
        type = AppExceptionType.server,
        statusCode = 500;

  const AppException.unknown([String? msg])
      : message = msg ?? AppStrings.genericError,
        type = AppExceptionType.unknown,
        statusCode = null;

  // ── Helpers ───────────────────────────────────────────────────
  bool get isAuthError =>
      type == AppExceptionType.unauthorised ||
      type == AppExceptionType.forbidden;

  bool get isNetworkError => type == AppExceptionType.network;

  @override
  String toString() => 'AppException($type, $statusCode): $message';
}

enum AppExceptionType {
  network,
  unauthorised,
  forbidden,
  notFound,
  conflict,
  badRequest,
  validation,
  rateLimited,
  server,
  unknown,
}
