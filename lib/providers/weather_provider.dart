import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/session_cache_service.dart';

class WeatherState {
  final WeatherModel? weather;
  final bool isLoading;
  final String? errorMessage;
  // True = loaded via GPS, false = manual city search
  final bool isLocationBased;

  const WeatherState({
    this.weather,
    this.isLoading = false,
    this.errorMessage,
    this.isLocationBased = true,
  });

  factory WeatherState.initial() => const WeatherState();
  factory WeatherState.loading() => const WeatherState(isLoading: true);
  factory WeatherState.success(WeatherModel weather, {bool isLocationBased = true}) =>
      WeatherState(weather: weather, isLocationBased: isLocationBased);
  factory WeatherState.error(String message) => WeatherState(errorMessage: message);

  bool get hasData => weather != null;
  bool get hasError => errorMessage != null;
}

class WeatherNotifier extends Notifier<WeatherState> {
  late final WeatherService _weatherService;
  late final LocationService _locationService;
  late final SessionCacheService _cache;

  @override
  WeatherState build() {
    _weatherService = WeatherService();
    _locationService = LocationService();
    _cache = SessionCacheService();
    // Hydrate UI immediately from disk — avoids blank loader flash on startup.
    _loadLastKnownWeather();
    return WeatherState.initial();
  }

  Future<void> _loadLastKnownWeather() async {
    final lastCity = await _cache.getPersistent<String>(SessionCacheService.lastCityKey);
    if (lastCity == null) return;
    final cached = await _cache.getPersistent<WeatherModel>(
      SessionCacheService.weatherKey(lastCity),
      fromJson: WeatherModel.fromJson,
    );
    if (cached != null) {
      state = WeatherState.success(cached, isLocationBased: false);
    }
  }

  Future<void> fetchWeatherByLocation() async {
    state = WeatherState(weather: state.weather, isLoading: true);
    try {
      final position = await _locationService.getCurrentLocation();
      final id = '${position.latitude.toStringAsFixed(2)}_${position.longitude.toStringAsFixed(2)}';
      final cacheKey = SessionCacheService.weatherKey(id);

      final cached = await _cache.getPersistent<WeatherModel>(
        cacheKey,
        maxAgeMinutes: 30,
        fromJson: WeatherModel.fromJson,
      );
      if (cached != null) {
        state = WeatherState.success(cached);
        return;
      }

      final weather = await _weatherService.getCurrentWeatherByCoords(
        position.latitude,
        position.longitude,
      );
      await _cache.savePersistent(cacheKey, weather.toJson());
      await _cache.savePersistent(SessionCacheService.lastCityKey, id);
      state = WeatherState.success(weather);
    } catch (e) {
      state = WeatherState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> fetchWeatherByCity(String cityName) async {
    if (cityName.trim().isEmpty) {
      state = WeatherState.error('Please enter a city name.');
      return;
    }
    state = WeatherState(weather: state.weather, isLoading: true);
    try {
      final cityKey = cityName.toLowerCase().trim();
      final cacheKey = SessionCacheService.weatherKey(cityKey);

      final cached = await _cache.getPersistent<WeatherModel>(
        cacheKey,
        maxAgeMinutes: 30,
        fromJson: WeatherModel.fromJson,
      );
      // Return early on cache hit — no redundant network call.
      if (cached != null) {
        state = WeatherState.success(cached, isLocationBased: false);
        return;
      }

      final weather = await _weatherService.getCurrentWeatherByCity(cityKey);
      await _cache.savePersistent(cacheKey, weather.toJson());
      await _cache.savePersistent(SessionCacheService.lastCityKey, cityKey);
      state = WeatherState.success(weather, isLocationBased: false);
    } catch (e) {
      state = WeatherState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  void clearError() => state = WeatherState.initial();
}

final weatherProvider = NotifierProvider<WeatherNotifier, WeatherState>(WeatherNotifier.new);
