import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/forecast_model.dart';
import '../widgets/animated_background.dart';

class HourlyForecastScreen extends StatelessWidget {
  final String cityName;
  final DateTime selectedDay;
  final List<ForecastDayModel> hourlyData;

  const HourlyForecastScreen({
    super.key,
    required this.cityName,
    required this.selectedDay,
    required this.hourlyData,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dayData = hourlyData.where((h) {
      return h.date.year == selectedDay.year &&
          h.date.month == selectedDay.month &&
          h.date.day == selectedDay.day;
    }).toList();

    return AnimatedBackground(
      isDark: isDark,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: Column(
            children: [
              Text(
                cityName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                DateFormat('EEEE, MMM d').format(selectedDay),
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              ),
            ],
          ),
        ),
        body: dayData.isEmpty
            ? const Center(
                child: Text('No hourly data available for this day.'),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildMainStat(dayData),
                    const SizedBox(height: 40),
                    _HourlyChart(dayData: dayData),
                    const SizedBox(height: 40),
                    _buildHourlyList(dayData),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildMainStat(List<ForecastDayModel> data) {
    final avgTemp =
        data.map((e) => e.tempDay).reduce((a, b) => a + b) / data.length;
    final condition = data[data.length ~/ 2].condition;

    return Column(
      children: [
        Text(
          '${avgTemp.round()}°C',
          style: const TextStyle(
            fontSize: 64,
            fontWeight: FontWeight.w900,
            color: Colors.white,
            shadows: [
              Shadow(
                color: Colors.black26,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
        ),
        Text(
          condition,
          style: const TextStyle(
            fontSize: 20,
            color: Colors.white70,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildHourlyList(List<ForecastDayModel> data) {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: data.length,
        itemBuilder: (context, index) {
          final item = data[index];
          final isNight = item.date.hour < 6 || item.date.hour > 18;

          return Container(
            width: 70,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  DateFormat('HH:mm').format(item.date),
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
                const SizedBox(height: 8),
                Icon(
                  isNight ? Icons.nightlight_round : Icons.wb_sunny_rounded,
                  color: isNight ? Colors.indigoAccent : Colors.orangeAccent,
                  size: 24,
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.tempDay.round()}°',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _HourlyChart extends StatefulWidget {
  final List<ForecastDayModel> dayData;
  const _HourlyChart({required this.dayData});

  @override
  State<_HourlyChart> createState() => _HourlyChartState();
}

class _HourlyChartState extends State<_HourlyChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white10),
      ),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          return CustomPaint(
            painter: _ChartPainter(data: widget.dayData, progress: _ctrl.value),
          );
        },
      ),
    );
  }
}

class _ChartPainter extends CustomPainter {
  final List<ForecastDayModel> data;
  final double progress;

  _ChartPainter({required this.data, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    // Use explicit reduction to avoid ambiguity or typing issues
    final double minTemp = data
        .map((e) => e.tempDay)
        .reduce((a, b) => a < b ? a : b);
    final double maxTemp = data
        .map((e) => e.tempDay)
        .reduce((a, b) => a > b ? a : b);
    final double range = (maxTemp - minTemp).abs();
    final double displayRange = range < 1.0 ? 1.0 : range;

    final List<Offset> points = [];
    final int len = data.length;
    final double stepX = len > 1 ? size.width / (len - 1) : size.width;

    for (int i = 0; i < len; i++) {
      final double x = i * stepX;
      final double normalizedTemp = (data[i].tempDay - minTemp) / displayRange;
      final double y =
          size.height -
          (normalizedTemp * size.height * 0.6 + size.height * 0.2);
      points.add(Offset(x, y));
    }

    if (points.isEmpty) return;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);

    if (len > 1) {
      for (int i = 0; i < points.length - 1; i++) {
        final p1 = points[i];
        final p2 = points[i + 1];
        final controlPoint1 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p1.dy);
        final controlPoint2 = Offset(p1.dx + (p2.dx - p1.dx) / 2, p2.dy);
        path.cubicTo(
          controlPoint1.dx,
          controlPoint1.dy,
          controlPoint2.dx,
          controlPoint2.dy,
          p2.dx,
          p2.dy,
        );
      }
    } else {
      path.lineTo(size.width, points[0].dy);
    }

    // Path Metric for animation
    final pathMetrics = path.computeMetrics().toList();
    if (pathMetrics.isEmpty) return;

    final metric = pathMetrics.first;
    final extractPath = metric.extractPath(0, metric.length * progress);

    // Draw Area Gradient
    final fillPath = Path.from(extractPath);
    if (points.isNotEmpty) {
      final int lastIndex = min(
        points.length - 1,
        (progress * (points.length - 1)).floor(),
      );
      fillPath.lineTo(points[lastIndex].dx, size.height);
      fillPath.lineTo(0, size.height);
      fillPath.close();

      final fillPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFFFF9800).withValues(alpha: 0.3 * progress),
            const Color(0xFF2196F3).withValues(alpha: 0.1 * progress),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

      canvas.drawPath(fillPath, fillPaint);
    }

    // Draw Gradient Line
    final linePaint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF2196F3), Color(0xFFFF9800), Color(0xFFF44336)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(extractPath, linePaint);

    // Draw Data Points
    for (int i = 0; i < points.length; i++) {
      final pointProgress = points.length > 1 ? i / (points.length - 1) : 1.0;
      if (progress >= pointProgress) {
        final p = points[i];
        final temp = data[i].tempDay.round();
        final hour = data[i].date.hour;
        final isNight = hour < 6 || hour > 18;

        // Outer Glow
        canvas.drawCircle(
          p,
          8,
          Paint()
            ..color = (isNight ? Colors.indigo : Colors.orange).withValues(alpha: 0.3),
        );
        // Inner Dot
        canvas.drawCircle(p, 4, Paint()..color = Colors.white);

        // Temp Label
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$temp°',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(p.dx - textPainter.width / 2, p.dy - 25),
        );

        // Mini Icon (Sun/Moon)
        final icon = isNight
            ? Icons.nights_stay_rounded
            : Icons.wb_sunny_rounded;
        final iconPainter = TextPainter(
          text: TextSpan(
            text: String.fromCharCode(icon.codePoint),
            style: TextStyle(
              fontSize: 14,
              fontFamily: icon.fontFamily,
              package: icon.fontPackage,
              color: isNight
                  ? const Color(0xFF7986CB)
                  : const Color(0xFFFFF176),
            ),
          ),
          textDirection: ui.TextDirection.ltr,
        )..layout();
        iconPainter.paint(
          canvas,
          Offset(p.dx - iconPainter.width / 2, p.dy + 12),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_ChartPainter old) => progress != old.progress;
}
