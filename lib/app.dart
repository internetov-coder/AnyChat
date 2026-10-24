import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/accent_colors.dart';
import 'features/home/main_shell.dart';
import 'features/settings/app_settings.dart';
import 'features/settings/state/settings_controller.dart';
import 'l10n/app_localizations.dart';

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
    final accentSeed = kAccentColors[settings.accentColor];
    final lightScheme = ColorScheme.fromSeed(
      seedColor: accentSeed ?? lightSeed ?? _seed,
      brightness: Brightness.light,
    );
    final darkScheme = ColorScheme.fromSeed(
      seedColor: accentSeed ?? darkSeed ?? _seed,
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
