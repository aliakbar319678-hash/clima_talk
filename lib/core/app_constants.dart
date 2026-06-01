// ─── Application Global Constants ─────────────────────────────────────────────
// This class centralizes all hardcoded values, API endpoints, and configuration
// settings used across the ClimaTalk application.
class AppConstants {
  // General App Info
  static const String appName = 'ClimaTalk';
  static const String appVersion = '1.0.0';

  // ─── Weather API Configuration ──────────────────────────────────────────────
  // OpenWeatherMap credentials and base endpoints for fetching real-time data.
  static const String weatherApiKey = '4105efb8f355f4067357c9d10e84ed1b';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // ─── AI Service Configuration ───────────────────────────────────────────────
  // Google Gemini — powerful AI model.
  // IMPORTANT: Replace this with your valid Google AI API key.
  static const String geminiApiKey = 'REPLACE_WITH_YOUR_GEMINI_API_KEY';
  static const String geminiModel = 'gemini-1.5-flash';

  // AI Error Messages
  static const String errorNoApiKey = 'Missing Gemini API Key. Please configure it in AppConstants.';
  static const String errorTimeout = 'The AI is taking too long to respond. Please try again.';
  static const String errorQuotaExceeded = 'Gemini API quota exceeded. Please try again later.';
  static const String errorNoInternet = 'No internet connection. Please check your network.';
  static const String errorGeneric = 'Something went wrong with the AI service. Please try again.';

  // ─── Performance & Cache Settings ──────────────────────────────────────────
  // Parameters for controlling memory usage and data freshness.
  static const int maxCacheEntries = 10;
  static const int cacheExpiryMinutes = 10;
  static const int maxChatHistory = 50;
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  static const int retryDelaySeconds = 2;
}

