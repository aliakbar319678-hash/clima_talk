// ThemeProvider manages the app-wide dark/light mode preference.
// Persists the user's choice using SharedPreferences.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

export '../core/app_theme.dart';

// Key used for persisting theme preference locally
const _themeKey = 'isDarkMode';

/// Notifier that manages theme mode state with persistence.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Load saved preference asynchronously after initial state is set
    _loadThemePreference();
    return ThemeMode.system; // Default to system theme
  }

  /// Loads persisted theme preference from SharedPreferences.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey);
    if (isDark != null) {
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  /// Toggles between light and dark mode and persists the choice.
  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, newMode == ThemeMode.dark);
  }
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

