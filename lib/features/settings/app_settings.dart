import 'package:shared_preferences/shared_preferences.dart';

import '../providers/domain/model_info.dart';

/// Global app settings (generation params, UI preferences, selected model).
///
/// Persisted with `shared_preferences`; API keys are *not* part of this class.
class AppSettings {
  const AppSettings({
    this.themeMode = 'system',
    this.localeCode,
    this.temperature = 0.7,
    this.maxTokens,
    this.timeoutSeconds = 90,
    this.systemPrompt = '',
    this.topP = 1.0,
    this.frequencyPenalty = 0.0,
    this.topK,
    this.contextLimit,
    this.historyDepth,
    this.accentColor = 'system',
    this.reasoningEffort = '',
    this.selectedProviderId = 'openai',
    this.selectedModelId,
    this.modelContextWindow,
    this.modelContextApproximate = true,
    this.modelInputPricePerM,
    this.modelOutputPricePerM,
    this.modelModalities = const <ModelModality>{},
    this.modelReasoningEfforts = const <String>[],
  });

  static const Object _unspecified = Object();

  final String themeMode;
  final String? localeCode;
  final double temperature;
  final int? maxTokens;
  final int timeoutSeconds;
  final String systemPrompt;

  /// Nucleus sampling (sent to every wire format).
  final double topP;

  /// OpenAI-only repetition penalty.
  final double frequencyPenalty;

  /// Gemini-only candidate count; `null` = do not send.
  final int? topK;

  /// Manual context-window override (tokens) for the context bar;
  /// `null` = use the model metadata (or 128k approx).
  final int? contextLimit;

  /// Send only the last N messages of the history; `null` = everything.
  final int? historyDepth;

  /// Accent seed from `kAccentColors`; `'system'` = dynamic color / default.
  final String accentColor;

  /// `''` (not sent), `low`, `medium` or `high` - OpenAI reasoning effort.
  final String reasoningEffort;
  final String selectedProviderId;
  final String? selectedModelId;
  final int? modelContextWindow;
  final bool modelContextApproximate;
  final double? modelInputPricePerM;
  final double? modelOutputPricePerM;

  /// Media inputs the selected model supports (drives the attach button).
  final Set<ModelModality> modelModalities;

  /// Thinking levels advertised by the catalog for the selected model.
  final List<String> modelReasoningEfforts;

  factory AppSettings.fromPrefs(SharedPreferences prefs) {
    return AppSettings(
      themeMode: prefs.getString('theme_mode') ?? 'system',
      localeCode: prefs.getString('locale_code'),
      temperature: prefs.getDouble('temperature') ?? 0.7,
      maxTokens: prefs.getInt('max_tokens'),
      timeoutSeconds: prefs.getInt('timeout_seconds') ?? 90,
      systemPrompt: prefs.getString('system_prompt') ?? '',
      topP: prefs.getDouble('top_p') ?? 1.0,
      frequencyPenalty: prefs.getDouble('frequency_penalty') ?? 0.0,
      topK: prefs.getInt('top_k'),
      contextLimit: prefs.getInt('context_limit'),
      historyDepth: prefs.getInt('history_depth'),
      accentColor: prefs.getString('accent_color') ?? 'system',
      reasoningEffort: prefs.getString('reasoning_effort') ?? '',
      selectedProviderId: prefs.getString('selected_provider') ?? 'openai',
      selectedModelId: prefs.getString('selected_model'),
      modelContextWindow: prefs.getInt('model_context_window'),
      modelContextApproximate: prefs.getBool('model_context_approx') ?? true,
      modelInputPricePerM: prefs.getDouble('model_input_price'),
      modelOutputPricePerM: prefs.getDouble('model_output_price'),
      modelModalities: _parseModalities(prefs.getString('model_modalities')),
      modelReasoningEfforts:
          _parseTokens(prefs.getString('model_reasoning_efforts')),
    );
  }

  static List<String> _parseTokens(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <String>[];
    return raw.split(' ').where((t) => t.isNotEmpty).toList();
  }

  static Set<ModelModality> _parseModalities(String? raw) {
    if (raw == null || raw.trim().isEmpty) return const <ModelModality>{};
    final out = <ModelModality>{};
    for (final token in raw.split(' ')) {
      for (final modality in ModelModality.values) {
        if (modality.name == token) out.add(modality);
      }
    }
    return out;
  }

