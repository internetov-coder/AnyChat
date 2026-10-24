import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'features/home/main_shell.dart';
import 'features/settings/app_settings.dart';
import 'features/settings/state/settings_controller.dart';
import 'l10n/app_localizations.dart';

/// Root widget: Material 3 themes (dynamic color on Android 12+), locale and
/// localization delegates.
class AnyChatApp extends ConsumerWidget {
  const AnyChatApp({super.key});

  static const Color _seed = Color(0xFF6750A4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsControllerProvider);
    final settings = settingsAsync.when(
      data: (AppSettings value) => value,
      loading: () => const AppSettings(),
      error: (Object error, StackTrace stack) => const AppSettings(),
    );
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        // `dynamic_color` 2.x hands out the ColorScheme of
        // `package:material_ui`, while ThemeData expects Flutter's own
        // ColorScheme. Re-seed Flutter's scheme from the dynamic primary
        // color (null on devices without Material You).
        final lightSeed = lightDynamic?.primary;
        final darkSeed = darkDynamic?.primary;
        return _buildApp(settings, lightSeed, darkSeed);
      },
    );
  }

  Widget _buildApp(
    AppSettings settings,
    Color? lightSeed,
    Color? darkSeed,
  ) {
    final lightScheme = ColorScheme.fromSeed(
      seedColor: lightSeed ?? _seed,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: darkSeed ?? _seed,
      brightness: Brightness.dark,
    );
    final localeCode = settings.localeCode;
    return MaterialApp(
      title: 'AnyChat',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorScheme: lightScheme),
      darkTheme: ThemeData(useMaterial3: true, colorScheme: darkScheme),
      themeMode: _themeMode(settings.themeMode),
      locale: localeCode == null ? null : Locale(localeCode),
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: const MainShell(),
    );
  }

  static ThemeMode _themeMode(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
