// ─── Daily Forecast Data Model ───────────────────────────────────────────────
// Represents a single "time slice" or day within a weather forecast.
class ForecastDayModel {
  // ─── Properties ─────────────────────────────────────────────────────────────
  final DateTime date;
  final double tempMin;
  final double tempMax;
  final double tempDay;
  final String condition;
  final String description;
  final String iconCode;
  final int humidity;
  final double windSpeed;
  final double precipitationProbability;

  const ForecastDayModel({
    required this.date,
    required this.tempMin,
    required this.tempMax,
    required this.tempDay,
    required this.condition,
    required this.description,
    required this.iconCode,
    required this.humidity,
    required this.windSpeed,
    required this.precipitationProbability,
  });

  // ─── JSON Factory ──────────────────────────────────────────────────────────
  factory ForecastDayModel.fromJson(Map<String, dynamic> json) {
    return ForecastDayModel(
      date: DateTime.fromMillisecondsSinceEpoch(
        ((json['dt'] as int?) ?? 0) * 1000,
      ),
      tempMin: (json['main']?['temp_min'] as num?)?.toDouble() ?? 0.0,
      tempMax: (json['main']?['temp_max'] as num?)?.toDouble() ?? 0.0,
      tempDay: (json['main']?['temp'] as num?)?.toDouble() ?? 0.0,
      condition: (json['weather'] as List?)?.first?['main'] as String? ?? '',
      description:
          (json['weather'] as List?)?.first?['description'] as String? ?? '',
      iconCode: (json['weather'] as List?)?.first?['icon'] as String? ?? '01d',
      humidity: (json['main']?['humidity'] as int?) ?? 0,
      windSpeed: (json['wind']?['speed'] as num?)?.toDouble() ?? 0.0,
      precipitationProbability: (json['pop'] as num?)?.toDouble() ?? 0.0,
    );
  }

  // ─── Display Helpers ────────────────────────────────────────────────────────
  String get iconUrl => 'https://openweathermap.org/img/wn/$iconCode@2x.png';
  String get tempDisplay => '${tempDay.round()}°C';
  String get minMaxDisplay => '${tempMin.round()}° / ${tempMax.round()}°';
}

// ─── Aggregate Forecast Response ─────────────────────────────────────────────
// Manages the complete forecast payload, providing both daily and hourly views.
class ForecastResponse {
  final String cityName;
  final String countryCode;
  final List<ForecastDayModel> dailyForecasts;
  final List<ForecastDayModel> hourlyForecasts;

  const ForecastResponse({
    required this.cityName,
    required this.countryCode,
    required this.dailyForecasts,
    required this.hourlyForecasts,
  });

  // Processes the API response to group 3-hour intervals into 24-hour days.
  factory ForecastResponse.fromJson(Map<String, dynamic> json) {
    final cityName = json['city']?['name'] as String? ?? '';
    final countryCode = json['city']?['country'] as String? ?? '';
    final rawList = json['list'] as List<dynamic>? ?? [];

    // Parse all raw intervals into a flat list
    final List<ForecastDayModel> hourlyForecasts = rawList
        .map((item) => ForecastDayModel.fromJson(item as Map<String, dynamic>))
        .toList();

    // Group intervals into days, selecting the noon entry to represent the day
    final Map<String, ForecastDayModel> dailyMap = {};
    for (final entry in hourlyForecasts) {
      final dateKey =
          '${entry.date.year}-${entry.date.month}-${entry.date.day}';

      if (!dailyMap.containsKey(dateKey)) {
        dailyMap[dateKey] = entry;
      } else {
        // Find the entry closest to 12:00 PM for the most accurate daily representation
        final existingHourDiff = (dailyMap[dateKey]!.date.hour - 12).abs();
        final newHourDiff = (entry.date.hour - 12).abs();
        if (newHourDiff < existingHourDiff) {
          dailyMap[dateKey] = entry;
        }
      }
    }

    final sorted = dailyMap.values.toList()
      ..sort((a, b) => a.date.compareTo(b.date));

    return ForecastResponse(
      cityName: cityName,
      countryCode: countryCode,
      dailyForecasts: sorted.take(7).toList(),
      hourlyForecasts: hourlyForecasts,
    );
  }
}

