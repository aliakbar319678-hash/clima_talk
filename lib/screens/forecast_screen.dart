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

class ForecastScreen extends ConsumerWidget {
  const ForecastScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final forecastState = ref.watch(forecastProvider);
    final weatherState = ref.watch(weatherProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          forecastState.forecast != null
              ? '${forecastState.forecast!.cityName} Forecast'
              : '7-Day Forecast',
        ),
      ),
      body: _buildBody(context, ref, theme, forecastState, weatherState),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    ForecastState forecastState,
    WeatherState weatherState,
  ) {
    if (forecastState.isLoading) {
      return const LoadingWidget(message: 'Loading forecast...');
    }
    if (forecastState.hasError) {
      return AppErrorWidget(
        message: forecastState.errorMessage!,
        onRetry: () {
          if (weatherState.hasData) {
            ref.read(forecastProvider.notifier).fetchForecastByCoords(
              weatherState.weather!.latitude,
              weatherState.weather!.longitude,
            );
          }
        },
      );
    }
    if (!forecastState.hasData || forecastState.forecast!.dailyForecasts.isEmpty) {
      return _buildEmptyState();
    }

    final forecasts = forecastState.forecast!.dailyForecasts;

    return RefreshIndicator(
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
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
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
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final dayForecast = forecasts[index];
                return GestureDetector(
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
                  child: AnimatedListItem(
                    delay: index * 60,
                    child: ForecastCard(
                      forecast: dayForecast,
                      isToday: index == 0,
                    ),
                  ),
                );
              },
              childCount: forecasts.length,
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

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
