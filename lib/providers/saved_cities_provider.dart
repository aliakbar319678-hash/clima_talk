// ─── saved_cities_provider.dart ───────────────────────────────────────────────
// Manages the list of cities the user has bookmarked as "favorites."
// Uses SharedPreferences (local device storage) to persist the list —
// so saved cities survive app restarts without needing a backend/database.
//
// Data Flow:
//  1. App starts → build() triggers fetchSavedCities() via Future.microtask
//  2. SharedPreferences is read → city list is decoded from JSON string
//  3. UI rebuilds with the list of saved cities
//  4. User can addCity() or removeCity() — both update state AND disk immediately
//
// SavedCitiesProvider manages the user's favorite cities via SharedPreferences.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_city_model.dart';

// ─── SavedCitiesState ─────────────────────────────────────────────────────────
// Immutable snapshot of the saved cities feature state.
/// Holds the saved cities list and operation states.
class SavedCitiesState {
  final List<SavedCityModel> cities;    // The current list of favorite cities
  final bool isLoading;                 // True while reading from disk
  final String? errorMessage;           // Non-null on error (e.g., disk read failed)
  final String? successMessage;         // Non-null after a successful add/remove

  const SavedCitiesState({
    this.cities = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  // Creates a new state object with specific fields overridden.
  // Note: errorMessage and successMessage are always reset (not carried over)
  // so old feedback messages don't persist across unrelated state changes.
  SavedCitiesState copyWith({
    List<SavedCityModel>? cities,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return SavedCitiesState(
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,   // Always replaced (null clears previous error)
      successMessage: successMessage, // Always replaced
    );
  }

  bool get hasError => errorMessage != null;
  bool get isEmpty => cities.isEmpty;
}

// ─── SavedCitiesNotifier ──────────────────────────────────────────────────────
/// Notifier for saved cities management using local SharedPreferences.
class SavedCitiesNotifier extends Notifier<SavedCitiesState> {
  // The key under which the cities JSON list is stored in SharedPreferences.
  static const _prefsKey = 'saved_cities_local';

  @override
  SavedCitiesState build() {
    // Future.microtask defers the async load until after the widget tree is built.
    // This prevents the "build called while another build is in progress" error.
    Future.microtask(fetchSavedCities);
    return const SavedCitiesState(isLoading: true); // Show loading spinner immediately
  }

  /// Loads saved cities from local SharedPreferences.
  /// Cities are stored as a JSON string (array of city objects).
  Future<void> fetchSavedCities() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final citiesJsonString = prefs.getString(_prefsKey);
      
      // If no data has ever been saved, return an empty list.
      if (citiesJsonString == null) {
        state = state.copyWith(cities: [], isLoading: false);
        return;
      }
      
      // Decode the JSON string back into a List, then convert each item to a model.
      final List<dynamic> decodedList = jsonDecode(citiesJsonString);
      final cities = decodedList
          .map((c) => SavedCityModel.fromJson(c as Map<String, dynamic>, c['id'] ?? ''))
          .toList();
          
      // Sort so newest is first, similar to Firebase descending order.
      cities.sort((a, b) => b.savedAt.compareTo(a.savedAt));
          
      state = state.copyWith(cities: cities, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Unable to load saved cities.',
      );
    }
  }

  /// Adds a city to favorites and syncs with SharedPreferences.
  Future<void> addCity(SavedCityModel city) async {
    try {
      // Check for duplicate before saving — prevent the same city appearing twice.
      final isDuplicate = state.cities.any(
        (c) => c.cityName.toLowerCase() == city.cityName.toLowerCase(),
      );

      if (isDuplicate) {
        // Show an error feedback message to the user instead of adding it again.
        state = state.copyWith(
          successMessage: null,
          errorMessage: '${city.cityName} is already in your saved cities.',
        );
        return;
      }

      // Ensure city has a unique ID if it's empty.
      // The ID is used later for deletion (we match by ID, not name).
      final cityToSave = city.id.isEmpty
          ? SavedCityModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(), // Unique timestamp ID
            cityName: city.cityName,
            countryCode: city.countryCode,
            latitude: city.latitude,
            longitude: city.longitude,
            savedAt: city.savedAt,
          )
          : city;

      // Prepend new city to the front of the list (newest first ordering).
      final prefs = await SharedPreferences.getInstance();
      final updatedCities = [cityToSave, ...state.cities];
      
      // Convert the list back to JSON (include the 'id' field manually since
      // toJson() doesn't include it — it's normally the Firestore document ID).
      final citiesJsonList = updatedCities.map((c) {
        final Map<String, dynamic> j = c.toJson();
        j['id'] = c.id; // Include local ID for deletion support
        return j;
      }).toList();
      
      // Write the updated list back to disk as a JSON string.
      await prefs.setString(_prefsKey, jsonEncode(citiesJsonList));

      // Update in-memory state to trigger UI rebuild with success feedback.
      state = state.copyWith(
        cities: updatedCities,
        successMessage: '${cityToSave.cityName} added to favorites!',
        errorMessage: null,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to save city: ${e.toString()}',
      );
    }
  }

  /// Removes a city from favorites by its local ID.
  Future<void> removeCity(String cityId, String cityName) async {
    try {
      // Filter out the city with matching ID from the in-memory list.
      final updatedCities = state.cities.where((c) => c.id != cityId).toList();
      final prefs = await SharedPreferences.getInstance();
      
      // Re-serialize the remaining cities and overwrite the stored JSON string.
      final citiesJsonList = updatedCities.map((c) {
        final j = c.toJson();
        j['id'] = c.id;
        return j;
      }).toList();
      
      await prefs.setString(_prefsKey, jsonEncode(citiesJsonList));
      
      // Update in-memory state with success message for the user.
      state = state.copyWith(
        cities: updatedCities,
        successMessage: '$cityName removed from favorites.',
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'Unable to remove city. Please try again.',
      );
    }
  }

  /// Clears any feedback messages after they've been shown to the user.
  /// Called after a SnackBar has been shown, so old messages don't re-appear.
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

// ─── Provider Declaration ─────────────────────────────────────────────────────
/// Provider for saved cities state management.
final savedCitiesProvider =
    NotifierProvider<SavedCitiesNotifier, SavedCitiesState>(() {
      return SavedCitiesNotifier();
    });
