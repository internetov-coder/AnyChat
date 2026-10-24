import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../app_providers.dart';
import '../data/provider_adapter.dart';
import '../domain/custom_provider.dart';
import '../domain/model_info.dart';

part 'providers_state.g.dart';

@riverpod
Stream<List<CustomProvider>> customProviders(Ref ref) =>
    ref.watch(providerConfigRepositoryProvider).watchAll();

@riverpod
Future<bool> hasApiKey(Ref ref, String providerId) async {
  final keyStore = ref.watch(keyStoreProvider);
  final key = await keyStore.readKey(providerId);
  return key != null && key.trim().isNotEmpty;
}

@riverpod
Future<List<ModelInfo>> providerModels(Ref ref, String providerId) async {
  final repo = ref.watch(providerConfigRepositoryProvider);
  final keyStore = ref.watch(keyStoreProvider);
  final provider = await repo.getProvider(providerId);
  if (provider == null) return const <ModelInfo>[];
  final key = await keyStore.readKey(providerId);
  if (key == null || key.trim().isEmpty) return const <ModelInfo>[];
  try {
    return await adapterFor(provider.format).fetchModels(
      apiKey: key.trim(),
      baseUrl: provider.baseUrl,
    );
  } catch (_) {
    return const <ModelInfo>[];
  }
}
