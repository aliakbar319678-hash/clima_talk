import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import '../models/forecast_model.dart';

class ForecastCard extends StatelessWidget {
  final ForecastDayModel forecast;
  final bool isToday;
  const ForecastCard({super.key, required this.forecast, this.isToday = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final condition = forecast.condition.toLowerCase();
    final gradientColors = _gradientColors(condition, isDark);
    final titleColor = isDark ? Colors.white : const Color(0xFF0A1545);
    final subColor = isDark ? Colors.white70 : Colors.black54;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: gradientColors[0].withValues(alpha: isDark ? 0.4 : 0.2),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.4),
          width: 1.5,
        ),
      ),
      child: Row(
        children: [
          // Day label
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isToday ? 'Today' : DateFormat('EEEE').format(forecast.date),
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    color: titleColor,
                  ),
                ),
                Text(
                  DateFormat('MMMM d').format(forecast.date),
                  style: TextStyle(
                    color: subColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // Icon + condition
          Expanded(
            flex: 4,
            child: Column(
              children: [
                CachedNetworkImage(
                  imageUrl: forecast.iconUrl,
                  width: 50,
                  height: 50,
                  // SizedBox placeholder — avoids starting a spinner animation per card row.
                  placeholder: (context, url) => const SizedBox(width: 50, height: 50),
                ),
                Text(
                  forecast.condition,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          // Temperature range
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${forecast.tempMax.round()}°',
                  style: TextStyle(
                    color: titleColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${forecast.tempMin.round()}°',
                  style: TextStyle(
                    color: subColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Color> _gradientColors(String condition, bool isDark) {
    if (condition.contains('sunny') || condition.contains('clear')) {
      return isDark
          ? [const Color(0xFF644100), const Color(0xFF332000)]
          : [const Color(0xFFFFD54F), const Color(0xFFFFB300)];
    } else if (condition.contains('rain') || condition.contains('drizzle')) {
      return isDark
          ? [const Color(0xFF0D47A1), const Color(0xFF001133)]
          : [const Color(0xFF64B5F6), const Color(0xFF1E88E5)];
    } else if (condition.contains('cloud')) {
      return isDark
          ? [const Color(0xFF455A64), const Color(0xFF1C313A)]
          : [const Color(0xFFCFD8DC), const Color(0xFF90A4AE)];
    } else if (condition.contains('storm') || condition.contains('thunder')) {
      return isDark
          ? [const Color(0xFF311B92), const Color(0xFF12005E)]
          : [const Color(0xFF9575CD), const Color(0xFF5E35B1)];
    } else if (condition.contains('snow')) {
      return isDark
          ? [const Color(0xFF006064), const Color(0xFF00252A)]
          : [const Color(0xFFB2EBF2), const Color(0xFF4DD0E1)];
    }
    return isDark
        ? [const Color(0xFF263238), const Color(0xFF000000)]
        : [const Color(0xFFECEFF1), const Color(0xFFB0BEC5)];
  }
}
