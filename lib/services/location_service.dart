// LocationService handles GPS permission requests and coordinate retrieval.
// Corresponds to the LocationService class defined in SRS Section 3.4.8.

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests location permission and returns current GPS coordinates.
  /// Throws a descriptive exception if permission is denied.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled on the device
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // Check current permission status
    permission = await Geolocator.checkPermission();

    // Request permission if not yet granted
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception(
          'Location permission denied. Please allow location access.',
        );
      }
    }

    // Handle permanently denied case — user must go to app settings
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. '
        'Please enable it from app settings.',
      );
    }

    // Return the current position with high accuracy
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  bool validateCoordinates(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
}
