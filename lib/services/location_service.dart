// ─── location_service.dart ────────────────────────────────────────────────────
// This service handles all GPS-related operations using the 'geolocator' package.
// It abstracts the permission flow so providers don't have to manage it themselves.
//
// Permission Flow:
//  1. Check if device's GPS hardware/service is enabled.
//  2. Check if app has permission to access location.
//  3. Request permission if not yet granted.
//  4. Throw a descriptive exception if permission is denied.
//  5. Return the current GPS Position (latitude + longitude).
//
// LocationService handles GPS permission requests and coordinate retrieval.
// Corresponds to the LocationService class defined in SRS Section 3.4.8.

import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Requests location permission and returns current GPS coordinates.
  /// Throws a descriptive exception if permission is denied.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Step 1: Check if the device's location service (GPS) is actually turned on.
    // Even if the app has permission, GPS might be switched off by the user.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    // Step 2: Check current permission status (denied, granted, etc.)
    permission = await Geolocator.checkPermission();

    // Step 3: If permission hasn't been decided yet, show the system dialog.
    // The user will see "Allow ClimaTalk to access your location?" prompt.
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // User explicitly pressed "Deny" on the permission dialog.
        throw Exception(
          'Location permission denied. Please allow location access.',
        );
      }
    }

    // Step 4: Handle permanently denied case — user must go to app settings manually.
    // This happens after the user denied permission twice — Android won't show the
    // dialog again. The user must manually enable it in Settings > App Info.
    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied. '
        'Please enable it from app settings.',
      );
    }

    // Step 5: All checks passed — get the GPS coordinates with high accuracy.
    // LocationAccuracy.high uses GPS satellites for the most precise position.
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );
  }

  // Validates that given coordinates are within the valid geographic range.
  // Latitude must be between -90 and 90, longitude between -180 and 180.
  bool validateCoordinates(double lat, double lon) {
    return lat >= -90 && lat <= 90 && lon >= -180 && lon <= 180;
  }
}
