import 'package:buddbull/core/error/app_exception.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:flutter/material.dart';

/// Localized user-facing message for [AppException].
extension AppExceptionL10n on AppException {
  String localizedMessage(BuildContext context) {
    if (serverMessage != null && serverMessage!.isNotEmpty) {
      return serverMessage!;
    }
    final l10n = context.l10n;
    return switch (type) {
      AppExceptionType.network => l10n.networkError,
      AppExceptionType.unauthorised => l10n.sessionExpired,
      AppExceptionType.forbidden => l10n.unauthorised,
      AppExceptionType.notFound => l10n.resourceNotFound,
      AppExceptionType.conflict => l10n.conflictError,
      AppExceptionType.badRequest => l10n.badRequestError,
      AppExceptionType.validation => l10n.validationError,
      AppExceptionType.rateLimited => l10n.rateLimitedError,
      AppExceptionType.server => l10n.serverError,
      AppExceptionType.unknown => l10n.genericError,
    };
  }
}
