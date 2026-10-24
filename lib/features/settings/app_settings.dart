import 'package:shared_preferences/shared_preferences.dart';

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
    this.selectedProviderId = 'openai',
    this.selectedModelId,
    this.modelContextWindow,
    this.modelContextApproximate = true,
    this.modelInputPricePerM,
    this.modelOutputPricePerM,
  });

  static const Object _unspecified = Object();

  final String themeMode;
  final String? localeCode;
  final double temperature;
  final int? maxTokens;
  final int timeoutSeconds;
  final String systemPrompt;
  final String selectedProviderId;
  final String? selectedModelId;
  final int? modelContextWindow;
  final bool modelContextApproximate;
  final double? modelInputPricePerM;
  final double? modelOutputPricePerM;

  factory AppSettings.fromPrefs(SharedPreferences prefs) {
    return AppSettings(
      themeMode: prefs.getString('theme_mode') ?? 'system',
      localeCode: prefs.getString('locale_code'),
      temperature: prefs.getDouble('temperature') ?? 0.7,
      maxTokens: prefs.getInt('max_tokens'),
      timeoutSeconds: prefs.getInt('timeout_seconds') ?? 90,
      systemPrompt: prefs.getString('system_prompt') ?? '',
      selectedProviderId: prefs.getString('selected_provider') ?? 'openai',
      selectedModelId: prefs.getString('selected_model'),
      modelContextWindow: prefs.getInt('model_context_window'),
      modelContextApproximate: prefs.getBool('model_context_approx') ?? true,
      modelInputPricePerM: prefs.getDouble('model_input_price'),
      modelOutputPricePerM: prefs.getDouble('model_output_price'),
    );
  }

  AppSettings copyWith({
    String? themeMode,
    Object? localeCode = _unspecified,
    double? temperature,
    Object? maxTokens = _unspecified,
    int? timeoutSeconds,
    String? systemPrompt,
    String? selectedProviderId,
    Object? selectedModelId = _unspecified,
    Object? modelContextWindow = _unspecified,
    Object? modelContextApproximate = _unspecified,
    Object? modelInputPricePerM = _unspecified,
    Object? modelOutputPricePerM = _unspecified,
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
    );
  }

  Future<void> persist(SharedPreferences prefs) async {
    await prefs.setString('theme_mode', themeMode);
    await _setOrNull(prefs, 'locale_code', localeCode);
    await prefs.setDouble('temperature', temperature);
    await _setOrNull(prefs, 'max_tokens', maxTokens);
    await prefs.setInt('timeout_seconds', timeoutSeconds);
    await prefs.setString('system_prompt', systemPrompt);
    await prefs.setString('selected_provider', selectedProviderId);
    await _setOrNull(prefs, 'selected_model', selectedModelId);
    await _setOrNull(prefs, 'model_context_window', modelContextWindow);
    await prefs.setBool('model_context_approx', modelContextApproximate);
    await _setOrNull(prefs, 'model_input_price', modelInputPricePerM);
    await _setOrNull(prefs, 'model_output_price', modelOutputPricePerM);
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
