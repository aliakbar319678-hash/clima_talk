// ─── session_cache_service.dart ───────────────────────────────────────────────
// This service implements a two-layer caching system to minimize redundant
// API calls and improve the app's performance and responsiveness.
//
// Layer 1 — In-Memory Cache (fast, session-only):
//   Stores objects in a Dart Map. Access is near-instant but data is lost
//   when the app closes or is restarted.
//
// Layer 2 — Persistent Cache (disk, survives restarts):
//   Uses SharedPreferences (key-value storage on device disk). Access is
//   slower than memory but data is available after the app is closed/reopened.
//
// Pattern: Write-through caching — when saving to disk, also save to memory.
// This ensures subsequent reads in the same session are ultra-fast.

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


// ─── Data Caching Service ────────────────────────────────────────────────────
// This service implements a high-performance hybrid caching strategy.
// It uses an In-Memory map for millisecond-fast access during a session,
// and SharedPreferences for persistent storage across app restarts.
class SessionCacheService {
  // Singleton Pattern: only ONE instance of this service exists in the entire app.
  // This ensures all providers share the same cache map and don't have duplicate data.
  static final SessionCacheService _instance = SessionCacheService._internal();
  factory SessionCacheService() => _instance;
  SessionCacheService._internal();

  // The in-memory cache — a simple Dart Map that stores any type of value.
  // It is static so it persists for the entire app session.
  static final Map<String, dynamic> _inMemoryCache = {};
  
  // ─── Persistent Storage Operations ──────────────────────────────────────────
  // These methods interact with the device's physical storage.

  // Saves a key-value pair to disk with an automatic timestamp for expiration tracking.
  // The timestamp allows us to check later if the data is still fresh.
  Future<void> savePersistent(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'value': value,
      'timestamp': DateTime.now().toIso8601String(), // Record when data was saved
    };
    await prefs.setString(key, jsonEncode(data));
    _inMemoryCache[key] = value; // Sync to memory for subsequent reads (write-through)
  }

  // Retrieves data from disk. If the data is older than maxAgeMinutes, it's considered
  // stale and will be deleted/ignored. Supports custom JSON parsing via fromJson.
  Future<T?> getPersistent<T>(String key, {int? maxAgeMinutes, T Function(Map<String, dynamic>)? fromJson}) async {
    // Fast Path: return immediately from memory if available (avoids disk I/O).
    if (_inMemoryCache.containsKey(key)) {
      return _inMemoryCache[key] as T?;
    }

    // Slow Path: read from disk if not in memory.
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null; // Key doesn't exist at all

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp'] as String);
      final age = DateTime.now().difference(timestamp).inMinutes;

      // Handle cache expiration — if the data is too old, delete it and return null.
      // The caller will then fetch fresh data from the API.
      if (maxAgeMinutes != null && age > maxAgeMinutes) {
        await prefs.remove(key);
        return null;
      }

      final value = data['value'];
      
      // If a fromJson mapper is provided, use it to reconstruct a typed object
      // (e.g., turn a raw Map into a WeatherModel instance).
      if (fromJson != null && value is Map<String, dynamic>) {
        final result = fromJson(value);
        _inMemoryCache[key] = result; // Write-through to memory
        return result;
      }
      
      _inMemoryCache[key] = value;
      return value as T?;
    } catch (_) {
      return null; // Silently fail on data corruption — just fetch fresh data
    }
  }

  // ─── Session-Only Operations ───────────────────────────────────────────────
  // Methods for high-frequency data that doesn't need to persist across restarts.
  // Used for forecast data which changes often and doesn't need to survive restarts.

  // Stores a value in memory only (not written to disk).
  void store(String key, dynamic value) {
    _inMemoryCache[key] = value;
  }

  // Retrieves a value from memory only. Returns null if not found.
  T? retrieve<T>(String key) {
    return _inMemoryCache[key] as T?;
  }

  // Wipes the entire in-memory cache (useful for logout or data reset).
  void clearCache() {
    _inMemoryCache.clear();
  }

  // ─── Standardized Cache Keys ────────────────────────────────────────────────
  // Centralized key generators prevent naming collisions across the app.
  // All keys follow a prefix pattern so they are easy to identify in storage.

  static String weatherKey(String identifier) => 'p_weather_$identifier';
  static String forecastKey(String identifier) => 'p_forecast_$identifier';
  static String aiKey(String query) => 'ai_${query.hashCode}';
  static const String lastCityKey = 'last_viewed_city';
}
