// ─── theme_provider.dart ──────────────────────────────────────────────────────
// Manages the app-wide dark/light mode preference.
// Persists the user's choice using SharedPreferences so the theme is
// remembered even after the app is closed and reopened.
//
// How it works:
//   1. On startup, it reads the saved theme preference from SharedPreferences.
//   2. If none is saved, it defaults to ThemeMode.system (follows phone setting).
//   3. When the user toggles the theme in SettingsScreen, it saves the new value
//      to SharedPreferences AND updates the state, causing the whole app to rebuild.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Re-exports AppTheme so any file that imports theme_provider.dart also gets
// access to AppTheme colors and styles without an extra import line.
export '../core/app_theme.dart';

// Key used for persisting theme preference locally in SharedPreferences.
// SharedPreferences stores key-value pairs — this string is the key.
const _themeKey = 'isDarkMode';

// ─── ThemeModeNotifier ────────────────────────────────────────────────────────
// A Riverpod Notifier that manages ThemeMode (light/dark/system).
/// Notifier that manages theme mode state with persistence.
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    // Load saved preference asynchronously after initial state is set.
    // This is non-blocking — the UI renders immediately with the default,
    // then switches to the saved preference once it's read from disk.
    _loadThemePreference();
    return ThemeMode.system; // Default to system theme before prefs are loaded
  }

  /// Loads persisted theme preference from SharedPreferences.
  /// If a preference is found, it updates the state which triggers a UI rebuild.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool(_themeKey); // Returns null if never set
    if (isDark != null) {
      // Update state — this causes MaterialApp in main.dart to switch themes.
      state = isDark ? ThemeMode.dark : ThemeMode.light;
    }
  }

  /// Toggles between light and dark mode and persists the choice immediately.
  /// Called when the user taps the theme toggle in SettingsScreen.
  Future<void> toggleTheme() async {
    // Toggle: if currently dark, switch to light, and vice versa.
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    state = newMode; // Update in memory — causes immediate UI rebuild
    // Also save to disk so the preference survives app restarts.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, newMode == ThemeMode.dark);
  }
}

// ─── Provider Declaration ─────────────────────────────────────────────────────
// The themeModeProvider is watched by the root ClimaTalkApp widget in main.dart.
// When state changes here, the entire MaterialApp rebuilds with the new theme.
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);
