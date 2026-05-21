import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_theme.dart';
import '../models/weather_model.dart';

class WeatherCard extends StatefulWidget {
  final WeatherModel weather;
  final VoidCallback? onRefresh;

  const WeatherCard({super.key, required this.weather, this.onRefresh});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerCtrl;
  // Cached once — date only changes at midnight, not on every rebuild.
  late final String _formattedDate;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
    _formattedDate = DateFormat('EEEE, MMMM d').format(DateTime.now());
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // sizeOf subscribes only to size changes — cheaper than MediaQuery.of(context).
    final size = MediaQuery.sizeOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradColors = _gradientColors(widget.weather.condition, isDark);
    final horizontalPad = size.width * 0.04;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: 8),
      child: AnimatedBuilder(
        animation: _shimmerCtrl,
        // Keep the heavy card body outside the builder to avoid rebuilding it
        // on every animation frame — only the animated border uses the builder.
        builder: (_, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradColors,
              ),
              border: Border.all(
                color: Colors.white.withValues(
                  alpha: 0.08 + 0.08 * sin(_shimmerCtrl.value * 2 * pi),
                ),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: gradColors.first.withValues(alpha: isDark ? 0.5 : 0.35),
                  blurRadius: 32,
                  spreadRadius: -6,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: child,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            children: [
              // Decorative background circles
              Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                  ),
                ),
              ),
              Positioned(
                bottom: -30,
                left: -20,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.03),
                  ),
                ),
              ),
              // Main content
              Padding(
                padding: EdgeInsets.all(size.width * 0.055),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Location + refresh
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Icon(
                                      Icons.location_on_rounded,
                                      color: Colors.white,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      '${widget.weather.cityName}, ${widget.weather.countryCode}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.2,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _formattedDate,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (widget.onRefresh != null)
                          _PressableButton(
                            onTap: widget.onRefresh!,
                            child: Container(
                              padding: const EdgeInsets.all(9),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 0.8,
                                ),
                              ),
                              child: const Icon(
                                Icons.refresh_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                      ],
                    ),

                    SizedBox(height: size.width * 0.05),

                    // Temperature + weather icon
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${widget.weather.temperature.round()}°',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: size.width * 0.22,
                                fontWeight: FontWeight.w100,
                                height: 0.9,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.weather.condition,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.weather.description.toUpperCase(),
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 10,
                                letterSpacing: 1.8,
                              ),
                            ),
                          ],
                        ),
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.06),
                              ),
                            ),
                            CachedNetworkImage(
                              imageUrl: widget.weather.iconUrl,
                              width: 90,
                              height: 90,
                              placeholder: (context, url) =>
                                  const SizedBox(width: 90, height: 90),
                              errorWidget: (context, url, error) => Icon(
                                _conditionIcon(widget.weather.condition),
                                color: Colors.white70,
                                size: 72,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'Feels like ${widget.weather.feelsLike.round()}°  ·  '
                        '${widget.weather.tempMin.round()}° / ${widget.weather.tempMax.round()}°',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.75),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
                    Divider(color: Colors.white.withValues(alpha: 0.12), thickness: 0.8),
                    const SizedBox(height: 16),

                    // Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(
                          icon: Icons.water_drop_outlined,
                          value: '${widget.weather.humidity}%',
                          label: 'Humidity',
                        ),
                        _VerticalDivider(),
                        _StatItem(
                          icon: Icons.air_rounded,
                          value: '${widget.weather.windSpeed.toStringAsFixed(1)} m/s',
                          label: 'Wind',
                        ),
                        _VerticalDivider(),
                        _StatItem(
                          icon: Icons.visibility_outlined,
                          value: '${(widget.weather.visibility / 1000).toStringAsFixed(1)} km',
                          label: 'Visibility',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Color> _gradientColors(String condition, bool isDark) {
    if (isDark) {
      switch (condition.toLowerCase()) {
        case 'clear':
          return [const Color(0xFF0B2A6E), const Color(0xFF1A3E9A)];
        case 'clouds':
          return [const Color(0xFF1A2744), const Color(0xFF2D3F66)];
        case 'rain':
        case 'drizzle':
          return [const Color(0xFF091C5E), const Color(0xFF122978)];
        case 'thunderstorm':
          return [const Color(0xFF180A42), const Color(0xFF2E126E)];
        case 'snow':
          return [const Color(0xFF102040), const Color(0xFF1A3566)];
        default:
          return [const Color(0xFF0D2060), const Color(0xFF1A3080)];
      }
    } else {
      switch (condition.toLowerCase()) {
        case 'clear':
          return [const Color(0xFF1A6EEB), const Color(0xFF38B8F5)];
        case 'clouds':
          return [const Color(0xFF4A6080), const Color(0xFF6E89A8)];
        case 'rain':
        case 'drizzle':
          return [const Color(0xFF1248A0), const Color(0xFF1E60C8)];
        case 'thunderstorm':
          return [const Color(0xFF2E0E7C), const Color(0xFF5B2DB0)];
        case 'snow':
          return [const Color(0xFF1A6EEB), const Color(0xFF60CDFF)];
        default:
          return [AppTheme.primaryBlue, AppTheme.lightBlue];
      }
    }
  }

  IconData _conditionIcon(String c) {
    switch (c.toLowerCase()) {
      case 'clear':
        return Icons.wb_sunny_rounded;
      case 'clouds':
        return Icons.cloud_rounded;
      case 'rain':
      case 'drizzle':
        return Icons.grain_rounded;
      case 'thunderstorm':
        return Icons.electric_bolt_rounded;
      case 'snow':
        return Icons.ac_unit_rounded;
      default:
        return Icons.wb_cloudy_rounded;
    }
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value, label;
  const _StatItem({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 0.8,
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(height: 7),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 11),
        ),
      ],
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 0.6,
      height: 44,
      color: Colors.white.withValues(alpha: 0.12),
    );
  }
}

class _PressableButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _PressableButton({required this.child, required this.onTap});

  @override
  State<_PressableButton> createState() => _PressableButtonState();
}

class _PressableButtonState extends State<_PressableButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
