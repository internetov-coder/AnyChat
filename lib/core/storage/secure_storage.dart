import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// API key storage backed by the platform keystore/keystore-equivalent.
///
/// Keys are stored per provider under `api_key_<providerId>` and never leave
/// the device. The database only stores provider configuration (base URL
/// overrides), never secrets.
class SecureKeyStore {
  SecureKeyStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static String keyName(String providerId) => 'api_key_$providerId';

  Future<String?> readKey(String providerId) =>
      _storage.read(key: keyName(providerId));

  Future<void> writeKey(String providerId, String key) =>
      _storage.write(key: keyName(providerId), value: key.trim());

  Future<void> deleteKey(String providerId) =>
      _storage.delete(key: keyName(providerId));

  /// `sk-...abcd` style mask for displaying a saved key.
  static String maskKey(String key) {
    final value = key.trim();
    if (value.length <= 2) return '••';
    if (value.length <= 10) {
      return '${value.substring(0, 2)}…${value.substring(value.length - 2)}';
    }
    return '${value.substring(0, 3)}...${value.substring(value.length - 4)}';
  }
}
