/// Typed, user-facing exceptions that the UI can display cleanly.
class AppException implements Exception {
  const AppException({
    required this.type,
    this.serverMessage,
    this.statusCode,
  });

  final AppExceptionType type;
  final String? serverMessage;
  final int? statusCode;

  // ── Named constructors ────────────────────────────────────────
  const AppException.network()
      : type = AppExceptionType.network,
        serverMessage = null,
        statusCode = null;

  const AppException.unauthorised([String? msg])
      : type = AppExceptionType.unauthorised,
        serverMessage = msg,
        statusCode = 401;

  const AppException.forbidden([String? msg])
      : type = AppExceptionType.forbidden,
        serverMessage = msg,
        statusCode = 403;

  const AppException.notFound([String? msg])
      : type = AppExceptionType.notFound,
        serverMessage = msg,
        statusCode = 404;

  const AppException.conflict([String? msg])
      : type = AppExceptionType.conflict,
        serverMessage = msg,
        statusCode = 409;

  const AppException.badRequest([String? msg])
      : type = AppExceptionType.badRequest,
        serverMessage = msg,
        statusCode = 400;

  const AppException.validation([String? msg])
      : type = AppExceptionType.validation,
        serverMessage = msg,
        statusCode = 422;

  const AppException.rateLimited()
      : type = AppExceptionType.rateLimited,
        serverMessage = null,
        statusCode = 429;

  const AppException.server([String? msg])
      : type = AppExceptionType.server,
        serverMessage = msg,
        statusCode = 500;

  const AppException.unknown([String? msg])
      : type = AppExceptionType.unknown,
        serverMessage = msg,
        statusCode = null;

  /// Legacy accessor — prefer [AppExceptionL10n.localizedMessage].
  String get message => serverMessage ?? type.name;

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
