// ForecastProvider manages the 7-day forecast state.
// Corresponds to the Forecast Processing subsystem from SDD Section 3.2.2.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/forecast_model.dart';
import '../services/weather_service.dart';
import '../services/session_cache_service.dart';

/// Holds the forecast async state.
class ForecastState {
  final ForecastResponse? forecast;
  final bool isLoading;
  final String? errorMessage;

  const ForecastState({
    this.forecast,
    this.isLoading = false,
    this.errorMessage,
  });

  factory ForecastState.initial() => const ForecastState();
  factory ForecastState.success(ForecastResponse forecast) =>
      ForecastState(forecast: forecast);
  factory ForecastState.error(String message) =>
      ForecastState(errorMessage: message);

  bool get hasData => forecast != null;
  bool get hasError => errorMessage != null;
}

/// Notifier for forecast data management.
class ForecastNotifier extends Notifier<ForecastState> {
  late final WeatherService _weatherService;
  late final SessionCacheService _cache;

  @override
  ForecastState build() {
    _weatherService = WeatherService();
    _cache = SessionCacheService();
    return ForecastState.initial();
  }

  /// Fetches 7-day forecast by GPS coordinates.
  Future<void> fetchForecastByCoords(double lat, double lon) async {
    // Preserve stale data during reload — prevents blank-screen flash.
    state = ForecastState(forecast: state.forecast, isLoading: true);
    try {
      final cacheKey = SessionCacheService.forecastKey(
        '${lat.toStringAsFixed(2)}_${lon.toStringAsFixed(2)}',
      );

      final cached = _cache.retrieve<ForecastResponse>(cacheKey);
      if (cached != null) {
        state = ForecastState.success(cached);
        return;
      }

      final forecast = await _weatherService.getForecastByCoords(lat, lon);
      _cache.store(cacheKey, forecast);
      state = ForecastState.success(forecast);
    } catch (e) {
      state = ForecastState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Fetches 7-day forecast by city name.
  Future<void> fetchForecastByCity(String cityName) async {
    if (cityName.trim().isEmpty) return;

    // Preserve stale data during reload — prevents blank-screen flash.
    state = ForecastState(forecast: state.forecast, isLoading: true);
    try {
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

/// Provider for 7-day forecast state.
final forecastProvider = NotifierProvider<ForecastNotifier, ForecastState>(ForecastNotifier.new);
