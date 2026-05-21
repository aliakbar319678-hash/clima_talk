import 'dart:math';
import 'package:flutter/material.dart';

// ─── Dynamic Atmospheric Background ──────────────────────────────────────────
// This widget provides a live, immersive background that adapts to the app's 
// theme. It uses CustomPainters to render high-performance animations like 
// moving clouds, twinkling stars, and light rays.
class AnimatedBackground extends StatefulWidget {
  final bool isDark;
  final Widget child;

  const AnimatedBackground({
    super.key,
    required this.isDark,
    required this.child,
  });

  @override
  State<AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<AnimatedBackground>
    with TickerProviderStateMixin {
  // Animation controllers for the various atmospheric elements
  late AnimationController _cloudController;
  late AnimationController _starController;
  late AnimationController _glowController;
  late AnimationController _particleController;

  // Data structures for storing randomized element positions
  final List<_StarParticle> _stars = [];
  final List<_CloudData> _clouds = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    // Configure loop timings for different animation layers
    _cloudController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 30),
    )..repeat();

    _starController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();

    // Initial randomized generation of background assets
    _generateStars();
    _generateClouds();
  }

  // Pre-generates randomized star positions and sizes for the night theme
  void _generateStars() {
    _stars.clear();
    for (int i = 0; i < 80; i++) {
      _stars.add(
        _StarParticle(
          x: _random.nextDouble(),
          y: _random.nextDouble(),
          size: _random.nextDouble() * 2.5 + 0.5,
          twinkleOffset: _random.nextDouble(),
          speed: _random.nextDouble() * 0.3 + 0.1,
        ),
      );
    }
  }

  // Pre-generates randomized cloud properties for the day theme
  void _generateClouds() {
    _clouds.clear();
    for (int i = 0; i < 5; i++) {
      _clouds.add(
        _CloudData(
          startX: _random.nextDouble(),
          y: _random.nextDouble() * 0.5,
          scale: _random.nextDouble() * 0.6 + 0.5,
          speed: _random.nextDouble() * 0.2 + 0.05,
          opacity: _random.nextDouble() * 0.3 + 0.15,
        ),
      );
    }
  }

  @override
  void dispose() {
    _cloudController.dispose();
    _starController.dispose();
    _glowController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // ─── Base Atmosphere Layer ────────────────────────────────────────────
        // Smooth color transition between day and night gradients.
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 800),
            decoration: BoxDecoration(
              gradient: widget.isDark
                  ? const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF020B18),
                        Color(0xFF0A1628),
                        Color(0xFF0D1F3C),
                        Color(0xFF071422),
                      ],
                      stops: [0.0, 0.3, 0.7, 1.0],
                    )
                  : const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4FC3F7), // Deep sky blue
                        Color(0xFF81D4FA), // Light sky blue
                        Color(0xFFFFE082), // Sunny yellow tint at bottom
                        Color(0xFFE3F2FD), // Soft white blue
                      ],
                      stops: [0.0, 0.4, 0.8, 1.0],
                    ),
            ),
          ),
        ),

        // ─── Celestial Layers ─────────────────────────────────────────────────
        
        // Night Theme: Stars & Constellations
        if (widget.isDark)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _starController,
                  _particleController,
                ]),
                builder: (context, _) {
                  return CustomPaint(
                    painter: _StarsPainter(
                      stars: _stars,
                      twinkleValue: _starController.value,
                      particleProgress: _particleController.value,
                    ),
                  );
                },
              ),
            ),
          ),

        // Night Theme: Lunar Glow
        if (widget.isDark)
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Positioned(
                top: -80 + _glowController.value * 20,
                right: -60,
                child: RepaintBoundary(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(
                            0xFF1E3A5F,
                          ).withValues(alpha: 0.3 + _glowController.value * 0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // Day Theme: Solar Glow
        if (!widget.isDark)
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Positioned(
                top: -60,
                right: -40,
                child: RepaintBoundary(
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.yellow.withValues(
                            alpha: 0.4 + _glowController.value * 0.2,
                          ),
                          Colors.orange.withValues(
                            alpha: 0.15 + _glowController.value * 0.1,
                          ),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // Day Theme: Dynamic Sun Rays
        if (!widget.isDark)
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, _) {
              return Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _SunRaysPainter(
                      opacity: 0.08 + _glowController.value * 0.05,
                      rotation: _glowController.value * 0.1,
                    ),
                  ),
                ),
              );
            },
          ),

        // Day Theme: Drifting Clouds
        if (!widget.isDark)
          Positioned.fill(
            child: RepaintBoundary(
              child: AnimatedBuilder(
                animation: _cloudController,
                builder: (context, _) {
                  return CustomPaint(
                    painter: _CloudsPainter(
                      clouds: _clouds,
                      progress: _cloudController.value,
                    ),
                  );
                },
              ),
            ),
          ),

        // Primary App Content (placed on top of background layers)
        widget.child,
      ],
    );
  }
}

