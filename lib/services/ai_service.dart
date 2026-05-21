import 'package:google_generative_ai/google_generative_ai.dart';

import '../core/app_constants.dart';
import '../models/weather_model.dart';

class AIService {
  // Lazy singletons — created once per AIService instance and reused across calls.
  late final GenerativeModel _model = GenerativeModel(
    model: AppConstants.aiModel,
    apiKey: AppConstants.aiApiKey,
  );

  Future<String> getWeatherGuidance({
    required String userQuery,
    WeatherModel? currentWeather,
  }) async {
    final systemPrompt = _buildSystemPrompt(currentWeather);
    return _callGemini(systemPrompt, userQuery);
  }

  Future<String> _callGemini(String systemPrompt, String userQuery) async {
    try {
      final response = await _model
          .generateContent(
            [Content.text(userQuery)],
            generationConfig: GenerationConfig(
              maxOutputTokens: 300,
              temperature: 0.7,
            ),
            // Pass system instruction per-request so it reflects current weather context.
            safetySettings: [],
          )
          .timeout(
            Duration(seconds: AppConstants.apiTimeoutSeconds),
            onTimeout: () =>
                throw Exception('AI service timed out. Please try again.'),
          );

      final text = response.text;
      if (text != null && text.isNotEmpty) return text.trim();
      return 'No response received from AI.';
    } catch (e) {
      final err = e.toString().toLowerCase();

      if (err.contains('quota') || err.contains('rate limit') || err.contains('429')) {
        return 'ClimaTalk is a bit busy right now (Quota Reached). Please wait a minute and try again! 😊';
      }
      // Fallback: prepend system context inline for models that reject system instructions.
      if (err.contains('systeminstruction') || err.contains('400')) {
        return _callGeminiFallback(systemPrompt, userQuery);
      }
      throw Exception('AI connection error: ${e.toString()}');
    }
  }

  Future<String> _callGeminiFallback(String systemPrompt, String userQuery) async {
    final response = await _model.generateContent(
      [Content.text('$systemPrompt\n\nUser question: $userQuery')],
      generationConfig: GenerationConfig(maxOutputTokens: 300, temperature: 0.7),
    );
    return response.text?.trim() ?? 'No response received.';
  }

  String _buildSystemPrompt(WeatherModel? weather) {
    const base =
        'You are ClimaTalk, a helpful AI weather companion. '
        'You provide friendly, practical weather advice and can answer weather-related questions about any city worldwide. '
        'Keep responses concise (2-4 sentences), friendly, and actionable.';

    if (weather == null) return base;

    return '$base\n\n'
        'The user\'s currently selected location:\n'
        '- Location: ${weather.cityName}, ${weather.countryCode}\n'
        '- Temperature: ${weather.temperature.round()}°C (feels like ${weather.feelsLike.round()}°C)\n'
        '- Condition: ${weather.condition} — ${weather.description}\n'
        '- Humidity: ${weather.humidity}%\n'
        '- Wind: ${weather.windSpeed} m/s\n\n'
        'Use this data for location-specific advice. For other locations, use your general knowledge.';
  }
}
