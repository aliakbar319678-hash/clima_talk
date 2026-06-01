import 'dart:io';
import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../core/app_constants.dart';
import '../models/weather_model.dart';
import 'dart:developer' as dev;

/// AIService uses Google Gemini API for intelligent weather guidance.
/// Implements robust error handling and context-aware system prompts.
class AIService {
  AIService();

  /// Sends the full conversation history to Gemini and returns the reply.
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

    // 2. Validate API Key
    if (AppConstants.geminiApiKey == 'REPLACE_WITH_YOUR_GEMINI_API_KEY' ||
        AppConstants.geminiApiKey.isEmpty) {
      throw Exception(AppConstants.errorNoApiKey);
    }

    final systemPrompt = _buildSystemPrompt(currentWeather);

    // 3. Convert history to Gemini Content format
    final chatHistory = history.map((msg) {
      final role = msg['role'] == 'user' ? 'user' : 'model';
      return Content(role, [TextPart(msg['content'] ?? '')]);
    }).toList();

    // 4. Initialize Model
    final model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: AppConstants.geminiApiKey,
      systemInstruction: Content.system(systemPrompt),
    );

    final chat = model.startChat(history: chatHistory);

    try {
      dev.log('Sending message to Gemini: $userQuery', name: 'AIService');
      
      final response = await chat.sendMessage(Content.text(userQuery)).timeout(
            const Duration(seconds: AppConstants.apiTimeoutSeconds),
          );

      final text = response.text;
      if (text != null && text.trim().isNotEmpty) {
        dev.log('Received response from Gemini', name: 'AIService');
        return text.trim();
      }
      
      throw Exception('Empty response from AI.');
    } on SocketException {
      throw Exception(AppConstants.errorNoInternet);
    } on TimeoutException {
      throw Exception(AppConstants.errorTimeout);
    } on GenerativeAIException catch (e) {
      dev.log('Gemini AI Exception: $e', name: 'AIService', error: e);
      if (e.message.contains('429') || e.message.contains('quota')) {
        throw Exception(AppConstants.errorQuotaExceeded);
      } else if (e.message.contains('401') || e.message.contains('API_KEY_INVALID')) {
        throw Exception(AppConstants.errorNoApiKey);
      }
      throw Exception('${AppConstants.errorGeneric} (${e.message})');
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

