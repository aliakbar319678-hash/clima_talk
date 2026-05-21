import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../models/saved_city_model.dart';
import '../models/weather_model.dart';
import '../providers/saved_cities_provider.dart';
import '../providers/weather_provider.dart';
import '../services/weather_service.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/city_list_tile.dart';
import '../widgets/loading_widget.dart';

class SavedCitiesScreen extends ConsumerStatefulWidget {
  const SavedCitiesScreen({super.key});

  @override
  ConsumerState<SavedCitiesScreen> createState() => _SavedCitiesScreenState();
}

class _SavedCitiesScreenState extends ConsumerState<SavedCitiesScreen>
    with SingleTickerProviderStateMixin {
  final WeatherService _weatherService = WeatherService();
  final Map<String, WeatherModel?> _weatherCache = {};
  final Map<String, bool> _loadingMap = {};
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
    _animCtrl.forward();
    Future.microtask(_fetchAllWeather);
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchAllWeather() async {
    final cities = ref.read(savedCitiesProvider).cities;
    // Fetch all city weather in parallel instead of sequentially.
    await Future.wait(cities.map(_fetchCityWeather));
  }

  Future<void> _fetchCityWeather(SavedCityModel city) async {
    if (!mounted) return;
    setState(() => _loadingMap[city.id] = true);
    try {
      final w = await _weatherService.getCurrentWeatherByCity(city.cityName);
      if (mounted) {
        setState(() {
          _weatherCache[city.id] = w;
          _loadingMap[city.id] = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMap[city.id] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final savedState = ref.watch(savedCitiesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    ref.listen<SavedCitiesState>(savedCitiesProvider, (_, current) {
      if (current.successMessage != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(current.successMessage!),
              backgroundColor: AppTheme.successColor,
            ),
          );
        ref.read(savedCitiesProvider.notifier).clearMessages();
      }
      if (current.errorMessage != null) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(current.errorMessage!),
              backgroundColor: AppTheme.errorColor,
            ),
          );
        ref.read(savedCitiesProvider.notifier).clearMessages();
      }
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Saved Cities'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: _showAddCityDialog,
          ),
        ],
      ),
      body: savedState.isLoading
          ? const LoadingWidget(message: 'Loading saved cities...')
          : savedState.isEmpty
          ? _buildEmptyState(isDark)
          : FadeTransition(
              opacity: _fadeAnim,
              child: RefreshIndicator(
                onRefresh: () async {
                  await ref
                      .read(savedCitiesProvider.notifier)
                      .fetchSavedCities();
                  _fetchAllWeather();
                },
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 24),
                  physics: const BouncingScrollPhysics(),
                  itemCount: savedState.cities.length,
                  itemBuilder: (context, index) {
                    final city = savedState.cities[index];
                    return AnimatedListItem(
                      delay: index * 80,
                      child: CityListTile(
                        city: city,
                        weatherData: _weatherCache[city.id],
                        isLoadingWeather: _loadingMap[city.id] ?? false,
                        onTap: () {
                          ref
                              .read(weatherProvider.notifier)
                              .fetchWeatherByCity(city.cityName);
                          ScaffoldMessenger.of(context)
                            ..clearSnackBars()
                            ..showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Loading ${city.cityName} weather...',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                        },
                        onDelete: () => _confirmDelete(city),
                      ),
                    );
                  },
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bookmark_border_rounded,
                  size: 46,
                  color: AppTheme.primaryBlue,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No saved cities yet',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppTheme.textPrimaryLight,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tap + to add your favorite cities\nfor quick weather access.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDark
                      ? AppTheme.textSecondaryDark
                      : AppTheme.textSecondaryLight,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: _showAddCityDialog,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add Your First City'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDelete(SavedCityModel city) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Remove City'),
        content: Text('Remove ${city.cityName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(savedCitiesProvider.notifier)
                  .removeCity(city.id, city.cityName);
              setState(() {
                _weatherCache.remove(city.id);
                _loadingMap.remove(city.id);
              });
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showAddCityDialog() {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.location_city_rounded, color: AppTheme.primaryBlue),
            SizedBox(width: 10),
            Text('Add City'),
          ],
        ),
        content: TextField(
          controller: ctrl,
          textCapitalization: TextCapitalization.words,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'e.g. London, Karachi, Dubai',
            prefixIcon: const Icon(Icons.search_rounded),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onSubmitted: (_) async {
            Navigator.pop(ctx);
            await _addCity(ctrl.text.trim());
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              Navigator.pop(ctx);
              await _addCity(name);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _addCity(String name) async {
    if (name.isEmpty) return;

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12),
              Text('Searching city...'),
            ],
          ),
          duration: const Duration(seconds: 15),
        ),
      );

    try {
      final weather = await _weatherService.getCurrentWeatherByCity(name);
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();

      final city = SavedCityModel(
        id: '',
        cityName: weather.cityName,
        countryCode: weather.countryCode,
        latitude: weather.latitude,
        longitude: weather.longitude,
        savedAt: DateTime.now(),
      );

      await ref.read(savedCitiesProvider.notifier).addCity(city);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: AppTheme.errorColor,
        ),
      );
    }
  }
}
