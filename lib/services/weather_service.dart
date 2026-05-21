// WeatherService handles all OpenWeatherMap API communication.
// Implements the WeatherManager class from SRS Section 3.4.2.
// Per SDD Section 5.3, all API calls use HTTPS with error handling.

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../core/app_constants.dart';
import '../models/weather_model.dart';
import '../models/forecast_model.dart';
import '../models/weather_alert_model.dart';

class WeatherService {
  // HTTP client reused across requests for connection pooling efficiency
  final http.Client _client;

  WeatherService({http.Client? client}) : _client = client ?? http.Client();

  // ─── Current Weather ──────────────────────────────────────────────────────

  /// Fetches current weather by GPS coordinates.
  /// Throws exception on network failure or invalid API response.
  Future<WeatherModel> getCurrentWeatherByCoords(double lat, double lon) async {
    final uri = Uri.parse(
      '${AppConstants.weatherBaseUrl}/weather'
      '?lat=$lat&lon=$lon'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric',
    );

    return _executeWeatherRequest(uri, WeatherModel.fromJson);
  }

  /// Fetches current weather by city name string.
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
  Future<ForecastResponse> getForecastByCoords(double lat, double lon) async {
    final uri = Uri.parse(
      '${AppConstants.weatherBaseUrl}/forecast'
      '?lat=$lat&lon=$lon'
      '&appid=${AppConstants.weatherApiKey}'
      '&units=metric'
      '&cnt=40', // 40 entries covers ~5-7 days of 3-hour intervals
    );

    final response = await _makeRequest(uri);
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

  // ─── Weather Alerts ───────────────────────────────────────────────────────

  Future<List<WeatherAlertModel>> getWeatherAlerts(
    double lat,
    double lon,
  ) async {
    try {
      final weather = await getCurrentWeatherByCoords(lat, lon);
      List<WeatherAlertModel> alerts = [];
      
      final conditionLower = weather.condition.toLowerCase();
      if (conditionLower.contains('thunderstorm')) {
        alerts.add(WeatherAlertModel(
          event: 'Severe Thunderstorm',
          senderName: 'ClimaTalk Alert System',
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(hours: 3)),
          description: 'Severe thunderstorms detected in your area. Expect heavy rain and strong winds. Please stay indoors.',
          tags: ['Thunderstorm', 'Severe'],
        ));
      } else if (conditionLower.contains('rain') && weather.windSpeed > 10) {
        alerts.add(WeatherAlertModel(
          event: 'Storm Warning',
          senderName: 'ClimaTalk Alert System',
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(hours: 4)),
          description: 'Strong winds and rain detected. Secure loose objects and avoid unnecessary travel.',
          tags: ['Rain', 'Wind'],
        ));
      } else if (weather.temperature >= 35) {
        alerts.add(WeatherAlertModel(
          event: 'Heat Advisory',
          senderName: 'ClimaTalk Alert System',
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(hours: 6)),
          description: 'Temperatures are very high. Stay hydrated and avoid prolonged exposure to the sun.',
          tags: ['Heat', 'Advisory'],
        ));
      } else if (weather.temperature <= 0) {
        alerts.add(WeatherAlertModel(
          event: 'Freezing Temperature Warning',
          senderName: 'ClimaTalk Alert System',
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(hours: 6)),
          description: 'Temperatures are at or below freezing. Risk of ice and frost. Keep warm.',
          tags: ['Cold', 'Freezing'],
        ));
      }

      // If no extreme conditions, provide a general advisory so the screen works
      if (alerts.isEmpty) {
        alerts.add(WeatherAlertModel(
          event: 'General Weather Advisory',
          senderName: 'ClimaTalk Service',
          start: DateTime.now(),
          end: DateTime.now().add(const Duration(hours: 12)),
          description: 'Current weather condition is ${weather.condition} with ${weather.temperature.round()}°C. Please remain aware of your surroundings as conditions can change.',
          tags: ['General', 'Advisory'],
        ));
      }

      return alerts;
    } catch (_) {
      return [];
    }
  }

  // ─── Private Helpers ──────────────────────────────────────────────────────

  /// Generic request executor that parses JSON and applies a model factory.
  Future<T> _executeWeatherRequest<T>(
    Uri uri,
    T Function(Map<String, dynamic>) factory,
  ) async {
    final json = await _makeRequest(uri);
    return factory(json);
  }

  /// Makes an HTTP GET request with timeout and error handling.
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

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Invalid API key. Please check configuration.');
      } else if (response.statusCode == 404) {
        throw Exception('City not found. Please enter a valid city name.');
      } else {
        throw Exception(
          'Weather data unavailable (${response.statusCode}). Try again later.',
        );
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