// ─── Painting Logic Components ───────────────────────────────────────────────

class _StarParticle {
  final double x, y, size, twinkleOffset, speed;
  _StarParticle({required this.x, required this.y, required this.size, required this.twinkleOffset, required this.speed});
}

class _CloudData {
  final double startX, y, scale, speed, opacity;
  _CloudData({required this.startX, required this.y, required this.scale, required this.speed, required this.opacity});
}

// Renders twinkling stars and occasional shooting stars for night mode.
class _StarsPainter extends CustomPainter {
  final List<_StarParticle> stars;
  final double twinkleValue;
  final double particleProgress;

  _StarsPainter({required this.stars, required this.twinkleValue, required this.particleProgress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle = (sin((twinkleValue + star.twinkleOffset) * pi * 2) + 1) / 2;
      final opacity = 0.3 + twinkle * 0.7;

      final driftX = sin(particleProgress * pi * 2 * star.speed + star.x * 10) * 3;
      final driftY = cos(particleProgress * pi * 2 * star.speed + star.y * 10) * 2;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      final cx = star.x * size.width + driftX;
      final cy = star.y * size.height + driftY;
      canvas.drawCircle(Offset(cx, cy), star.size, paint);

      if (star.size > 1.8) {
        final glowPaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(cx, cy), star.size * 2.5, glowPaint);
      }
    }

    // Occasional shooting star implementation
    final shootingProgress = (particleProgress * 3) % 1.0;
    if (shootingProgress < 0.15) {
      final normalizedProgress = shootingProgress / 0.15;
      final startX = size.width * 0.8;
      final startY = size.height * 0.1;
      final endX = startX - 120 * normalizedProgress;
      final endY = startY + 60 * normalizedProgress;

      final shootPaint = Paint()
        ..color = Colors.white.withValues(alpha: (1 - normalizedProgress) * 0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), shootPaint);
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) =>
      twinkleValue != old.twinkleValue || particleProgress != old.particleProgress;
}

// Renders realistic drifting clouds for day mode.
class _CloudsPainter extends CustomPainter {
  final List<_CloudData> clouds;
  final double progress;

  _CloudsPainter({required this.clouds, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    for (final cloud in clouds) {
      final x = (cloud.startX + progress * cloud.speed) % 1.3 - 0.15;
      final y = cloud.y;

      final paint = Paint()
        ..color = Colors.white.withValues(alpha: cloud.opacity)
        ..style = PaintingStyle.fill;

      final cx = x * size.width;
      final cy = y * size.height;
      _drawCloud(canvas, paint, cx, cy, cloud.scale);
    }
  }

  void _drawCloud(Canvas canvas, Paint paint, double cx, double cy, double scale) {
    final s = scale * 50;
    canvas.drawCircle(Offset(cx, cy), s * 0.6, paint);
    canvas.drawCircle(Offset(cx + s * 0.5, cy + s * 0.1), s * 0.5, paint);
    canvas.drawCircle(Offset(cx - s * 0.5, cy + s * 0.1), s * 0.45, paint);
    canvas.drawCircle(Offset(cx + s * 0.9, cy + s * 0.3), s * 0.4, paint);
    canvas.drawCircle(Offset(cx - s * 0.9, cy + s * 0.3), s * 0.35, paint);

    final rect = Rect.fromLTWH(cx - s, cy + s * 0.1, s * 2, s * 0.5);
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(_CloudsPainter old) => progress != old.progress;
}

// Renders rotating light rays from the sun in day mode.
class _SunRaysPainter extends CustomPainter {
  final double opacity;
  final double rotation;

  _SunRaysPainter({required this.opacity, this.rotation = 0});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..strokeWidth = 2;

    canvas.save();
    canvas.translate(size.width * 0.9, 0);
    canvas.rotate(rotation);

    for (int i = 0; i < 12; i++) {
      final angle = (i / 12) * pi * 2;
      final endX = cos(angle) * 300;
      final endY = sin(angle) * 400;
      canvas.drawLine(Offset.zero, Offset(endX, endY), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_SunRaysPainter old) =>
      opacity != old.opacity || rotation != old.rotation;
}

