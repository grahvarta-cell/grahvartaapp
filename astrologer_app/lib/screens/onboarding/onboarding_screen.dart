import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/app_theme.dart';
import '../auth/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingData {
  final String icon;
  final String title;
  final String subtitle;
  final List<String> symbols;
  final List<String> pills;

  const _OnboardingData({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.symbols,
    required this.pills,
  });
}

const _pages = [
  _OnboardingData(
    icon: '🔮',
    title: 'Share Your\nCosmic Wisdom',
    subtitle: 'Turn your astrology expertise into a thriving practice. Help seekers navigate life with your guidance on Grahvarta.',
    symbols: ['♈', '♉', '♊', '♋', '♌', '♍', '♎', '♏', '♐', '♑', '♒', '♓'],
    pills: ['Vedic', 'Tarot', 'Numerology', 'KP'],
  ),
  _OnboardingData(
    icon: '💬',
    title: 'Connect &\nConsult Instantly',
    subtitle: 'Receive consultation requests via live chat, voice, or video call. Set your own availability and earn on your schedule.',
    symbols: ['✨', '⭐', '🌙', '☀️', '💫', '🪐', '🌟', '⚡', '🔥', '💎', '🌈', '✦'],
    pills: ['Live Chat', 'Voice Call', 'Video Call'],
  ),
  _OnboardingData(
    icon: '💰',
    title: 'Grow Your\nAstrology Career',
    subtitle: 'Build your reputation, go live to reach thousands, earn per minute, and withdraw your earnings anytime.',
    symbols: ['🌕', '🌗', '🌑', '🌓', '☿', '♀', '♂', '♃', '♄', '⛎', '☽', '☿'],
    pills: ['Earn Per Minute', 'Go Live', 'Instant Withdrawal'],
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
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen(isAstrologerMode: true)));
  }

  List<Color> _gradientForPage(int index, bool isDark) {
    if (isDark) {
      const darkGradients = [
        [Color(0xFF2D1B00), Color(0xFF0D0D0D)],
        [Color(0xFF0D1A2D), Color(0xFF0D0D0D)],
        [Color(0xFF1A0D2D), Color(0xFF0D0D0D)],
      ];
      return darkGradients[index % darkGradients.length];
    } else {
      const lightGradients = [
        [Color(0xFFE8F4FF), Color(0xFFFFFFFF)],
        [Color(0xFFE0EEFF), Color(0xFFFFFFFF)],
        [Color(0xFFEEE8FF), Color(0xFFFFFFFF)],
      ];
      return lightGradients[index % lightGradients.length];
    }
  }

  Color _accentForPage(int index, BuildContext context) {
    if (index == 1) {
      return context.clr.accentAlt;
    } else if (index == 2) {
      return context.clr.accentAlt;
    }
    return context.clr.accent;
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = _gradientForPage(_currentPage, isDark);
    final accentColor = _accentForPage(_currentPage, context);

    return Scaffold(
      backgroundColor: context.clr.bg,
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradient,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              _BackgroundSymbols(symbols: page.symbols, rotation: _bgRotation, accentColor: accentColor),
              Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton(
                        onPressed: _finish,
                        child: Text('Skip', style: TextStyle(color: context.clr.txtMuted, fontSize: 14)),
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
                      itemBuilder: (ctx, i) {
                        final pageAccent = _accentForPage(i, ctx);
                        return _OnboardingPage(
                          data: _pages[i],
                          animController: _contentAnimController,
                          accentColor: pageAccent,
                        );
                      },
                    ),
                  ),
                  _BottomControls(
                    currentPage: _currentPage,
                    total: _pages.length,
                    accentColor: accentColor,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // In light mode use a darker shade of accent; in dark mode use accent directly
    final symbolColor = isDark ? accentColor : Color.lerp(accentColor, const Color(0xFF042B59), 0.4)!;
    return AnimatedBuilder(
      animation: rotation,
      builder: (_, __) => CustomPaint(
        size: MediaQuery.of(context).size,
        painter: _SymbolsPainter(symbols: symbols, rotation: rotation.value, color: symbolColor),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  final _OnboardingData data;
  final AnimationController animController;
  final Color accentColor;

  const _OnboardingPage({required this.data, required this.animController, required this.accentColor});

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
            _IconWidget(accentColor: accentColor, icon: data.icon),
            const SizedBox(height: 48),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.clr.txtPrimary,
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
              style: TextStyle(color: context.clr.txtSecondary, fontSize: 15, height: 1.6),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: data.pills.map((p) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Text(p, style: TextStyle(color: accentColor, fontSize: 12, fontWeight: FontWeight.w600)),
              )).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _IconWidget extends StatelessWidget {
  final Color accentColor;
  final String icon;
  const _IconWidget({required this.accentColor, required this.icon});

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
            border: Border.all(color: accentColor.withValues(alpha: 0.12), width: 1),
          ),
        ),
        Container(
          width: 132,
          height: 132,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: accentColor.withValues(alpha: 0.22), width: 1),
          ),
        ),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accentColor.withValues(alpha: 0.12),
            border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.25), blurRadius: 32, spreadRadius: 4)],
          ),
          child: Center(child: Text(icon, style: const TextStyle(fontSize: 44))),
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
                  color: isActive ? accentColor : context.clr.txtMuted.withValues(alpha: 0.35),
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
                boxShadow: [BoxShadow(color: accentColor.withValues(alpha: 0.4), blurRadius: 20, offset: const Offset(0, 8))],
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
              child: Text(
                'Already registered? Sign in',
                style: TextStyle(color: context.clr.txtMuted, fontSize: 13),
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
      final opacity = 0.15 + (i % 4) * 0.06;
      final fontSize = 12.0 + (i % 3) * 5;

      textPainter.text = TextSpan(
        text: symbols[i],
        style: TextStyle(fontSize: fontSize, color: color.withValues(alpha: opacity)),
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset(x - textPainter.width / 2, y - textPainter.height / 2));
    }
  }

  @override
  bool shouldRepaint(_SymbolsPainter old) => old.rotation != rotation || old.color != color;
}
