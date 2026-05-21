// ─── Weather Data Model ──────────────────────────────────────────────────────
// This model represents the current weather state for a specific location.
// It maps the raw response from the OpenWeatherMap API into a type-safe object.
class WeatherModel {
  // ─── Core Properties ────────────────────────────────────────────────────────
  final String cityName;
  final String countryCode;
  final double temperature;
  final double feelsLike;
  final double tempMin;
  final double tempMax;
  final int humidity;
  final double windSpeed;
  final String condition;     // Primary condition (e.g., "Clear", "Rain")
  final String description;   // Detailed condition (e.g., "clear sky")
  final String iconCode;      // API icon identifier (e.g., "01d")
  final int uvIndex;
  final int visibility;
  final double latitude;
  final double longitude;
  final DateTime observedAt;

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

  // ─── JSON Serialization ─────────────────────────────────────────────────────
  // Handles mapping from the API's complex nested JSON structure to our flat model.
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
      condition: (json['weather'] as List?)?.first?['main'] as String? ?? '',
      description:
          (json['weather'] as List?)?.first?['description'] as String? ?? '',
      iconCode: (json['weather'] as List?)?.first?['icon'] as String? ?? '01d',
      uvIndex: 0, 
      visibility: (json['visibility'] as int?) ?? 0,
      latitude: (json['coord']?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['coord']?['lon'] as num?)?.toDouble() ?? 0.0,
      observedAt: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as int?) ?? 0) * 1000,
      ),
    );
  }

  // Converts the object back into a JSON-compatible map for persistent caching.
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
      'dt': observedAt.millisecondsSinceEpoch ~/ 1000,
    };
  }

  // ─── Utility Getters ────────────────────────────────────────────────────────
  // Provides high-level access to formatted data for UI display.

  // The official OpenWeatherMap icon URL for the current condition.
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';

  // Temperature formatted for display (e.g., "25°C").
  String get temperatureDisplay => '${temperature.round()}°C';

  @override
  String toString() =>
      'WeatherModel(city: $cityName, temp: $temperature, condition: $condition)';
}

