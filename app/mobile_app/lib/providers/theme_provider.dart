import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/app_logger.dart';

enum AppThemeMode {
  system('跟随系统', CupertinoIcons.gear_alt),
  light('浅色模式', CupertinoIcons.sun_max),
  dark('深色模式', CupertinoIcons.moon);

  const AppThemeMode(this.label, this.icon);

  final String label;
  final IconData icon;

  Brightness? get forcedBrightness => switch (this) {
    AppThemeMode.light => Brightness.light,
    AppThemeMode.dark => Brightness.dark,
    AppThemeMode.system => null,
  };
}

final themeModeNotifierProvider =
    NotifierProvider<ThemeModeNotifier, AppThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<AppThemeMode> {
  static const _prefsKey = 'app.theme_mode';

  @override
  AppThemeMode build() {
    // Load persisted value asynchronously after the first frame.
    // Default to system mode until the stored value is available.
    Future.microtask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final storedIndex = prefs.getInt(_prefsKey);
        if (storedIndex != null &&
            storedIndex >= 0 &&
            storedIndex < AppThemeMode.values.length) {
          final mode = AppThemeMode.values[storedIndex];
          if (mode != state) {
            state = mode;
          }
        }
      } catch (e) {
        AppLogger.warn(
          'ThemeModeNotifier',
          'Failed to load theme mode',
          context: {'error': e.toString()},
        );
      }
    });

    return AppThemeMode.system;
  }

  Future<void> setMode(AppThemeMode mode) async {
    state = mode;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_prefsKey, mode.index);
    } catch (e) {
      AppLogger.warn(
        'ThemeModeNotifier',
        'Failed to persist theme mode',
        context: {'error': e.toString()},
      );
    }
  }
}