  AppSettings copyWith({
    String? themeMode,
    Object? localeCode = _unspecified,
    double? temperature,
    Object? maxTokens = _unspecified,
    int? timeoutSeconds,
    String? systemPrompt,
    double? topP,
    double? frequencyPenalty,
    Object? topK = _unspecified,
    Object? contextLimit = _unspecified,
    Object? historyDepth = _unspecified,
    String? accentColor,
    String? reasoningEffort,
    String? selectedProviderId,
    Object? selectedModelId = _unspecified,
    Object? modelContextWindow = _unspecified,
    Object? modelContextApproximate = _unspecified,
    Object? modelInputPricePerM = _unspecified,
    Object? modelOutputPricePerM = _unspecified,
    Set<ModelModality>? modelModalities,
    List<String>? modelReasoningEfforts,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      localeCode:
          identical(localeCode, _unspecified) ? this.localeCode : localeCode as String?,
      temperature: temperature ?? this.temperature,
      maxTokens:
          identical(maxTokens, _unspecified) ? this.maxTokens : maxTokens as int?,
      timeoutSeconds: timeoutSeconds ?? this.timeoutSeconds,
      systemPrompt: systemPrompt ?? this.systemPrompt,
      topP: topP ?? this.topP,
      frequencyPenalty: frequencyPenalty ?? this.frequencyPenalty,
      topK: identical(topK, _unspecified) ? this.topK : topK as int?,
      contextLimit: identical(contextLimit, _unspecified)
          ? this.contextLimit
          : contextLimit as int?,
      historyDepth: identical(historyDepth, _unspecified)
          ? this.historyDepth
          : historyDepth as int?,
      accentColor: accentColor ?? this.accentColor,
      reasoningEffort: reasoningEffort ?? this.reasoningEffort,
      selectedProviderId: selectedProviderId ?? this.selectedProviderId,
      selectedModelId: identical(selectedModelId, _unspecified)
          ? this.selectedModelId
          : selectedModelId as String?,
      modelContextWindow: identical(modelContextWindow, _unspecified)
          ? this.modelContextWindow
          : modelContextWindow as int?,
      modelContextApproximate: identical(modelContextApproximate, _unspecified)
          ? this.modelContextApproximate
          : modelContextApproximate as bool,
      modelInputPricePerM: identical(modelInputPricePerM, _unspecified)
          ? this.modelInputPricePerM
          : modelInputPricePerM as double?,
      modelOutputPricePerM: identical(modelOutputPricePerM, _unspecified)
          ? this.modelOutputPricePerM
          : modelOutputPricePerM as double?,
      modelModalities: modelModalities ?? this.modelModalities,
      modelReasoningEfforts:
          modelReasoningEfforts ?? this.modelReasoningEfforts,
    );
  }

  /// Drops the model selection (used when the provider changes).
  AppSettings withoutModel() {
    return copyWith(
      selectedModelId: null,
      modelContextWindow: null,
      modelContextApproximate: true,
      modelInputPricePerM: null,
      modelOutputPricePerM: null,
      modelModalities: const <ModelModality>{},
      modelReasoningEfforts: const <String>[],
    );
  }

  Future<void> persist(SharedPreferences prefs) async {
    await prefs.setString('theme_mode', themeMode);
    await _setOrNull(prefs, 'locale_code', localeCode);
    await prefs.setDouble('temperature', temperature);
    await _setOrNull(prefs, 'max_tokens', maxTokens);
    await prefs.setInt('timeout_seconds', timeoutSeconds);
    await prefs.setString('system_prompt', systemPrompt);
    await prefs.setDouble('top_p', topP);
    await prefs.setDouble('frequency_penalty', frequencyPenalty);
    await _setOrNull(prefs, 'top_k', topK);
    await _setOrNull(prefs, 'context_limit', contextLimit);
    await _setOrNull(prefs, 'history_depth', historyDepth);
    await prefs.setString('accent_color', accentColor);
    await prefs.setString('reasoning_effort', reasoningEffort);
    await _setOrNull(
      prefs,
      'model_reasoning_efforts',
      modelReasoningEfforts.isEmpty ? null : modelReasoningEfforts.join(' '),
    );
    await prefs.setString('selected_provider', selectedProviderId);
    await _setOrNull(prefs, 'selected_model', selectedModelId);
    await _setOrNull(prefs, 'model_context_window', modelContextWindow);
    await prefs.setBool('model_context_approx', modelContextApproximate);
    await _setOrNull(prefs, 'model_input_price', modelInputPricePerM);
    await _setOrNull(prefs, 'model_output_price', modelOutputPricePerM);
    await _setOrNull(
      prefs,
      'model_modalities',
      modelModalities.isEmpty
          ? null
          : modelModalities.map((m) => m.name).join(' '),
    );
  }

  Future<void> _setOrNull(SharedPreferences prefs, String key, Object? value) {
    if (value == null) return prefs.remove(key);
    if (value is String) return prefs.setString(key, value);
    if (value is int) return prefs.setInt(key, value);
    if (value is double) return prefs.setDouble(key, value);
    if (value is bool) return prefs.setBool(key, value);
    return prefs.remove(key);
  }
}
