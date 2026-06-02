// ─── weather_provider.dart ────────────────────────────────────────────────────
// This provider manages the state of the currently displayed weather data.
// It coordinates between the LocationService (GPS) and WeatherService (API)
// to fetch and cache weather for the user's current location or a searched city.
//
// Architecture Pattern:
//   WeatherState    → Immutable snapshot of weather data + loading/error flags
//   WeatherNotifier → Business logic that fetches data and manages caching
//   weatherProvider → Riverpod provider exposed to UI widgets

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/weather_model.dart';
import '../services/weather_service.dart';
import '../services/location_service.dart';
import '../services/session_cache_service.dart';

// ─── WeatherState ─────────────────────────────────────────────────────────────
// Represents all possible states the weather UI can be in:
//   - Initial: No data, not loading, no error (app just started)
//   - Loading: Fetching data, may still have old data for stale-while-revalidate
//   - Success: Data available and ready to display
//   - Error: Something went wrong, show error UI with retry button
class WeatherState {
  final WeatherModel? weather;   // The actual weather data (null until loaded)
  final bool isLoading;          // True while an API request is in progress
  final String? errorMessage;    // Non-null when an error has occurred
  // True = loaded via GPS, false = manual city search
  final bool isLocationBased;    // Used to show different icons/labels in the UI

  const WeatherState({
    this.weather,
    this.isLoading = false,
    this.errorMessage,
    this.isLocationBased = true,
  });

  // Named constructors for convenient state creation — makes code more readable.
  factory WeatherState.initial() => const WeatherState();
  factory WeatherState.loading() => const WeatherState(isLoading: true);
  factory WeatherState.success(WeatherModel weather, {bool isLocationBased = true}) =>
      WeatherState(weather: weather, isLocationBased: isLocationBased);
  factory WeatherState.error(String message) => WeatherState(errorMessage: message);

  // Convenience getters used in the HomeScreen to conditionally render widgets.
  bool get hasData => weather != null;
  bool get hasError => errorMessage != null;
}

// ─── WeatherNotifier ──────────────────────────────────────────────────────────
// The brain of weather data management. Handles caching, GPS, and API calls.
class WeatherNotifier extends Notifier<WeatherState> {
  late final WeatherService _weatherService;
  late final LocationService _locationService;
  late final SessionCacheService _cache;

  @override
  WeatherState build() {
    // Initialize services when the provider is first created.
    _weatherService = WeatherService();
    _locationService = LocationService();
    _cache = SessionCacheService();
    // Hydrate UI immediately from disk — avoids blank loader flash on startup.
    // This loads the last known weather from SharedPreferences before the API call.
    _loadLastKnownWeather();
    return WeatherState.initial();
  }

  // Loads the last viewed city's weather from persistent disk cache on app startup.
  // This gives users instant content while the fresh API request is being made.
  Future<void> _loadLastKnownWeather() async {
    final lastCity = await _cache.getPersistent<String>(SessionCacheService.lastCityKey);
    if (lastCity == null) return;
    final cached = await _cache.getPersistent<WeatherModel>(
      SessionCacheService.weatherKey(lastCity),
      fromJson: WeatherModel.fromJson, // Tells the cache how to reconstruct the object
    );
    if (cached != null) {
      state = WeatherState.success(cached, isLocationBased: false);
    }
  }

  // ─── Fetch by GPS Location ─────────────────────────────────────────────────
  // Called on app start and when the user pulls down to refresh on the home screen.
  Future<void> fetchWeatherByLocation() async {
    // Keep old data visible while loading (stale-while-revalidate UX pattern).
    state = WeatherState(weather: state.weather, isLoading: true);
    try {
      // Get GPS coordinates from the device.
      final position = await _locationService.getCurrentLocation();
      final id = '${position.latitude.toStringAsFixed(2)}_${position.longitude.toStringAsFixed(2)}';
      final cacheKey = SessionCacheService.weatherKey(id);

      // Check if we have fresh cached data (less than 30 minutes old).
      // If yes, skip the API call entirely — saves bandwidth and is faster.
      final cached = await _cache.getPersistent<WeatherModel>(
        cacheKey,
        maxAgeMinutes: 30,
        fromJson: WeatherModel.fromJson,
      );
      if (cached != null) {
        state = WeatherState.success(cached);
        return;
      }

      // No fresh cache — fetch from the API using the GPS coordinates.
      final weather = await _weatherService.getCurrentWeatherByCoords(
        position.latitude,
        position.longitude,
      );
      // Save to persistent cache and remember this as the last viewed location.
      await _cache.savePersistent(cacheKey, weather.toJson());
      await _cache.savePersistent(SessionCacheService.lastCityKey, id);
      state = WeatherState.success(weather);
    } catch (e) {
      // Show error message and let the UI display a retry button.
      state = WeatherState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // ─── Fetch by City Name (Search) ──────────────────────────────────────────
  // Called when the user searches for a city in the app bar search field.
  Future<void> fetchWeatherByCity(String cityName) async {
    if (cityName.trim().isEmpty) {
      state = WeatherState.error('Please enter a city name.');
      return;
    }
    // Keep old data visible while loading.
    state = WeatherState(weather: state.weather, isLoading: true);
    try {
      final cityKey = cityName.toLowerCase().trim();
      final cacheKey = SessionCacheService.weatherKey(cityKey);

      // Check cache first — avoids redundant API calls for recently searched cities.
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

      // Fetch from API and cache the result for future requests.
      final weather = await _weatherService.getCurrentWeatherByCity(cityKey);
      await _cache.savePersistent(cacheKey, weather.toJson());
      await _cache.savePersistent(SessionCacheService.lastCityKey, cityKey);
      state = WeatherState.success(weather, isLocationBased: false);
    } catch (e) {
      state = WeatherState.error(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Resets state to initial — used to clear errors and go back to empty UI.
  void clearError() => state = WeatherState.initial();
}

// ─── Provider Declaration ─────────────────────────────────────────────────────
// This line creates the actual Riverpod provider. Widgets access it via:
//   final weatherState = ref.watch(weatherProvider);
final weatherProvider = NotifierProvider<WeatherNotifier, WeatherState>(WeatherNotifier.new);
