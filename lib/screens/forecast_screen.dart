// ─── forecast_screen.dart ─────────────────────────────────────────────────────
// The Forecast Screen shows the 7-day daily weather forecast as a scrollable list.
// Each row is a ForecastCard that is tappable — tapping opens the HourlyForecastScreen
// for that specific day, showing 3-hour interval breakdowns.
//
// Screen States:
//   Loading  → Shows a centered spinner with "Loading forecast..." text
//   Error    → Shows an error message with a Retry button
//   Empty    → Shows a placeholder when no city is selected yet
//   Data     → Shows a scrollable list of ForecastCard widgets

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_theme.dart';
import '../providers/forecast_provider.dart';
import '../providers/weather_provider.dart';
import '../widgets/animated_list_item.dart';
import '../widgets/forecast_card.dart';
import '../widgets/loading_widget.dart';
import '../widgets/app_error_widget.dart';
import 'hourly_forecast_screen.dart';

// ─── ForecastScreen ───────────────────────────────────────────────────────────
// A simple ConsumerWidget (no state needed — just reads from providers).
class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both providers — this widget rebuilds when either state changes.
    final forecastState = ref.watch(forecastProvider);
    final weatherState = ref.watch(weatherProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        // Dynamic title: shows city name if forecast is loaded, generic title otherwise.
        title: Text(
          forecastState.forecast != null
              ? '${forecastState.forecast!.cityName} Forecast'
              : '7-Day Forecast',
        ),
      ),
      body: _buildBody(context, ref, theme, forecastState, weatherState),
    );
  }

  // ─── Body Builder ────────────────────────────────────────────────────────
  // Handles all four possible states of the forecast feature.
  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ForecastState forecastState,
    WeatherState weatherState,
  ) {
    // Loading state — show a full-screen loading widget.
    if (forecastState.isLoading) {
      return const LoadingWidget(message: 'Loading forecast...');
    }
    // Error state — show an error widget with a retry button.
    if (forecastState.hasError) {
      return AppErrorWidget(
        message: forecastState.errorMessage!,
        onRetry: () {
          // Re-fetch using the current weather location's coordinates.
          if (weatherState.hasData) {
            ref.read(forecastProvider.notifier).fetchForecastByCoords(
              weatherState.weather!.latitude,
              weatherState.weather!.longitude,
            );
          }
        },
      );
    }
    // Empty state — no data yet (app just started, no location selected).
    if (!forecastState.hasData || forecastState.forecast!.dailyForecasts.isEmpty) {
      return _buildEmptyState();
    }

    // Data state — show the list of daily forecasts.
    final forecasts = forecastState.forecast!.dailyForecasts;

    return RefreshIndicator(
      // Pull-to-refresh refetches forecast using current GPS coordinates.
      onRefresh: () async {
        if (weatherState.hasData) {
          await ref.read(forecastProvider.notifier).fetchForecastByCoords(
            weatherState.weather!.latitude,
            weatherState.weather!.longitude,
          );
        }
      },
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Header Row ─────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  // Calendar icon in a rounded container
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_month_rounded,
                      color: AppTheme.primaryBlue,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Daily Overview',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // ─── Forecast List ───────────────────────────────────────────────
          // SliverList is more performant than a Column for long lists —
          // it only renders items visible on screen (lazy rendering).
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dayForecast = forecasts[index];
                return GestureDetector(
                  // Tapping a day navigates to its hourly breakdown screen.
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HourlyForecastScreen(
                        cityName: forecastState.forecast!.cityName,
                        selectedDay: dayForecast.date,
                        hourlyData: forecastState.forecast!.hourlyForecasts,
                      ),
                    ),
                  ),
                  // AnimatedListItem wraps each card in a staggered entrance animation.
                  // delay * index means each card appears slightly after the previous one.
                  child: AnimatedListItem(
                    delay: index * 60, // Stagger: 0ms, 60ms, 120ms, 180ms...
                    child: ForecastCard(
                      forecast: dayForecast,
                      isToday: index == 0, // First item is always today
                    ),
                  ),
                );
              },
              childCount: forecasts.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)), // Bottom padding
        ],
      ),
    );
  }

  // Shown when no forecast data is available yet.
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.calendar_today_outlined,
              size: 40,
              color: AppTheme.primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No forecast available',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Text(
            'Search for a city or allow\nlocation access.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
