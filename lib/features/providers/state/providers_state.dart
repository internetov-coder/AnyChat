import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app_providers.dart';
import '../../../core/storage/db.dart';
import '../data/provider_adapter.dart';
import '../domain/model_info.dart';
import '../domain/provider_registry.dart';

part 'providers_state.g.dart';

/// Live per-provider configuration rows (base URL overrides).
@riverpod
Stream<List<ProviderConfig>> providerConfigs(Ref ref) =>
    ref.watch(providerConfigRepositoryProvider).watchAll();

/// Whether an API key is already stored for [providerId].
@riverpod
Future<bool> hasApiKey(Ref ref, String providerId) async {
  final keyStore = ref.watch(keyStoreProvider);
  final key = await keyStore.readKey(providerId);
  return key != null && key.trim().isNotEmpty;
}

/// Model catalog for a provider: the `/models` endpoint when available,
/// falling back to the curated static list (no key or request failure).
@riverpod
Future<List<ModelInfo>> providerModels(Ref ref, String providerId) async {
  final provider = findProvider(providerId);
  final keyStore = ref.watch(keyStoreProvider);
  final configRepo = ref.watch(providerConfigRepositoryProvider);
  if (provider.modelsEndpoint == null) return provider.fallbackModels;

  final key = await keyStore.readKey(providerId);
  if (key == null || key.trim().isEmpty) return provider.fallbackModels;

  final baseUrl = await configRepo.baseUrlOverride(providerId) ??
      provider.baseUrl;
  try {
    final models = await adapterFor(provider.format).fetchModels(
      apiKey: key.trim(),
      baseUrl: baseUrl,
    );
    return models.isEmpty ? provider.fallbackModels : models;
  } catch (_) {
    return provider.fallbackModels;
  }
}
