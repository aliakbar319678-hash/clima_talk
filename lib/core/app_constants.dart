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
  // Google Gemini API settings for the smart weather companion chat feature.
  static const String aiApiKey = 'AIzaSyBJ54hsocuI0mDGDJM8VA4jNDGmGdbiGdw';
  static const String aiBaseUrl =
      'https://generativelanguage.googleapis.com/v1';
  static const String aiModel = 'gemini-2.0-flash';

  // ─── Performance & Cache Settings ──────────────────────────────────────────
  // Parameters for controlling memory usage and data freshness.
  static const int maxCacheEntries = 10;
  static const int cacheExpiryMinutes = 10;
  static const int maxChatHistory = 50;
  static const int apiTimeoutSeconds = 30;

}

