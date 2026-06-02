// ─── forecast_provider.dart ───────────────────────────────────────────────────
// Manages the state for the 7-day weather forecast feature.
// Works similarly to WeatherProvider but serves the ForecastScreen.
// Uses in-memory session caching (not disk) since forecast data is needed
// for the current session only and refreshes often.
//
// ForecastProvider manages the 7-day forecast state.
// Corresponds to the Forecast Processing subsystem from SDD Section 3.2.2.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/forecast_model.dart';
import '../services/weather_service.dart';
import '../services/session_cache_service.dart';

// ─── ForecastState ────────────────────────────────────────────────────────────
// Holds all possible states for the forecast screen.
/// Holds the forecast async state.
class ForecastState {
  final ForecastResponse? forecast; // 7-day forecast data (null until loaded)
  final bool isLoading;             // True while API request is in progress
  final String? errorMessage;       // Non-null when an error occurred

  const ForecastState({
    this.forecast,
    this.isLoading = false,
    this.errorMessage,
  });

  // Named constructors for clean state transitions.
  factory ForecastState.initial() => const ForecastState();
  factory ForecastState.success(ForecastResponse forecast) =>
      ForecastState(forecast: forecast);
  factory ForecastState.error(String message) =>
      ForecastState(errorMessage: message);

  // Convenience getters for conditional UI rendering.
  bool get hasData => forecast != null;
  bool get hasError => errorMessage != null;
}

// ─── ForecastNotifier ─────────────────────────────────────────────────────────
// Handles fetching and caching of forecast data. The forecast is triggered
// automatically by WeatherProvider whenever weather data changes city.
/// Notifier for forecast data management.
class ForecastNotifier extends Notifier<ForecastState> {
  late final WeatherService _weatherService;
  late final SessionCacheService _cache;

  @override
  ForecastState build() {
    // Initialize services.
    _weatherService = WeatherService();
    _cache = SessionCacheService();
    return ForecastState.initial();
  }

  /// Fetches 7-day forecast by GPS coordinates.
  /// Called automatically by HomeScreen when weather location changes.
  Future<void> fetchForecastByCoords(double lat, double lon) async {
    // Preserve stale data during reload — prevents blank-screen flash.
    // The user still sees old data while the new data is being fetched.
    state = ForecastState(forecast: state.forecast, isLoading: true);
    try {
      // Build a unique cache key from coordinates (rounded to 2 decimal places).
      final cacheKey = SessionCacheService.forecastKey(
        '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}',
      );

      // Check in-memory session cache first — instant access if already fetched.
      final cached = _cache.retrieve<ForecastResponse>(cacheKey);
      if (cached != null) {
        state = ForecastState.success(cached);
        return;
      }

      // Not cached — make the API call and then store the result in memory.
      final forecast = await _weatherService.getForecastByCoords(lat, lon);
      _cache.store(cacheKey, forecast);
      state = ForecastState.success(forecast);
    } catch (e) {
      state = ForecastState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Fetches 7-day forecast by city name.
  /// Called when the user searches for a specific city.
  Future<void> fetchForecastByCity(String cityName) async {
    if (cityName.trim().isEmpty) return;

    // Preserve stale data during reload — prevents blank-screen flash.
    state = ForecastState(forecast: state.forecast, isLoading: true);
    try {
      // Normalize city name to lowercase for consistent cache key matching.
      final cacheKey = SessionCacheService.forecastKey(cityName.toLowerCase());

      final cached = _cache.retrieve<ForecastResponse>(cacheKey);
      if (cached != null) {
        state = ForecastState.success(cached);
        return;
      }

      final forecast = await _weatherService.getForecastByCity(cityName.trim());
      _cache.store(cacheKey, forecast);
      state = ForecastState.success(forecast);
    } catch (e) {
      state = ForecastState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }
}

// ─── Provider Declaration ─────────────────────────────────────────────────────
/// Provider for 7-day forecast state.
final forecastProvider = NotifierProvider<ForecastNotifier, ForecastState>(ForecastNotifier.new);
