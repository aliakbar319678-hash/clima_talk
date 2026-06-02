// ─── app_constants.dart ───────────────────────────────────────────────────────
// This file centralizes ALL hardcoded values in one place.
// Using a constants class prevents "magic numbers/strings" from being
// scattered across the codebase, making it easy to update API keys,
// URLs, and limits without hunting through every file.

// ─── Application Global Constants ─────────────────────────────────────────────
// This class centralizes all hardcoded values, API endpoints, and configuration
// settings used across the ClimaTalk application.
class AppConstants {
  // General App Info
  static const String appName = 'ClimaTalk';
  static const String appVersion = '1.0.0';

  // ─── Weather API Configuration ──────────────────────────────────────────────
  // OpenWeatherMap credentials and base endpoints for fetching real-time data.
  // The API key is used in every HTTP request to authenticate with the server.
  // The base URL is the root endpoint for all OpenWeatherMap API calls.
  static const String weatherApiKey = '4105efb8f355f4067357c9d10e84ed1b';
  static const String weatherBaseUrl =
      'https://api.openweathermap.org/data/2.5';

  // ─── AI Service Configuration ───────────────────────────────────────────────
  // Google Gemini — powerful AI model.
  // IMPORTANT: Replace this with your valid Google AI API key.
  // NOTE: The app has been migrated to use Pollinations AI (free, no key needed),
  // so these values are kept for reference but are no longer actively used.
  static const String geminiApiKey = 'REPLACE_WITH_YOUR_GEMINI_API_KEY';
  static const String geminiModel = 'gemini-1.5-flash';

  // ─── AI Error Messages ──────────────────────────────────────────────────────
  // These strings are shown to the user in the chat UI when an error occurs.
  // Centralizing them here ensures consistent messaging across the whole app.
  static const String errorNoApiKey = 'Missing Gemini API Key. Please configure it in AppConstants.';
  static const String errorTimeout = 'The AI is taking too long to respond. Please try again.';
  static const String errorQuotaExceeded = 'Gemini API quota exceeded. Please try again later.';
  static const String errorNoInternet = 'No internet connection. Please check your network.';
  static const String errorGeneric = 'Something went wrong with the AI service. Please try again.';

  // ─── Performance & Cache Settings ──────────────────────────────────────────
  // Parameters for controlling memory usage and data freshness.
  // maxCacheEntries: limits how many items are kept in memory at once.
  // cacheExpiryMinutes: data older than this is considered stale and refetched.
  // maxChatHistory: maximum number of chat messages kept in the conversation list.
  // apiTimeoutSeconds: how long to wait for a network response before giving up.
  // maxRetries: how many times to retry a failed AI request before showing an error.
  // retryDelaySeconds: how many seconds to wait between each retry attempt.
  static const int maxCacheEntries = 10;
  static const int cacheExpiryMinutes = 10;
  static const int maxChatHistory = 50;
  static const int apiTimeoutSeconds = 30;
  static const int maxRetries = 3;
  static const int retryDelaySeconds = 2;
}
