import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'providers/observer.dart';
import 'providers/theme_provider.dart';
import 'screens/splash_screen.dart';
import 'widgets/animated_background.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(
    ProviderScope(
      observers: [const AppObserver()],
      child: const ClimaTalkApp(),
    ),
  );
}

class ClimaTalkApp extends ConsumerWidget {
  const ClimaTalkApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = themeMode == ThemeMode.dark;

    return MaterialApp(
      title: 'ClimaTalk',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      // Wraps every route in the animated starfield/weather background.
      builder: (context, child) => AnimatedBackground(
        isDark: isDark,
        child: child ?? const SizedBox.shrink(),
      ),
      home: const SplashScreen(),
    );
  }
}
