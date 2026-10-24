import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../app_settings.dart';

part 'settings_controller.g.dart';

/// Loads [AppSettings] once and persists every change.
@riverpod
class SettingsController extends _$SettingsController {
  @override
  Future<AppSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return AppSettings.fromPrefs(prefs);
  }

  AppSettings? get _value {
    final current = state;
    if (current is AsyncData<AppSettings>) return current.value;
    return null;
  }

  Future<void> _update(AppSettings Function(AppSettings change) change) async {
    final current = _value;
    if (current == null) return;
    final next = change(current);
    state = AsyncData(next);
    final prefs = await SharedPreferences.getInstance();
    await next.persist(prefs);
  }

  Future<void> setThemeMode(String value) =>
      _update((s) => s.copyWith(themeMode: value));

  Future<void> setLocale(String? value) =>
      _update((s) => s.copyWith(localeCode: value));

  Future<void> setTemperature(double value) =>
      _update((s) => s.copyWith(temperature: value));

  Future<void> setMaxTokens(int? value) =>
      _update((s) => s.copyWith(maxTokens: value));

  Future<void> setTimeoutSeconds(int value) =>
      _update((s) => s.copyWith(timeoutSeconds: value));

  Future<void> setSystemPrompt(String value) =>
      _update((s) => s.copyWith(systemPrompt: value));

  Future<void> selectProvider(String providerId) => _update(
        (s) => s
            .copyWith(selectedProviderId: providerId)
            .withoutModel(),
      );

  Future<void> selectModel({
    required String providerId,
    required String modelId,
    int? contextWindow,
    bool contextApproximate = true,
    double? inputPricePerM,
    double? outputPricePerM,
  }) {
    return _update(
      (s) => s.copyWith(
        selectedProviderId: providerId,
        selectedModelId: modelId,
        modelContextWindow: contextWindow,
        modelContextApproximate: contextApproximate,
        modelInputPricePerM: inputPricePerM,
        modelOutputPricePerM: outputPricePerM,
      ),
    );
  }
}
