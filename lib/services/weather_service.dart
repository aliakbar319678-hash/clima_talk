// ─── weather_service.dart ─────────────────────────────────────────────────────
// This service handles ALL communication with the OpenWeatherMap REST API.
// It is a pure "data layer" class — it has no knowledge of Flutter UI.
// It only fetches raw data, parses JSON, and returns typed Dart model objects.
//
// API Used: OpenWeatherMap (https://openweathermap.org/api)
// Two endpoints are used:
//   - /weather  → Current weather conditions for a location
//   - /forecast → 5-day forecast in 3-hour intervals (40 data points)
//
// WeatherService handles all OpenWeatherMap API communication.
// Implements the WeatherManager class from SRS Section 3.4.2.
// Per SDD Section 5.3, all API calls use HTTPS with error handling.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/app_constants.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';


class WeatherService {
  // HTTP client reused across requests for connection pooling efficiency.
  // Injecting the client also makes this class testable (we can pass a mock client in tests).
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  // ─── Current Weather ──────────────────────────────────────────────────────

  /// Fetches current weather by GPS coordinates.
  /// Throws exception on network failure or invalid API response.
  /// 'units=metric' tells the API to return temperatures in Celsius.
  Future<WeatherModel> getCurrentWeatherByCoords(double lat, double lon) async {
    final uri = Uri.parse(
      '${AppConstants.weatherBaseUrl}/weather'
      '?lat=$lat&lon=$lon'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric',
    );

    // Delegates the actual HTTP call to the shared _executeWeatherRequest helper.
    return _executeWeatherRequest(uri, WeatherModel.fromJson);
  }

  /// Fetches current weather by city name string.
  /// The city name is URL-encoded to handle spaces and special characters safely.
  Future<WeatherModel> getCurrentWeatherByCity(String cityName) async {
    final uri = Uri.parse(
      '${AppConstants.weatherBaseUrl}/weather'
      '?q=${Uri.encodeComponent(cityName)}'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric',
    );

    return _executeWeatherRequest(uri, WeatherModel.fromJson);
  }

  // ─── 7-Day Forecast ───────────────────────────────────────────────────────

  /// Fetches 5-day/3-hour forecast by GPS coordinates, then groups into daily.
  /// cnt=40 requests 40 time slots (5 days × 8 slots per day = 40 entries).
  Future<ForecastResponse> getForecastByCoords(double lat, double lon) async {
    final uri = Uri.parse(
      '${AppConstants.weatherBaseUrl}/forecast'
      '?lat=$lat&lon=$lon'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric'
      '&cnt=40', // 40 entries covers ~5-7 days of 3-hour intervals
    );

    final response = await _makeRequest(uri);
    // ForecastResponse.fromJson handles grouping 3-hour slots into daily summaries.
    return ForecastResponse.fromJson(response);
  }

  /// Fetches forecast by city name.
  Future<ForecastResponse> getForecastByCity(String cityName) async {
    final uri = Uri.parse(
      '${AppConstants.weatherBaseUrl}/forecast'
      '?q=${Uri.encodeComponent(cityName)}'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric'
      '&cnt=40',
    );

    final response = await _makeRequest(uri);
    return ForecastResponse.fromJson(response);
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  /// Generic request executor that parses JSON and applies a model factory.
  /// The factory parameter makes this reusable for both WeatherModel and ForecastResponse.
  Future<T> _executeWeatherRequest<T>(
    Uri uri,
    T Function(Map<String, dynamic>) factory,
  ) async {
    final json = await _makeRequest(uri);
    return factory(json);
  }

  /// Makes an HTTP GET request with timeout and structured error handling.
  /// Translates HTTP status codes into user-friendly exception messages.
  Future<Map<String, dynamic>> _makeRequest(Uri uri) async {
    try {
      final response = await _client
          .get(uri)
          .timeout(
            Duration(seconds: AppConstants.apiTimeoutSeconds),
            onTimeout: () => throw Exception(
              'Request timed out. Please check your connection.',
            ),
          );

      // 200: Success — parse and return the JSON body.
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        // 401: Unauthorized — the API key is wrong or missing.
        throw Exception('Invalid API key. Please check configuration.');
      } else if (response.statusCode == 404) {
        // 404: Not Found — the city name doesn't exist in OpenWeatherMap's database.
        throw Exception('City not found. Please enter a valid city name.');
      } else {
        // Any other status code indicates a server-side or unexpected error.
        throw Exception(
          'Weather data unavailable (${response.statusCode}). Try again later.',
        );
      }
    } on Exception {
      rethrow; // Re-throw our own typed exceptions so callers handle them properly.
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
