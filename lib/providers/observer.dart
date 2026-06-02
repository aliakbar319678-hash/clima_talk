// ─── observer.dart ────────────────────────────────────────────────────────────
// The AppObserver is a Riverpod ProviderObserver — a debugging tool that
// automatically logs every provider lifecycle event to the console.
//
// What it logs:
//   ✅ Added   — When a provider is first created (someone called ref.watch/read)
//   🔄 Updated — When a provider's state changes
//   🗑️ Disposed — When a provider is destroyed (no longer being watched)
//
// IMPORTANT: All logging is guarded by kDebugMode — these logs ONLY appear
// during development/testing and are completely removed in release/production builds.
// This means zero performance cost in the app store version.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ProviderObserver tracks provider state changes — debug builds only.
base class AppObserver extends ProviderObserver {
  const AppObserver();

  // Called when a new provider is initialized and added to the container.
  @override
  void didAddProvider(ProviderObserverContext context, Object? value) {
    if (kDebugMode) {
      debugPrint(
        '✅ [Riverpod] Added: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }

  // Called every time a provider's state value changes.
  // previousValue and newValue let you compare before/after if needed.
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

  // Called when a provider is no longer watched by any widget and is cleaned up.
  @override
  void didDisposeProvider(ProviderObserverContext context) {
    if (kDebugMode) {
      debugPrint(
        '🗑️ [Riverpod] Disposed: ${context.provider.name ?? context.provider.runtimeType}',
      );
    }
  }
}
