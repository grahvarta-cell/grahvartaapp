import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../auth/role_selection_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingData {
  final String icon;
  final String title;
  final String subtitle;
  final List<Color> gradient;
  final Color accentColor;
  final List<String> symbols;
  final List<String> pills;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.accentColor,
    required this.symbols,
    required this.pills,
  });
}

const _pages = [
  _OnboardingData(
    icon: '🔮',
    title: 'Discover Your\nCosmic Path',
    subtitle: 'Get personalized horoscopes, birth chart readings, and daily predictions tailored to your unique celestial blueprint.',
    gradient: [Color(0xFF2D1B00), Color(0xFF0D0D0D)],
    accentColor: AppColors.orange,
    symbols: ['♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'],
    pills: ['Daily Horoscope', 'Birth Chart', 'Compatibility'],
  ),
  _OnboardingData(
    icon: '🌟',
    title: 'Talk to Expert\nAstrologers',
    subtitle: 'Connect instantly with 500+ verified astrologers via live chat, voice, or video call. First 3 minutes free!',
    gradient: [Color(0xFF0D1A2D), Color(0xFF0D0D0D)],
    accentColor: Color(0xFF4A9EFF),
    symbols: ['✨', '⭐', '🌙', '☀️', '💫', '🪐', '🌟', '⚡', '🔥', '💎', '🌈', '✦'],
    pills: ['500+ Astrologers', 'Live Chat', 'Voice & Video'],
  ),
  _OnboardingData(
    icon: '💫',
    title: 'Live, Learn &\nGrow Together',
    subtitle: 'Join live astrology sessions, explore cosmic events, and become part of a thriving spiritual community.',
    gradient: [Color(0xFF1A0D2D), Color(0xFF0D0D0D)],
    accentColor: AppColors.gold,
    symbols: ['🌕', '🌗', '🌑', '🌓', '☿', '♀', '♂', '♃', '♄', '⛎', '☽', '☿'],
    pills: ['Live Sessions', 'Community', 'Cosmic Events'],
  ),
];

class _OnboardingScreenState extends State<OnboardingScreen> with TickerProviderStateMixin {
  final _pageController = PageController();
  late AnimationController _bgAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _bgRotation;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _bgAnimController = AnimationController(vsync: this, duration: const Duration(seconds: 20))..repeat();
    _contentAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _bgRotation = Tween<double>(begin: 0, end: 2 * pi).animate(_bgAnimController);
    _contentAnimController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _bgAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const RoleSelectionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: page.gradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _BackgroundSymbols(symbols: page.symbols, rotation: _bgRotation, accentColor: page.accentColor),
              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: _finish,
                        child: const Text('Skip', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                      ),
                    ),
                  ),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (i) {
                        setState(() => _currentPage = i);
                        _contentAnimController.forward(from: 0);
                      },
                      itemCount: _pages.length,
                      itemBuilder: (_, i) => _OnboardingPage(data: _pages[i], animController: _contentAnimController),
                    ),
                  ),
                  _BottomControls(
                    currentPage: _currentPage,
                    total: _pages.length,
                    accentColor: page.accentColor,
                    onNext: _nextPage,
                    onSkip: _finish,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BackgroundSymbols extends StatelessWidget {
  final List<String> symbols;
  final Animation<double> rotation;
  final Color accentColor;

  const _BackgroundSymbols({required this.symbols, required this.rotation, required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: rotation,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _SymbolsPainter(symbols: symbols, rotation: rotation.value, color: accentColor),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final AnimationController animController;

  const _OnboardingPage({required this.data, required this.animController});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animController,
      builder: (_, child) => FadeTransition(
        opacity: CurvedAnimation(parent: animController, curve: Curves.easeOut),
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
              .animate(CurvedAnimation(parent: animController, curve: Curves.easeOut)),
          child: child,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _IconWidget(data: data),
            const SizedBox(height: 48),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 30,
                fontWeight: FontWeight.w800,
                height: 1.2,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              data.subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: data.pills.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: data.accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: data.accentColor.withOpacity(0.3)),
                ),
                child: Text(p, style: TextStyle(color: data.accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconWidget extends StatelessWidget {
  final _OnboardingData data;
  const _IconWidget({required this.data});

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 168,
          height: 168,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: data.accentColor.withOpacity(0.12), width: 1),
          ),
        ),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: data.accentColor.withOpacity(0.22), width: 1),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: data.accentColor.withOpacity(0.12),
            border: Border.all(color: data.accentColor.withOpacity(0.4), width: 1.5),
            boxShadow: [BoxShadow(color: data.accentColor.withOpacity(0.25), blurRadius: 32, spreadRadius: 4)],
          ),
          child: Center(child: Text(data.icon, style: const TextStyle(fontSize: 44))),
        ),
      ],
    );
  }
}

class _BottomControls extends StatelessWidget {
  final int currentPage;
  final int total;
  final Color accentColor;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  const _BottomControls({
    required this.currentPage,
    required this.total,
    required this.accentColor,
    required this.onNext,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    final isLast = currentPage == total - 1;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(total, (i) {
              final isActive = i == currentPage;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: isActive ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: isActive ? accentColor : AppColors.textMuted.withOpacity(0.35),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            }),
          ),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: onNext,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                color: accentColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: accentColor.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Center(
                child: Text(
                  isLast ? 'Get Started  →' : 'Continue  →',
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                ),
              ),
            ),
          ),
          if (!isLast) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onSkip,
              child: const Text(
                'Already have an account? Sign in',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SymbolsPainter extends CustomPainter {
  final List<String> symbols;
  final double rotation;
  final Color color;

  _SymbolsPainter({required this.symbols, required this.rotation, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < symbols.length; i++) {
      final angle = rotation + (i * 2 * pi / symbols.length);
      final radiusX = size.width * 0.42;
      final radiusY = size.height * 0.38;
      final x = size.width / 2 + cos(angle) * radiusX;
      final y = size.height / 2 + sin(angle) * radiusY;
      final opacity = 0.05 + (i % 4) * 0.015;
      final fontSize = 12.0 + (i % 3) * 5;

      textPainter.text = TextSpan(
        text: symbols[i],
        style: TextStyle(fontSize: fontSize, color: color.withOpacity(opacity)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_SymbolsPainter old) => old.rotation != rotation || old.color != color;
}
