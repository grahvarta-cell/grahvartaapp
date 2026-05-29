import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'login_screen.dart';

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.6,
            colors: [const Color(0xFF1A0A00), context.clr.bg],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                // Logo / header
                Container(
                  width: 72, height: 72,
                  decoration: BoxDecoration(
                    color: context.clr.accent.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: context.clr.accent.withValues(alpha: 0.3), width: 2),
                  ),
                  child: Icon(Icons.auto_awesome, color: context.clr.accent, size: 32),
                ),
                const SizedBox(height: 24),
                Text(
                  'Welcome to Grahvarta',
                  style: TextStyle(color: context.clr.txtPrimary, fontSize: 28, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  'How would you like to continue?',
                  style: TextStyle(color: context.clr.txtSecondary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const Spacer(),
                // User card
                _RoleCard(
                  icon: Icons.person_rounded,
                  title: 'Continue as User',
                  subtitle: 'Get horoscopes, consult astrologers,\nexplore live sessions & reports',
                  color: context.clr.accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen(isAstrologerMode: false)),
                  ),
                ),
                const SizedBox(height: 16),
                // Astrologer card
                _RoleCard(
                  icon: Icons.star_rounded,
                  title: 'Join as Astrologer',
                  subtitle: 'Accept consultations, go live,\nearn per minute & grow your brand',
                  color: const Color(0xFFFFD700),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen(isAstrologerMode: true)),
                  ),
                ),
                const Spacer(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: context.clr.txtPrimary, fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.4)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.7)),
          ],
        ),
      ),
    );
  }
}
