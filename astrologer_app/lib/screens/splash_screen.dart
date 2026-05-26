import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'auth/role_selection_screen.dart';
import 'onboarding/onboarding_screen.dart';
import 'astrologer/astrologer_main_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late final AnimationController _rotController;
  late final AnimationController _entryController;
  late final AnimationController _pulseController;

  late final Animation<double> _starsFade;
  late final Animation<double> _mandalaOpacity;
  late final Animation<double> _mandalaScale;
  late final Animation<double> _mandalaReveal;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _taglineFade;
  late final Animation<double> _dotsFade;

  late final List<_Star> _stars;

  @override
  void initState() {
    super.initState();

    final rng = Random();
    _stars = List.generate(45, (_) => _Star(
      x: rng.nextDouble(),
      y: rng.nextDouble(),
      size: rng.nextDouble() * 2.2 + 0.4,
      phase: rng.nextDouble() * 2 * pi,
    ));

    _rotController = AnimationController(vsync: this, duration: const Duration(seconds: 22))..repeat();

    _pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat();

    _entryController = AnimationController(vsync: this, duration: const Duration(milliseconds: 2400));

    _starsFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.0, 0.25, curve: Curves.easeIn)));

    _mandalaOpacity = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.08, 0.45, curve: Curves.easeOut)));

    _mandalaScale = Tween<double>(begin: 0.45, end: 1.0).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.08, 0.55, curve: Curves.elasticOut)));

    _mandalaReveal = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.12, 0.60, curve: Curves.easeOut)));

    _textFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.48, 0.72, curve: Curves.easeOut)));

    _textSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.48, 0.72, curve: Curves.easeOut)));

    _taglineFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.66, 0.86, curve: Curves.easeOut)));

    _dotsFade = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _entryController, curve: const Interval(0.80, 1.0, curve: Curves.easeOut)));

    _entryController.forward();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Start auth lookup in parallel with the animation
    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_done') ?? false;

    Widget? dest;
    if (!onboardingDone) {
      dest = const OnboardingScreen();
    } else {
      if (!mounted) return;
      final auth = context.read<AuthProvider>();
      final isLoggedIn = await auth.tryAutoLogin();
      if (!mounted) return;
      dest = !isLoggedIn
          ? const RoleSelectionScreen()
          : const AstrologerMainScreen();
    }

    // Always show splash for at least 3s total
    final elapsed = _entryController.lastElapsedDuration?.inMilliseconds ?? 0;
    final remaining = 3000 - elapsed;
    if (remaining > 0) await Future.delayed(Duration(milliseconds: remaining));

    if (!mounted) return;
    Navigator.pushReplacement(context, _fadeRoute(dest));
  }

  PageRoute _fadeRoute(Widget page) => PageRouteBuilder(
        pageBuilder: (_, __, ___) => page,
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      );

  @override
  void dispose() {
    _rotController.dispose();
    _entryController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedBuilder(
        animation: Listenable.merge([_entryController, _rotController, _pulseController]),
        builder: (_, __) => Stack(
          children: [
            // Deep radial glow that brightens as mandala reveals
            Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 0.9,
                  colors: [
                    AppColors.orange.withOpacity(0.10 * _mandalaOpacity.value),
                    AppColors.background,
                  ],
                ),
              ),
            ),

            // Twinkling stars
            Opacity(
              opacity: _starsFade.value,
              child: CustomPaint(
                size: size,
                painter: _StarsPainter(_stars, _pulseController.value),
              ),
            ),

            // Central content
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Mandala
                  Opacity(
                    opacity: _mandalaOpacity.value,
                    child: Transform.scale(
                      scale: _mandalaScale.value,
                      child: Transform.rotate(
                        angle: _rotController.value * 2 * pi,
                        child: CustomPaint(
                          size: const Size(150, 150),
                          painter: _MandalaPainter(_mandalaReveal.value),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // App name
                  FadeTransition(
                    opacity: _textFade,
                    child: SlideTransition(
                      position: _textSlide,
                      child: const Text(
                        'Grahvarta',
                        style: TextStyle(
                          fontFamily: 'CinzelDecorative',
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Tagline
                  Opacity(
                    opacity: _taglineFade.value,
                    child: const Text(
                      'YOUR COSMIC GUIDE',
                      style: TextStyle(
                        color: AppColors.gold,
                        fontSize: 11,
                        letterSpacing: 4,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),

                  const SizedBox(height: 56),

                  // Pulsing dots loader
                  Opacity(
                    opacity: _dotsFade.value,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final t = (_pulseController.value + i / 3) % 1.0;
                        final opacity = (sin(t * 2 * pi) * 0.45 + 0.55);
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withOpacity(opacity),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stars ────────────────────────────────────────────────────────────────────

class _Star {
  final double x, y, size, phase;
  const _Star({required this.x, required this.y, required this.size, required this.phase});
}

class _StarsPainter extends CustomPainter {
  final List<_Star> stars;
  final double tick;
  const _StarsPainter(this.stars, this.tick);

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in stars) {
      final brightness = sin(tick * 2 * pi + s.phase) * 0.45 + 0.55;
      canvas.drawCircle(
        Offset(s.x * size.width, s.y * size.height),
        s.size,
        Paint()..color = Colors.white.withOpacity(brightness * 0.65),
      );
    }
  }

  @override
  bool shouldRepaint(_StarsPainter old) => old.tick != tick;
}

// ── Mandala ──────────────────────────────────────────────────────────────────

class _MandalaPainter extends CustomPainter {
  final double reveal; // 0..1
  const _MandalaPainter(this.reveal);

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    // Soft outer glow
    canvas.drawCircle(
      c,
      r * 0.92,
      Paint()
        ..color = AppColors.orange.withOpacity(0.12 * reveal)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );

    // Concentric rings drawn as arcs (reveal 0→1)
    _drawArc(canvas, c, r * 0.90, AppColors.orange.withOpacity(0.9), 1.6, reveal);
    _drawArc(canvas, c, r * 0.70, AppColors.gold.withOpacity(0.55), 1.0, reveal);
    _drawArc(canvas, c, r * 0.50, AppColors.orange.withOpacity(0.35), 0.8, reveal);

    // 12 spokes (zodiac-style), each extending progressively
    for (int i = 0; i < 12; i++) {
      final angle = i * pi / 6;
      final spokeReveal = ((reveal * 14) - i).clamp(0.0, 1.0);
      if (spokeReveal <= 0) continue;

      final inner = Offset(c.dx + r * 0.50 * cos(angle), c.dy + r * 0.50 * sin(angle));
      final outer = Offset(c.dx + r * 0.90 * cos(angle), c.dy + r * 0.90 * sin(angle));
      final tip = Offset.lerp(inner, outer, spokeReveal)!;

      canvas.drawLine(
        inner,
        tip,
        Paint()
          ..color = AppColors.orange.withOpacity(0.28 * spokeReveal)
          ..strokeWidth = 0.9
          ..strokeCap = StrokeCap.round,
      );

      // Small dot at the outer ring junction
      if (spokeReveal > 0.85) {
        canvas.drawCircle(
          outer,
          2.2,
          Paint()..color = AppColors.orange.withOpacity(0.85 * ((spokeReveal - 0.85) / 0.15)),
        );
      }
    }

    // Center radial gradient fill
    if (reveal > 0) {
      final cr = r * 0.28 * reveal;
      canvas.drawCircle(
        c,
        cr,
        Paint()
          ..shader = RadialGradient(colors: [
            AppColors.orange.withOpacity(0.85),
            AppColors.orange.withOpacity(0.0),
          ]).createShader(Rect.fromCircle(center: c, radius: cr)),
      );
    }

    // 8-point star burst (appears last)
    if (reveal > 0.65) {
      final burst = ((reveal - 0.65) / 0.35).clamp(0.0, 1.0);
      _drawStarBurst(canvas, c, r * 0.18 * burst, AppColors.gold.withOpacity(0.9 * burst));
    }
  }

  void _drawArc(Canvas canvas, Offset center, double radius, Color color, double strokeWidth, double progress) {
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawStarBurst(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 8; i++) {
      final a = i * pi / 4;
      canvas.drawLine(
        Offset(center.dx + radius * 0.25 * cos(a), center.dy + radius * 0.25 * sin(a)),
        Offset(center.dx + radius * cos(a), center.dy + radius * sin(a)),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_MandalaPainter old) => old.reveal != reveal;
}
