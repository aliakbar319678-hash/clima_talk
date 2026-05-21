// WeatherAlertModel represents a severe weather alert from the API.
// Used by the Notification Subsystem as defined in SDD.

class WeatherAlertModel {
  final String senderName;
  final String event;
  final DateTime start;
  final DateTime end;
  final String description;
  final List<String> tags;

  const WeatherAlertModel({
    required this.senderName,
    required this.event,
    required this.start,
    required this.end,
    required this.description,
    required this.tags,
  });

  /// Parses an alert entry from the OpenWeatherMap OneCall API response.
  factory WeatherAlertModel.fromJson(Map<String, dynamic> json) {
    return WeatherAlertModel(
      senderName: json['sender_name'] as String? ?? 'Weather Service',
      event: json['event'] as String? ?? 'Weather Alert',
      start: DateTime.fromMillisecondsSinceEpoch(
        ((json['start'] as int?) ?? 0) * 1000,
      ),
      end: DateTime.fromMillisecondsSinceEpoch(
        ((json['end'] as int?) ?? 0) * 1000,
      ),
      description: json['description'] as String? ?? '',
      tags: (json['tags'] as List?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  /// Returns a short readable event label for notifications.
  String get shortDescription {
    if (description.length > 100) {
      return '${description.substring(0, 100)}...';
    }
    return description;
  }
}
