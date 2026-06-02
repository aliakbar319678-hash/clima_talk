import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/app_constants.dart';
import '../models/weather_model.dart';
import 'dart:developer' as dev;

/// AIService uses Pollinations Text API for intelligent weather guidance.
/// Implements robust error handling and context-aware system prompts.
class AIService {
  AIService();

  /// Sends the full conversation history to Pollinations AI and returns the reply.
  /// Handles timeouts, connectivity check, and specific error codes.
  Future<String> getWeatherGuidance({
    required String userQuery,
    required List<Map<String, String>> history,
    WeatherModel? currentWeather,
  }) async {
    // 1. Check Internet Connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw const SocketException(AppConstants.errorNoInternet);
    }

    final systemPrompt = _buildSystemPrompt(currentWeather);

    // 2. Prepare the messages array for the API
    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    for (var msg in history) {
      messages.add({
        'role': msg['role'] == 'user' ? 'user' : 'assistant',
        'content': msg['content'] ?? '',
      });
    }

    messages.add({'role': 'user', 'content': userQuery});

    try {
      dev.log('Sending message to AI: $userQuery', name: 'AIService');
      
      final response = await http.post(
        Uri.parse('https://text.pollinations.ai/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': messages}),
      ).timeout(
        const Duration(seconds: AppConstants.apiTimeoutSeconds),
      );

      if (response.statusCode == 200) {
        final text = response.body;
        if (text.trim().isNotEmpty) {
          dev.log('Received response from AI', name: 'AIService');
          return text.trim();
        }
      }
      
      throw Exception('Empty or invalid response from AI.');
    } on SocketException {
      throw Exception(AppConstants.errorNoInternet);
    } on TimeoutException {
      throw Exception(AppConstants.errorTimeout);
    } catch (e) {
      dev.log('Unexpected AI Service Error: $e', name: 'AIService', error: e);
      throw Exception(AppConstants.errorGeneric);
    }
  }

  String _buildSystemPrompt(WeatherModel? weather) {
    const base = 'You are ClimaTalk, a professional and friendly AI weather companion. '
        'Your goal is to provide insightful, accurate, and practical weather advice. '
        'Always response with complete sentences. Be concise but helpful. '
        'If the user asks something unrelated to weather, politely pivot back to weather '
        'or offer general assistance while maintaining your persona.';

    if (weather == null) return base;

    return '$base\n\n'
        "CONTEXT: Current location weather:\n"
        '- City: ${weather.cityName}\n'
        '- Temp: ${weather.temperature.round()}°C (Feels like: ${weather.feelsLike.round()}°C)\n'
        '- Conditions: ${weather.condition} (${weather.description})\n'
        '- Humidity: ${weather.humidity}%\n'
        '- Wind: ${weather.windSpeed} m/s\n\n'
        'Use this data to personalize your advice. If the user asks about multiple locations, '
        'prioritize the current one unless they specify otherwise.';
  }
}

