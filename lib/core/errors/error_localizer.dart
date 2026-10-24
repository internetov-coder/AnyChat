import '../../l10n/app_localizations.dart';
import 'api_error.dart';

/// Turns an [ApiError] into a localized, human-readable message.
///
/// The original payload ([ApiError.raw]) never reaches the user; it is only
/// kept for the debug log.
String localizeApiError(AppLocalizations l10n, ApiError error) {
  switch (error.type) {
    case ApiErrorType.authError:
      return l10n.errAuth;
    case ApiErrorType.rateLimit:
      return l10n.errRateLimit(error.retryAfter ?? 30);
    case ApiErrorType.quotaExceeded:
      return l10n.errQuota;
    case ApiErrorType.modelNotFound:
      return l10n.errModelNotFound;
    case ApiErrorType.contextLengthExceeded:
      return l10n.errContextLength;
    case ApiErrorType.invalidRequest:
      return l10n.errInvalidRequest(_truncate(error.details ?? error.raw));
    case ApiErrorType.networkError:
      return l10n.errNetwork;
    case ApiErrorType.timeout:
      return l10n.errTimeout;
    case ApiErrorType.serverError:
      return l10n.errServer;
    case ApiErrorType.unknown:
      return l10n.errUnknown(_truncate(error.raw));
  }
}

String _truncate(String value, [int maxLength = 200]) {
  final trimmed = value.trim();
  if (trimmed.length <= maxLength) return trimmed;
  return '${trimmed.substring(0, maxLength)}…';
}
