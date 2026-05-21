// SavedCitiesProvider manages the user's favorite cities via SharedPreferences.

import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/saved_city_model.dart';

/// Holds the saved cities list and operation states.
class SavedCitiesState {
  final List<SavedCityModel> cities;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const SavedCitiesState({
    this.cities = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  SavedCitiesState copyWith({
    List<SavedCityModel>? cities,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
  }) {
    return SavedCitiesState(
      cities: cities ?? this.cities,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      successMessage: successMessage,
    );
  }

  bool get hasError => errorMessage != null;
  bool get isEmpty => cities.isEmpty;
}

/// Notifier for saved cities management using local SharedPreferences.
class SavedCitiesNotifier extends Notifier<SavedCitiesState> {
  static const _prefsKey = 'saved_cities_local';

  @override
  SavedCitiesState build() {
    Future.microtask(fetchSavedCities);
    return const SavedCitiesState(isLoading: true);
  }

  /// Loads saved cities from local SharedPreferences.
  Future<void> fetchSavedCities() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final prefs = await SharedPreferences.getInstance();
      final citiesJsonString = prefs.getString(_prefsKey);
      
      if (citiesJsonString == null) {
        state = state.copyWith(cities: [], isLoading: false);
        return;
      }
      
      final List<dynamic> decodedList = jsonDecode(citiesJsonString);
      final cities = decodedList
          .map((c) => SavedCityModel.fromJson(c as Map<String, dynamic>, c['id'] ?? ''))
          .toList();
          
      // Sort so newest is first, similar to Firebase descending order
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
      // Check for duplicate before saving
      final isDuplicate = state.cities.any(
        (c) => c.cityName.toLowerCase() == city.cityName.toLowerCase(),
      );

      if (isDuplicate) {
        state = state.copyWith(
          successMessage: null,
          errorMessage: '${city.cityName} is already in your saved cities.',
        );
        return;
      }

      // Ensure city has a unique ID if it's empty
      final cityToSave = city.id.isEmpty
          ? SavedCityModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            cityName: city.cityName,
            countryCode: city.countryCode,
            latitude: city.latitude,
            longitude: city.longitude,
            savedAt: city.savedAt,
          )
          : city;

      final prefs = await SharedPreferences.getInstance();
      final updatedCities = [cityToSave, ...state.cities];
      
      final citiesJsonList = updatedCities.map((c) {
        final Map<String, dynamic> j = c.toJson();
        j['id'] = c.id; 
        return j;
      }).toList();
      
      await prefs.setString(_prefsKey, jsonEncode(citiesJsonList));

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
      final updatedCities = state.cities.where((c) => c.id != cityId).toList();
      final prefs = await SharedPreferences.getInstance();
      
      final citiesJsonList = updatedCities.map((c) {
        final j = c.toJson();
        j['id'] = c.id;
        return j;
      }).toList();
      
      await prefs.setString(_prefsKey, jsonEncode(citiesJsonList));
      
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

  /// Clears any feedback messages after they've been shown.
  void clearMessages() {
    state = state.copyWith(errorMessage: null, successMessage: null);
  }
}

/// Provider for saved cities state management.
final savedCitiesProvider =
    NotifierProvider<SavedCitiesNotifier, SavedCitiesState>(() {
      return SavedCitiesNotifier();
    });
