// ─── splash_screen.dart ───────────────────────────────────────────────────────
// The Splash Screen is the FIRST screen the user sees when launching the app.
// Its job is to:
//   1. Show an animated branding sequence (logo + app name + tagline)
//   2. Auto-navigate to the HomeScreen after 3 seconds
//
// Animation Structure (sequential, then parallel):
//   - Logo fades in + scales up with elasticOut curve (bouncy)
//   - After logo finishes, text slides up + fades in
//   - Orbiting ring animations run independently in parallel (infinite loop)
//   - Three pulsing dots appear with staggered delay for a loading feel

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


import 'home_screen.dart';

// ─── SplashScreen Widget ──────────────────────────────────────────────────────
// ConsumerStatefulWidget is used because this screen needs both:
//   - State (for AnimationControllers)
//   - ref (from Riverpod, in case providers need to be accessed)
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

// ─── _SplashScreenState ───────────────────────────────────────────────────────
// TickerProviderStateMixin is required for AnimationController — it provides
// the "vsync" (vertical sync) that ties animations to screen refresh rate.
class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // AnimationControllers drive the timing of each animation.
  late AnimationController _logoCtrl;   // Controls logo fade+scale timing
  late AnimationController _textCtrl;   // Controls text slide+fade timing
  late AnimationController _orbitCtrl;  // Controls the infinite orbit rotation

  // Animation objects define the VALUE produced at each point in time.
  late Animation<double> _fadeAnim;    // 0.0 (invisible) → 1.0 (visible)
  late Animation<double> _scaleAnim;   // 0.4 (small) → 1.0 (full size)
  late Animation<Offset> _slideAnim;  // Offset(0, 0.3) → Offset.zero (slides up)

  @override
  void initState() {
    super.initState();

    // ─── Create Animation Controllers ────────────────────────────────────────
    // Duration controls how long each phase of the animation takes.
    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // Logo takes 1.2 seconds
    );
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),  // Text takes 0.9 seconds
    );
    _orbitCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),          // Full orbit takes 8 seconds
    )..repeat(); // ..repeat() makes it loop infinitely automatically

    // ─── Define Animation Values ──────────────────────────────────────────────
    // CurvedAnimation wraps a controller with an easing curve for natural motion.
    // Curves.elasticOut creates a bouncy "spring" effect perfect for logos.
    _fadeAnim = Tween<double>(
      begin: 0,  // Start fully invisible
      end: 1,    // End fully visible
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.easeOut));
    _scaleAnim = Tween<double>(
      begin: 0.4,  // Start at 40% of final size
      end: 1.0,    // End at 100% size
    ).animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.3),  // Start 30% below final position
      end: Offset.zero,              // End at natural position
    ).animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    // ─── Chain Animations ─────────────────────────────────────────────────────
    // Logo animation plays first, THEN text animation starts once logo finishes.
    // .forward() starts the animation, .then() chains a callback on completion.
    _logoCtrl.forward().then((_) => _textCtrl.forward());

    // ─── Auto-Navigate After 3 Seconds ───────────────────────────────────────
    // After 3 seconds, navigate to HomeScreen using a custom fade transition.
    // 'mounted' check prevents errors if the widget was disposed before the timer fired.
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.pushReplacement(context, _fadeRoute(const HomeScreen()));
      }
    });
  }

  @override
  void dispose() {
    // IMPORTANT: Always dispose AnimationControllers to prevent memory leaks.
    // Failing to do this is a common Flutter bug that wastes memory and CPU.
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _orbitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Auth check removed to bypass login

    return Scaffold(
      backgroundColor: Colors.transparent, // The animated background shows through
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ─── Logo Section (Orbiting Rings + Cloud Icon) ───────────────────
            // FadeTransition uses _fadeAnim to fade the entire logo section in.
            FadeTransition(
              opacity: _fadeAnim,
              // ScaleTransition uses _scaleAnim to grow the logo from small to full size.
              child: ScaleTransition(
                scale: _scaleAnim,
                child: SizedBox(
                  width: 180,
                  height: 180,
                  // Stack layers multiple elements on top of each other:
                  // Outer ring → Inner ring → Core logo icon
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // ─── Orbit Ring 1 (clockwise) ─────────────────────────
                      // AnimatedBuilder rebuilds this widget every animation frame.
                      // _orbitCtrl.value goes from 0.0 to 1.0 over 8 seconds.
                      AnimatedBuilder(
                        animation: _orbitCtrl,
                        builder: (context, child) => Transform.rotate(
                          // Multiply by 2π to get a full 360° rotation per loop.
                          angle: _orbitCtrl.value * 2 * pi,
                          child: Container(
                            width: 170,
                            height: 170,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF4FC3F7).withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            // A small dot positioned on the right edge of the ring.
                            // When the ring rotates, this dot appears to orbit the center.
                            child: Align(
                              alignment: const Alignment(1, 0),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4FC3F7),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ─── Orbit Ring 2 (counter-clockwise, slower) ─────────
                      // Negative angle = counter-clockwise rotation.
                      // * 0.7 makes it 70% as fast as the outer ring.
                      AnimatedBuilder(
                        animation: _orbitCtrl,
                        builder: (context, child) => Transform.rotate(
                          angle: -_orbitCtrl.value * 2 * pi * 0.7,
                          child: Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: const Color(0xFF7C4DFF).withValues(alpha: 0.25),
                                width: 1,
                              ),
                            ),
                            child: Align(
                              alignment: const Alignment(0, -1),
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF7C4DFF),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // ─── Core Logo Container ──────────────────────────────
                      // The central gradient box with the cloud icon.
                      // Uses a linear gradient from blue to purple for a premium look.
                      Container(
                        width: 90,
                        height: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(26),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A6EEB), Color(0xFF5B4DFF)],
                          ),
                          border: Border.all(
                            color: const Color(0xFF4FC3F7).withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: const Icon(
                          Icons.cloud_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // ─── App Name + Tagline ────────────────────────────────────────────
            // SlideTransition moves the text from below up to its natural position.
            // FadeTransition fades it in simultaneously.
            SlideTransition(
              position: _slideAnim,
              child: FadeTransition(
                opacity: _textCtrl,
                child: Column(
                  children: [
                    const Text(
                      'ClimaTalk',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Smart AI Weather Companion',
                      style: TextStyle(
                        color: const Color(0xFF4FC3F7).withValues(alpha: 0.9),
                        fontSize: 14,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 64),

            // ─── Pulsing Loading Dots ─────────────────────────────────────────
            // Fades in with the text animation, then shows 3 staggered pulsing dots.
            FadeTransition(opacity: _textCtrl, child: const _PulseDots()),
          ],
        ),
      ),
    );
  }

  // ─── Custom Fade Route ────────────────────────────────────────────────────
  // Creates a page transition that fades out the splash screen and fades in
  // the home screen. Much smoother than the default slide transition.
  PageRoute _fadeRoute(Widget screen) => PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, anim, secondaryAnimation, child) =>
        FadeTransition(opacity: anim, child: child),
    transitionDuration: const Duration(milliseconds: 500),
  );
}

// ─── _PulseDots Widget ────────────────────────────────────────────────────────
// A private widget that renders three pulsing dots as a loading indicator.
// Each dot independently fades in and out, with a staggered start delay.
class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots> with TickerProviderStateMixin {
  late List<AnimationController> _ctrls; // One controller per dot (3 total)
  late List<Animation<double>> _anims;   // One opacity animation per dot

  @override
  void initState() {
    super.initState();
    // Create 3 controllers, one for each dot.
    _ctrls = List.generate(
      3,
      (i) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 700), // Each pulse takes 0.7 seconds
      ),
    );
    // Create a 0.2 → 1.0 opacity animation for each controller.
    // 0.2 means the dot never fully disappears — it stays faintly visible.
    _anims = _ctrls
        .map(
          (c) => Tween<double>(
            begin: 0.2,
            end: 1.0,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)),
        )
        .toList();
    // Start each dot with a staggered delay (0ms, 200ms, 400ms).
    // This creates the "wave" effect where dots pulse one after another.
    // repeat(reverse: true) makes each dot pulse from dim to bright and back.
    for (int i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 200), () {
        if (mounted) _ctrls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    // Dispose all 3 controllers to prevent memory leaks.
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Render 3 dots in a row, each controlled by its own FadeTransition.
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => FadeTransition(
          opacity: _anims[i],
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: Color(0xFF4FC3F7), // Neon blue dots
              shape: BoxShape.circle,
            ),
          ),
        ),
      ),
    );
  }
}
