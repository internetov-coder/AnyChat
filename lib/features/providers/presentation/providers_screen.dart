import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app_providers.dart';
import '../../../core/storage/secure_storage.dart';
import '../../../l10n/app_localizations.dart';
import '../data/provider_adapter.dart';
import '../domain/provider_registry.dart';
import '../state/providers_state.dart';
import '../../settings/state/settings_controller.dart';

/// Provider picker with per-provider API key and Base URL management.
class ProvidersScreen extends ConsumerWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedId = ref.watch(settingsControllerProvider).when(
          data: (value) => value.selectedProviderId,
          loading: () => 'openai',
          error: (Object error, StackTrace stack) => 'openai',
        );

    return Scaffold(
      appBar: AppBar(title: Text(l10n.providersTitle)),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: <Widget>[
          _ProviderDetail(
            key: ValueKey<String>(selectedId),
            providerId: selectedId,
          ),
          const Divider(height: 1),
          for (final provider in kProviders)
            ListTile(
              leading: Icon(
                selectedId == provider.id
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
              ),
              title: Text(provider.displayName),
              subtitle: Text('${l10n.formatLabel}: ${provider.format.name}'),
              selected: selectedId == provider.id,
              onTap: () => ref
                  .read(settingsControllerProvider.notifier)
                  .selectProvider(provider.id),
            ),
        ],
      ),
    );
  }
}

class _ProviderDetail extends ConsumerStatefulWidget {
  const _ProviderDetail({
    super.key,
    required this.providerId,
  });

  final String providerId;

  @override
  ConsumerState<_ProviderDetail> createState() => _ProviderDetailState();
}

class _ProviderDetailState extends ConsumerState<_ProviderDetail> {
  final TextEditingController _keyController = TextEditingController();
  final TextEditingController _urlController = TextEditingController();
  bool _started = false;
  bool _loading = true;
  bool _hasKey = false;
  bool _checking = false;
  String? _keyMask;
  String? _checkResult;

  @override
  void dispose() {
    _keyController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final key =
        await ref.read(keyStoreProvider).readKey(widget.providerId);
    final url = await ref
        .read(providerConfigRepositoryProvider)
        .baseUrlOverride(widget.providerId);
    if (!mounted) return;
    final trimmedKey = (key ?? '').trim();
    setState(() {
      _hasKey = trimmedKey.isNotEmpty;
      _keyMask = trimmedKey.isEmpty
          ? null
          : SecureKeyStore.maskKey(trimmedKey);
      _urlController.text = url ?? '';
      _loading = false;
    });
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _saveKey() async {
    final l10n = AppLocalizations.of(context);
    final value = _keyController.text.trim();
    if (value.isEmpty) {
      _showMessage(l10n.keyMissing);
      return;
    }
    await ref.read(keyStoreProvider).writeKey(widget.providerId, value);
    ref.invalidate(hasApiKeyProvider(widget.providerId));
    ref.invalidate(providerModelsProvider(widget.providerId));
    if (!mounted) return;
    final mask = SecureKeyStore.maskKey(value);
    setState(() {
      _hasKey = true;
      _keyMask = mask;
      _checkResult = null;
      _keyController.clear();
    });
    _showMessage(l10n.keySavedMasked(mask));
  }

  Future<void> _deleteKey() async {
    final l10n = AppLocalizations.of(context);
    await ref.read(keyStoreProvider).deleteKey(widget.providerId);
    ref.invalidate(hasApiKeyProvider(widget.providerId));
    ref.invalidate(providerModelsProvider(widget.providerId));
    if (!mounted) return;
    setState(() {
      _hasKey = false;
      _keyMask = null;
      _checkResult = null;
      _keyController.clear();
    });
    _showMessage(l10n.keyRemoved);
  }

  Future<void> _checkKey() async {
    final l10n = AppLocalizations.of(context);
    final provider = findProvider(widget.providerId);
    final typed = _keyController.text.trim();
    final key = typed.isNotEmpty
        ? typed
        : await ref.read(keyStoreProvider).readKey(widget.providerId);
    final apiKey = (key ?? '').trim();
    if (apiKey.isEmpty) {
      _showMessage(l10n.keyMissing);
      return;
    }
    if (!mounted) return;
    setState(() {
      _checking = true;
      _checkResult = null;
    });
    final urlText = _urlController.text.trim();
    final baseUrl = urlText.isEmpty ? provider.baseUrl : urlText;
    String result;
    try {
      // Always probe with a minimal completion: some model catalogs (e.g.
      // the Vercel AI Gateway) are public and would not prove the key works.
      final probe = ChatParams(
        apiKey: apiKey,
        baseUrl: baseUrl,
        model: provider.defaultModel,
        turns: const <ChatTurn>[
          ChatTurn(role: 'user', content: 'ping'),
        ],
        maxTokens: 1,
        timeout: const Duration(seconds: 30),
      );
      await for (final _ in adapterFor(provider.format).streamChat(probe)) {
        // Drain the stream: a completed request proves the key works.
      }
      result = 'ok';
    } catch (_) {
      result = 'fail';
    }
    if (!mounted) return;
    setState(() {
      _checking = false;
      _checkResult = result;
    });
  }

  Future<void> _saveBaseUrl(String value) {
    return ref
        .read(providerConfigRepositoryProvider)
        .setBaseUrlOverride(widget.providerId, value);
  }

  @override
  Widget build(BuildContext context) {
    if (!_started) {
      _started = true;
      _loadInitial();
    }
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = findProvider(widget.providerId);

    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final mask = _keyMask;
    final checkResult = _checkResult;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  provider.displayName,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              Text(
                '${l10n.formatLabel}: ${provider.format.name}',
                style: theme.textTheme.labelSmall,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _hasKey && mask != null
                ? '${l10n.apiKeyLabel}: $mask'
                : l10n.noKeyYet,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _keyController,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: InputDecoration(
              labelText: l10n.apiKeyLabel,
              hintText: 'sk-...',
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(28),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              FilledButton.icon(
                onPressed: _saveKey,
                icon: const Icon(Icons.save_outlined, size: 18),
                label: Text(l10n.saveKey),
              ),
              if (_hasKey)
                OutlinedButton.icon(
                  onPressed: _deleteKey,
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(l10n.deleteKey),
                ),
              if (_checking)
                const Padding(
                  padding: EdgeInsets.all(8),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: _checkKey,
                  icon: const Icon(Icons.verified_user_outlined, size: 18),
                  label: Text(l10n.checkKey),
                ),
            ],
          ),
          if (checkResult != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                checkResult == 'ok' ? l10n.keyOk : l10n.keyFailed,
                style: TextStyle(
                  color: checkResult == 'ok'
                      ? const Color(0xFF2E7D32)
                      : scheme.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          const SizedBox(height: 16),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _urlController,
                  onChanged: _saveBaseUrl,
                  decoration: InputDecoration(
                    labelText: l10n.baseUrlOverride,
                    hintText: provider.baseUrl,
                    helperText: l10n.baseUrlHint,
                    isDense: true,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(28),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: l10n.baseUrlReset,
                onPressed: () {
                  _urlController.clear();
                  _saveBaseUrl('');
                },
                icon: const Icon(Icons.restore),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
