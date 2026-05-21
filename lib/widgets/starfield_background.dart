import 'dart:math';
import 'package:flutter/material.dart';

// ── Star data model ──────────────────────────────────────────────────────────
class _Star {
  double x;
  double y;
  double size;
  double speed;
  double opacity;
  double twinklePhase;
  double twinkleSpeed;

  _Star({
    required this.x,
    required this.y,
    required this.size,
    required this.speed,
    required this.opacity,
    required this.twinklePhase,
    required this.twinkleSpeed,
  });
}

// ── StarfieldBackground ──────────────────────────────────────────────────────
/// Renders an animated night-sky starfield behind any content.
/// Stars slowly drift upward and twinkle independently.
/// Wrap your screen content in this widget.
///
/// Usage:
///   StarfieldBackground(
///     child: YourScreenContent(),
///   )
class StarfieldBackground extends StatefulWidget {
  final Widget child;
  final List<Color> gradientColors;
  final int starCount;

  const StarfieldBackground({
    super.key,
    required this.child,
    this.gradientColors = const [
      Color(0xFF020818),
      Color(0xFF050D2A),
      Color(0xFF0A1545),
      Color(0xFF0D1B4B),
    ],
    this.starCount = 120,
  });

  @override
  State<StarfieldBackground> createState() => _StarfieldBackgroundState();
}

class _StarfieldBackgroundState extends State<StarfieldBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Star> _stars;
  final Random _rand = Random();

  @override
  void initState() {
    super.initState();
    _stars = [];

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();

    WidgetsBinding.instance.addPostFrameCallback((_) => _initStars());
  }

  void _initStars() {
    if (!mounted) return;
    final size = MediaQuery.of(context).size;
    _stars = List.generate(
      widget.starCount,
      (i) => _randomStar(size, init: true),
    );
    setState(() {});
  }

  _Star _randomStar(Size size, {bool init = false}) {
    return _Star(
      x: _rand.nextDouble() * size.width,
      y: init ? _rand.nextDouble() * size.height : size.height + 10,
      size: _rand.nextDouble() * 2.0 + 0.5,
      speed: _rand.nextDouble() * 0.12 + 0.03,
      opacity: _rand.nextDouble() * 0.5 + 0.3,
      twinklePhase: _rand.nextDouble() * 2 * pi,
      twinkleSpeed: _rand.nextDouble() * 0.04 + 0.01,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final size = MediaQuery.of(context).size;

        // Update stars each frame
        for (int i = 0; i < _stars.length; i++) {
          _stars[i].y -= _stars[i].speed;
          _stars[i].twinklePhase += _stars[i].twinkleSpeed;

          // Reset star to bottom when it leaves the top
          if (_stars[i].y < -5) {
            _stars[i] = _randomStar(size);
          }
        }

        return Stack(
          children: [
            // Deep space gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: widget.gradientColors,
                ),
              ),
            ),

            // Star layer
            CustomPaint(
              painter: _StarPainter(stars: _stars),
              size: Size.infinite,
            ),

            // Nebula glow effects
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF1A3A8A).withValues(alpha: 0.15),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 100,
              left: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF2A1A6A).withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Actual screen content on top
            widget.child,
          ],
        );
      },
    );
  }
}

// ── Star Painter ─────────────────────────────────────────────────────────────
class _StarPainter extends CustomPainter {
  final List<_Star> stars;

  const _StarPainter({required this.stars});

  @override
  void paint(Canvas canvas, Size size) {
    for (final star in stars) {
      final twinkle = (sin(star.twinklePhase) * 0.5 + 0.5);
      final opacity = (star.opacity * (0.5 + twinkle * 0.5)).clamp(0.0, 1.0);

      // Glow effect - outer soft circle
      final glowPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity * 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2);
      canvas.drawCircle(Offset(star.x, star.y), star.size * 2.5, glowPaint);

      // Core bright star dot
      final starPaint = Paint()
        ..color = Colors.white.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(Offset(star.x, star.y), star.size, starPaint);

      // Cross sparkle for larger stars
      if (star.size > 1.5 && twinkle > 0.7) {
        final sparklePaint = Paint()
          ..color = Colors.white.withValues(alpha: opacity * 0.6)
          ..strokeWidth = 0.8
          ..style = PaintingStyle.stroke;
        final s = star.size * 3;
        canvas.drawLine(
          Offset(star.x - s, star.y),
          Offset(star.x + s, star.y),
          sparklePaint,
        );
        canvas.drawLine(
          Offset(star.x, star.y - s),
          Offset(star.x, star.y + s),
          sparklePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_StarPainter old) => true;
}
