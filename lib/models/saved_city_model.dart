// SavedCityModel represents a city saved by the user to their favorites.
// Stored in Firebase Firestore under the user's document.

class SavedCityModel {
  final String id; // Firestore document ID
  final String cityName;
  final String countryCode;
  final double latitude;
  final double longitude;
  final DateTime savedAt;

  const SavedCityModel({
    required this.id,
    required this.cityName,
    required this.countryCode,
    required this.latitude,
    required this.longitude,
    required this.savedAt,
  });

  /// Constructs a SavedCityModel from Firestore document data.
  factory SavedCityModel.fromJson(Map<String, dynamic> json, String docId) {
    return SavedCityModel(
      id: docId,
      cityName: json['cityName'] as String? ?? '',
      countryCode: json['countryCode'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      savedAt: json['savedAt'] != null
          ? DateTime.parse(json['savedAt'] as String)
          : DateTime.now(),
    );
  }

  /// Converts to a JSON map for Firestore storage.
  Map<String, dynamic> toJson() {
    return {
      'cityName': cityName,
      'countryCode': countryCode,
      'latitude': latitude,
      'longitude': longitude,
      'savedAt': savedAt.toIso8601String(),
    };
  }

  /// Display label combining city and country.
  String get displayName => '$cityName, $countryCode';
}
