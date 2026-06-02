// ─── weather_model.dart ───────────────────────────────────────────────────────
// This model represents a single snapshot of current weather conditions.
// It acts as a type-safe wrapper around the raw JSON response from OpenWeatherMap.
//
// The OpenWeatherMap /weather endpoint returns a deeply nested JSON object.
// This model flattens that structure into a clean, easy-to-use Dart class.
//
// Example raw API JSON (simplified):
// {
//   "name": "Lahore",
//   "main": {"temp": 34.5, "feels_like": 36.2, "humidity": 60},
//   "weather": [{"main": "Clear", "description": "clear sky", "icon": "01d"}],
//   "wind": {"speed": 2.5},
//   ...
// }

// ─── Weather Data Model ──────────────────────────────────────────────────────
// This model represents the current weather state for a specific location.
// It maps the raw response from the OpenWeatherMap API into a type-safe object.
class WeatherModel {
  // ─── Core Properties ────────────────────────────────────────────────────────
  final String cityName;      // e.g., "Lahore"
  final String countryCode;   // e.g., "PK"
  final double temperature;   // Current temperature in Celsius
  final double feelsLike;     // "Feels like" temperature (accounts for humidity/wind)
  final double tempMin;       // Today's minimum temperature
  final double tempMax;       // Today's maximum temperature
  final int humidity;         // Humidity percentage (0-100)
  final double windSpeed;     // Wind speed in meters per second
  final String condition;     // Primary condition (e.g., "Clear", "Rain")
  final String description;   // Detailed condition (e.g., "clear sky")
  final String iconCode;      // API icon identifier (e.g., "01d")
  final int uvIndex;          // UV Index (not available in basic API — defaults to 0)
  final int visibility;       // Visibility in meters
  final double latitude;      // GPS latitude of the location
  final double longitude;     // GPS longitude of the location
  final DateTime observedAt;  // When this weather data was recorded by the station

  const WeatherModel({
    required this.cityName,
    required this.countryCode,
    required this.temperature,
    required this.feelsLike,
    required this.tempMin,
    required this.tempMax,
    required this.humidity,
    required this.windSpeed,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.uvIndex,
    required this.visibility,
    required this.latitude,
    required this.longitude,
    required this.observedAt,
  });

  // ─── JSON Deserialization ────────────────────────────────────────────────────
  // Factory constructor that builds a WeatherModel from the raw API JSON map.
  // Uses the null-aware ?. operator to safely access nested fields.
  // The ?. returns null if the parent key doesn't exist, and ?? provides defaults.
  factory WeatherModel.fromJson(Map<String, dynamic> json) {
    return WeatherModel(
      cityName: json['name'] as String? ?? 'Unknown',
      countryCode: (json['sys']?['country'] as String?) ?? '',
      temperature: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      feelsLike: (json['main']?['feels_like'] as num?)?.toDouble() ?? 0.0,
      tempMin: (json['main']?['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (json['main']?['temp_max'] as num?)?.toDouble() ?? 0.0,
      humidity: (json['main']?['humidity'] as int?) ?? 0,
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      // 'weather' is a JSON array — we take the first element [0] for the main condition.
      condition: (json['weather'] as List?)?.first?['main'] as String? ?? '',
      description:
          (json['weather'] as List?)?.first?['description'] as String? ?? '',
      iconCode: (json['weather'] as List?)?.first?['icon'] as String? ?? '01d',
      uvIndex: 0, // Not provided by the /weather endpoint
      visibility: (json['visibility'] as int?) ?? 0,
      latitude: (json['coord']?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['coord']?['lon'] as num?)?.toDouble() ?? 0.0,
      // 'dt' is Unix timestamp in seconds — multiply by 1000 to convert to ms.
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as int?) ?? 0) * 1000,
      ),
    );
  }

  // ─── JSON Serialization ─────────────────────────────────────────────────────
  // Converts the model back into a Map<String, dynamic> for saving to cache.
  // This recreates the original API JSON structure so fromJson() can read it back.
  Map<String, dynamic> toJson() {
    return {
      'name': cityName,
      'sys': {'country': countryCode},
      'main': {
        'temp': temperature,
        'feels_like': feelsLike,
        'temp_min': tempMin,
        'temp_max': tempMax,
        'humidity': humidity,
      },
      'wind': {'speed': windSpeed},
      'weather': [
        {'main': condition, 'description': description, 'icon': iconCode},
      ],
      'visibility': visibility,
      'coord': {'lat': latitude, 'lon': longitude},
      'dt': observedAt.millisecondsSinceEpoch ~/ 1000, // Back to Unix seconds
    };
  }

  // ─── Utility Getters ────────────────────────────────────────────────────────
  // Provides high-level access to formatted data for UI display.

  // The official OpenWeatherMap icon URL for the current condition.
  // @2x means the high-resolution version of the icon.
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  // Temperature formatted for display (e.g., "25°C").
  String get temperatureDisplay => '${temperature.round()}°C';

  @override
  String toString() =>
      'WeatherModel(city: $cityName, temp: $temperature, condition: $condition)';
}
