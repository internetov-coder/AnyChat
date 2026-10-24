import '../../../core/storage/db.dart' as db;
import '../../../core/network/api_format.dart';

/// Trims surrounding spaces and trailing slashes from an endpoint.
String normalizeEndpoint(String url) {
  var trimmed = url.trim();
  while (trimmed.endsWith('/')) {
    trimmed = trimmed.substring(0, trimmed.length - 1);
  }
  return trimmed;
}

/// A user-defined provider: name + endpoint + wire format.
///
/// API keys are NOT part of this class - they live in secure storage under
/// `api_key_<id>`. AnyChat has no built-in providers; every endpoint is
/// added by the user.
class CustomProvider {
  const CustomProvider({
    required this.id,
    required this.name,
    required this.baseUrl,
    required this.format,
  });

  final String id;
  final String name;
  final String baseUrl;
  final ApiFormat format;

  factory CustomProvider.fromRow(db.ProviderConfig row) => CustomProvider(
        id: row.providerId,
        name: row.name.isNotEmpty ? row.name : row.providerId,
        baseUrl: row.baseUrl,
        format: _parseFormat(row.format),
      );

  static ApiFormat _parseFormat(String raw) {
    for (final format in ApiFormat.values) {
      if (format.name == raw) return format;
    }
    return ApiFormat.openai;
  }
}
