// ─── ai_service.dart ──────────────────────────────────────────────────────────
// This service is the bridge between the ClimaTalk app and the AI chatbot API.
// It was originally built for Google Gemini but has been migrated to use
// Pollinations AI (https://text.pollinations.ai/) which is completely FREE
// and requires NO API key — perfect for demos and presentations.
//
// How it works:
//  1. User types a message in the ChatScreen.
//  2. ChatProvider calls AIService.getWeatherGuidance().
//  3. This service checks internet, builds the message list, sends an HTTP POST.
//  4. The API responds with a plain text string which is returned to the UI.

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
  ///
  /// Parameters:
  ///   - userQuery: The latest message the user typed.
  ///   - history: The full list of previous messages (for conversational context).
  ///   - currentWeather: Optional live weather data to personalize responses.
  Future<String> getWeatherGuidance({
    required String userQuery,
    required List<Map<String, String>> history,
    WeatherModel? currentWeather,
  }) async {
    // 1. Check Internet Connectivity
    // Before making any network call, verify the user has internet.
    // ConnectivityResult.none means no WiFi and no mobile data.
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      throw const SocketException(AppConstants.errorNoInternet);
    }

    // 2. Build the system prompt that defines the AI's personality and context.
    // If weather data is available, it's injected here so the AI can reference it.
    final systemPrompt = _buildSystemPrompt(currentWeather);

    // 3. Prepare the messages array for the API
    // The Pollinations API follows the OpenAI message format:
    // - 'system' role: Defines the AI's instructions and persona.
    // - 'user' role: Messages from the human user.
    // - 'assistant' role: Previous AI responses (for conversational memory).
    final List<Map<String, String>> messages = [
      {'role': 'system', 'content': systemPrompt},
    ];

    // Convert our internal history format into the API's expected format.
    for (var msg in history) {
      messages.add({
        'role': msg['role'] == 'user' ? 'user' : 'assistant',
        'content': msg['content'] ?? '',
      });
    }

    // Append the current user query as the final message in the conversation.
    messages.add({'role': 'user', 'content': userQuery});

    try {
      dev.log('Sending message to AI: $userQuery', name: 'AIService');
      
      // 4. Make the HTTP POST request to the Pollinations AI text endpoint.
      // The request body is JSON-encoded, and we set the content-type header accordingly.
      // .timeout() ensures the app doesn't hang forever if the server is slow.
      final response = await http.post(
        Uri.parse('https://text.pollinations.ai/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'messages': messages}),
      ).timeout(
        const Duration(seconds: AppConstants.apiTimeoutSeconds),
      );

      // 5. Process the response.
      // HTTP 200 means success. The body IS the AI's plain text reply.
      if (response.statusCode == 200) {
        final text = response.body;
        if (text.trim().isNotEmpty) {
          dev.log('Received response from AI', name: 'AIService');
          return text.trim();
        }
      }
      
      throw Exception('Empty or invalid response from AI.');
    } on SocketException {
      // Thrown if the network connection drops after the initial check.
      throw Exception(AppConstants.errorNoInternet);
    } on TimeoutException {
      // Thrown by .timeout() if the server takes longer than apiTimeoutSeconds.
      throw Exception(AppConstants.errorTimeout);
    } catch (e) {
      // Catch-all for any unexpected errors (server errors, parsing issues, etc.)
      dev.log('Unexpected AI Service Error: $e', name: 'AIService', error: e);
      throw Exception(AppConstants.errorGeneric);
    }
  }

  // ─── System Prompt Builder ─────────────────────────────────────────────────
  // This method constructs the "system" message that shapes the AI's behavior.
  // A system prompt tells the AI who it is, what it should do, and what context
  // it has available. It's the equivalent of writing job instructions for the AI.
  String _buildSystemPrompt(WeatherModel? weather) {
    // Base personality: defines the AI as a weather-focused assistant.
    const base = 'You are ClimaTalk, a professional and friendly AI weather companion. '
        'Your goal is to provide insightful, accurate, and practical weather advice. '
        'Always response with complete sentences. Be concise but helpful. '
        'If the user asks something unrelated to weather, politely pivot back to weather '
        'or offer general assistance while maintaining your persona.';

    // If no weather data is available (e.g., user hasn't given location),
    // just return the base personality without any context.
    if (weather == null) return base;

    // If live weather data is available, inject it into the prompt so the AI
    // can say things like "Since it's 34°C in Lahore, I recommend staying hydrated."
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
