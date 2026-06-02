// ─── main.dart ────────────────────────────────────────────────────────────────
// This is the entry point of the ClimaTalk application.
// It configures the app-wide state management (Riverpod), sets system UI
// overlays, and defines the root MaterialApp widget with theme support.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/observer.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'widgets/animated_background.dart';

// ─── App Entry Point ──────────────────────────────────────────────────────────
// main() is the first function Flutter calls. It must be async because we call
// WidgetsFlutterBinding.ensureInitialized() before any plugin usage.
void main() async {
  // Ensures Flutter's engine is fully ready before calling platform-specific APIs.
  WidgetsFlutterBinding.ensureInitialized();

  // Customizes the Android status bar — makes it transparent with white icons
  // so it blends with the animated starfield background.
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // ProviderScope is required by Riverpod — it acts as the root dependency
  // injection container that holds all provider state for the entire app.
  // AppObserver is attached here for debugging: it logs every provider change.
  runApp(
    ProviderScope(
      observers: [const AppObserver()],
      child: const ClimaTalkApp(),
    ),
  );
}

// ─── Root Application Widget ──────────────────────────────────────────────────
// ClimaTalkApp is a ConsumerWidget (from Riverpod), meaning it can "watch"
// providers and rebuild automatically when their state changes.
class ClimaTalkApp extends ConsumerWidget {
  const ClimaTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider — rebuilds this widget when the user switches
    // between dark and light mode in the settings screen.
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    // MaterialApp is the top-level widget that configures routes, themes,
    // and global settings for the whole application.
    return MaterialApp(
      title: 'ClimaTalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,      // Used when ThemeMode.light is active
      darkTheme: AppTheme.darkTheme,   // Used when ThemeMode.dark is active
      themeMode: themeMode,            // Dynamically controlled by user preference
      // The builder wraps EVERY route in the animated background widget.
      // This ensures the weather animation is always visible regardless of the screen.
      builder: (context, child) => AnimatedBackground(
        isDark: isDark,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(), // First screen shown on app launch
    );
  }
}
