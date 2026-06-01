import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ProviderObserver tracks provider state changes — debug builds only.
base class AppObserver extends ProviderObserver {
  const AppObserver();

  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (kDebugMode) {
      debugPrint(
        '✅ [Riverpod] Added: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }

  @override
  void didUpdateProvider(
    ProviderObserverContext context,
    Object? previousValue,
    Object? newValue,
  ) {
    if (kDebugMode) {
      debugPrint(
        '🔄 [Riverpod] Updated: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }

  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (kDebugMode) {
      debugPrint(
        '🗑️ [Riverpod] Disposed: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }
}
