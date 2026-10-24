import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../providers/domain/model_info.dart';
import '../../providers/domain/provider_registry.dart';
import '../../providers/presentation/providers_screen.dart';
import '../../providers/state/providers_state.dart';
import '../../settings/app_settings.dart';
import '../../settings/state/settings_controller.dart';

/// Model picker for the selected provider: search, prices, context window and
/// a manual "custom model id" escape hatch.
class ModelsScreen extends ConsumerStatefulWidget {
  const ModelsScreen({super.key});

  @override
  ConsumerState<ModelsScreen> createState() => _ModelsScreenState();
}

class _ModelsScreenState extends ConsumerState<ModelsScreen> {
  final TextEditingController _customController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _customController.dispose();
    super.dispose();
  }

  void _applyCustomModel(String providerId) {
    final modelId = _customController.text.trim();
    if (modelId.isEmpty) return;
    ref
        .read(settingsControllerProvider.notifier)
        .selectModel(providerId: providerId, modelId: modelId);
    _customController.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final settings = ref.watch(settingsControllerProvider).when(
          data: (AppSettings value) => value,
          loading: () => const AppSettings(),
          error: (Object error, StackTrace stack) => const AppSettings(),
        );
    final provider = findProvider(settings.selectedProviderId);
    final modelsAsync = ref.watch(providerModelsProvider(provider.id));
    final hasKey = ref.watch(hasApiKeyProvider(provider.id)).when(
          data: (bool value) => value,
          loading: () => false,
          error: (Object error, StackTrace stack) => false,
        );
    final selectedModelId = settings.selectedModelId;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.modelsTitle),
        actions: <Widget>[
          IconButton(
            onPressed: () =>
                ref.invalidate(providerModelsProvider(provider.id)),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          ListTile(
            leading: const Icon(Icons.dns_outlined),
            title: Text(provider.displayName),
            subtitle: Text('${l10n.formatLabel}: ${provider.format.name}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext routeContext) =>
                    const ProvidersScreen(),
              ),
            ),
          ),
          if (!hasKey)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                l10n.modelsNoKey,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: TextField(
              onChanged: (String value) =>
                  setState(() => _query = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: l10n.searchModels,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          modelsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (Object error, StackTrace stack) => Padding(
              padding: const EdgeInsets.all(24),
              child: Center(child: Text(l10n.errUnknown('$error'))),
            ),
            data: (List<ModelInfo> models) {
              final query = _query;
              final filtered = models.where((ModelInfo model) {
                if (query.isEmpty) return true;
                return model.id.toLowerCase().contains(query) ||
                    model.name.toLowerCase().contains(query);
              }).toList();
              if (filtered.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(l10n.modelsEmpty)),
                );
              }
              return Column(
                children: <Widget>[
                  for (final model in filtered)
                    _ModelTile(
                      key: ValueKey<String>('${provider.id}/${model.id}'),
                      model: model,
                      providerId: provider.id,
                      selected: model.id == selectedModelId,
                    ),

                ],
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _customController,
                    onSubmitted: (String value) =>
                        _applyCustomModel(provider.id),
                    decoration: InputDecoration(
                      labelText: l10n.customModelLabel,
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(28),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _applyCustomModel(provider.id),
                  child: Text(l10n.customModelApply),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

IconData _modalityIcon(ModelModality modality) {
  switch (modality) {
    case ModelModality.image:
      return Icons.image;
    case ModelModality.video:
      return Icons.videocam;
    case ModelModality.audio:
      return Icons.mic_none;
  }
}

class _ModelTile extends ConsumerWidget {
  const _ModelTile({
    super.key,
    required this.model,
    required this.providerId,
    required this.selected,
  });

  final ModelInfo model;
  final String providerId;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final inputPrice = model.inputPricePerM;
    final outputPrice = model.outputPricePerM;
    final contextWindow = model.contextWindow;

    return ListTile(
      title: Text(model.name, maxLines: 2, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            model.id,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (inputPrice != null || outputPrice != null)
            Text(
              [
                if (inputPrice != null)
                  l10n.priceInput(inputPrice.toStringAsFixed(2)),
                if (outputPrice != null)
                  l10n.priceOutput(outputPrice.toStringAsFixed(2)),
              ].join(' · '),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (contextWindow != null)
            Text(
              l10n.contextWindowLabel(contextWindow),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          if (model.modalities.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  for (final modality in ModelModality.values)
                    if (model.modalities.contains(modality))
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(_modalityIcon(modality), size: 14),
                      ),
                ],
              ),
            ),
        ],
      ),
      isThreeLine: true,
      trailing: selected ? Icon(Icons.check_circle, color: scheme.primary) : null,
      onTap: () async {
        await ref.read(settingsControllerProvider.notifier).selectModel(
              providerId: providerId,
              modelId: model.id,
              contextWindow: model.contextWindow,
              contextApproximate: model.approximateContext,
              inputPricePerM: model.inputPricePerM,
              outputPricePerM: model.outputPricePerM,
              modalities: model.modalities,
            );
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.modelSelected),
            duration: const Duration(seconds: 1),
          ),
        );
      },
    );
  }
}
