import 'package:flutter/material.dart';

import '../core/app_theme.dart';
import '../models/saved_city_model.dart';
import '../models/weather_model.dart';

class CityListTile extends StatefulWidget {
  final SavedCityModel city;
  final WeatherModel? weatherData;
  final bool isLoadingWeather;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const CityListTile({
    super.key,
    required this.city,
    this.weatherData,
    this.isLoadingWeather = false,
    this.onTap,
    this.onDelete,
  });

  @override
  State<CityListTile> createState() => _CityListTileState();
}

class _CityListTileState extends State<CityListTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnim = Tween<double>(
      begin: 1,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: GestureDetector(
        onTapDown: (_) => _ctrl.forward(),
        onTapUp: (_) {
          _ctrl.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _ctrl.reverse(),
        child: ScaleTransition(
          scale: _scaleAnim,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.nightCard : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.07),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Weather icon
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.weatherData != null
                          ? _getConditionColors(widget.weatherData!.condition)
                          : [AppTheme.primaryBlue, AppTheme.lightBlue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: widget.isLoadingWeather
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.weatherData != null
                                ? _conditionEmoji(widget.weatherData!.condition)
                                : '🌍',
                            style: const TextStyle(fontSize: 26),
                          ),
                        ),
                ),

                const SizedBox(width: 14),

                // City info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.city.cityName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            widget.city.countryCode,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                          if (widget.weatherData != null) ...[
                            const Text(
                              ' · ',
                              style: TextStyle(color: Colors.grey),
                            ),
                            Text(
                              widget.weatherData!.condition,
                              style: const TextStyle(
                                color: AppTheme.lightBlue,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Temperature
                if (widget.weatherData != null)
                  Text(
                    widget.weatherData!.temperatureDisplay,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w200,
                      color: AppTheme.primaryBlue,
                    ),
                  ),

                const SizedBox(width: 4),

                // Delete
                if (widget.onDelete != null)
                  GestureDetector(
                    onTap: widget.onDelete,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red,
                        size: 18,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getConditionColors(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return [const Color(0xFF1E88E5), const Color(0xFF42A5F5)];
      case 'clouds':
        return [const Color(0xFF546E7A), const Color(0xFF78909C)];
      case 'rain':
      case 'drizzle':
        return [const Color(0xFF1565C0), const Color(0xFF1976D2)];
      case 'thunderstorm':
        return [const Color(0xFF4A148C), const Color(0xFF6A1B9A)];
      case 'snow':
        return [const Color(0xFF1E88E5), const Color(0xFF64B5F6)];
      default:
        return [AppTheme.primaryBlue, AppTheme.lightBlue];
    }
  }

  String _conditionEmoji(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
      case 'haze':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
}
