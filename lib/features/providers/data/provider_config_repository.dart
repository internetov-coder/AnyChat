import 'package:drift/drift.dart';

import '../../../core/network/api_format.dart';
import '../../../core/storage/db.dart';
import '../domain/custom_provider.dart';

class ProviderConfigRepository {
  ProviderConfigRepository(this._db);

  final AppDatabase _db;

  Stream<List<CustomProvider>> watchAll() {
    final query = _db.select(_db.providersConfig)
      ..orderBy([(t) => OrderingTerm.asc(t.id)]);
    return query.watch().map(
          (rows) => rows.map(CustomProvider.fromRow).toList(),
        );
  }

  Future<CustomProvider?> getProvider(String providerId) async {
    final query = _db.select(_db.providersConfig)
      ..where((t) => t.providerId.equals(providerId));
    final row = await query.getSingleOrNull();
    return row == null ? null : CustomProvider.fromRow(row);
  }

  Future<CustomProvider> create({
    required String name,
    required String baseUrl,
    required ApiFormat format,
  }) async {
    final id = '${DateTime.now().microsecondsSinceEpoch}';
    final url = normalizeEndpoint(baseUrl);
    await _db.into(_db.providersConfig).insert(
          ProvidersConfigCompanion.insert(
            providerId: id,
            name: Value(name),
            baseUrl: Value(url),
            format: Value(format.name),
          ),
        );
    return CustomProvider(id: id, name: name, baseUrl: url, format: format);
  }

  Future<void> updateProvider(
    String providerId, {
    String? name,
    String? baseUrl,
    ApiFormat? format,
  }) {
    final companion = ProvidersConfigCompanion(
      name: name == null ? const Value.absent() : Value(name),
      baseUrl: baseUrl == null
          ? const Value.absent()
          : Value(normalizeEndpoint(baseUrl)),
      format: format == null ? const Value.absent() : Value(format.name),
    );
    return (_db.update(_db.providersConfig)
          ..where((t) => t.providerId.equals(providerId)))
        .write(companion);
  }

  Future<void> deleteProvider(String providerId) {
    return (_db.delete(_db.providersConfig)
          ..where((t) => t.providerId.equals(providerId)))
        .go();
  }

}
