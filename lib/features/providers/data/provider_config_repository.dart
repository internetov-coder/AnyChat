import 'package:drift/drift.dart';

import '../../../core/storage/db.dart';

/// Per-provider configuration (base URL overrides). API keys never live here.
class ProviderConfigRepository {
  ProviderConfigRepository(this._db);

  final AppDatabase _db;

  Future<String?> baseUrlOverride(String providerId) async {
    final query = _db.select(_db.providersConfig)
      ..where((t) => t.providerId.equals(providerId));
    final row = await query.getSingleOrNull();
    return row?.baseUrlOverride;
  }

  Future<void> setBaseUrlOverride(String providerId, String? baseUrl) async {
    final trimmed = (baseUrl ?? '').trim();
    final normalized = trimmed.isEmpty ? null : trimmed;
    final query = _db.select(_db.providersConfig)
      ..where((t) => t.providerId.equals(providerId));
    final existing = await query.getSingleOrNull();
    if (existing == null) {
      if (normalized == null) return;
      await _db.into(_db.providersConfig).insert(
            ProvidersConfigCompanion.insert(
              providerId: providerId,
              baseUrlOverride: Value(normalized),
            ),
          );
      return;
    }
    await (_db.update(_db.providersConfig)
          ..where((t) => t.id.equals(existing.id)))
        .write(ProvidersConfigCompanion(baseUrlOverride: Value(normalized)));
  }
}
