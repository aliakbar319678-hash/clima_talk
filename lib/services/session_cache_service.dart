import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';


// ─── Data Caching Service ────────────────────────────────────────────────────
// This service implements a high-performance hybrid caching strategy.
// It uses an In-Memory map for millisecond-fast access during a session,
// and SharedPreferences for persistent storage across app restarts.
class SessionCacheService {
  // Singleton — all providers share one instance and one backing map.
  static final SessionCacheService _instance = SessionCacheService._internal();
  factory SessionCacheService() => _instance;
  SessionCacheService._internal();

  // Temporary storage for the current app session
  static final Map<String, dynamic> _inMemoryCache = {};
  
  // ─── Persistent Storage Operations ──────────────────────────────────────────
  // These methods interact with the device's physical storage.

  // Saves a key-value pair to disk with an automatic timestamp for expiration tracking.
  Future<void> savePersistent(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'value': value,
      'timestamp': DateTime.now().toIso8601String(),
    };
    await prefs.setString(key, jsonEncode(data));
    _inMemoryCache[key] = value; // Sync to memory for subsequent reads
  }

  // Retrieves data from disk. If the data is older than maxAgeMinutes, it's considered
  // stale and will be deleted/ignored. Supports custom JSON parsing via fromJson.
  Future<T?> getPersistent<T>(String key, {int? maxAgeMinutes, T Function(Map<String, dynamic>)? fromJson}) async {
    // Return from memory if available (Fast Path)
    if (_inMemoryCache.containsKey(key)) {
      return _inMemoryCache[key] as T?;
    }

    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(key);
    if (jsonStr == null) return null;

    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final timestamp = DateTime.parse(data['timestamp'] as String);
      final age = DateTime.now().difference(timestamp).inMinutes;

      // Handle cache expiration
      if (maxAgeMinutes != null && age > maxAgeMinutes) {
        await prefs.remove(key);
        return null;
      }

      final value = data['value'];
      
      // If a mapper is provided, use it to reconstruct the object (e.g., WeatherModel)
      if (fromJson != null && value is Map<String, dynamic>) {
        final result = fromJson(value);
        _inMemoryCache[key] = result;
        return result;
      }
      
      _inMemoryCache[key] = value;
      return value as T?;
    } catch (_) {
      return null; // Silently fail on corruption
    }
  }

  // ─── Session-Only Operations ───────────────────────────────────────────────
  // Methods for high-frequency data that doesn't need to persist across restarts.

  void store(String key, dynamic value) {
    _inMemoryCache[key] = value;
  }

  T? retrieve<T>(String key) {
    return _inMemoryCache[key] as T?;
  }

  void clearCache() {
    _inMemoryCache.clear();
  }

  // ─── Standardized Cache Keys ────────────────────────────────────────────────
  // Centralized key generators to prevent naming collisions across the app.

  static String weatherKey(String identifier) => 'p_weather_$identifier';
  static String forecastKey(String identifier) => 'p_forecast_$identifier';
  static String aiKey(String query) => 'ai_${query.hashCode}';
  static const String lastCityKey = 'last_viewed_city';
}

