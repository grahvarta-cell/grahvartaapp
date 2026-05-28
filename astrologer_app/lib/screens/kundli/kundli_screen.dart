import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'free_kundli_screen.dart';
import 'kundli_matching_screen.dart';
import 'compatibility_screen.dart';

class KundliScreen extends StatelessWidget {
  const KundliScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: Text('Kundli & Astrology', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // User sign banner
          if (user?.sunSign != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [context.clr.surface, context.clr.surfaceLight]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.clr.accent.withValues(alpha: 0.3)),
              ),
              child: Row(children: [
                const Text('☀️', style: TextStyle(fontSize: 32)),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Your Sun Sign', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
                  Text(user!.sunSign!, style: TextStyle(color: context.clr.accent, fontSize: 22, fontWeight: FontWeight.bold)),
                  if (user.birthPlace != null)
                    Text('Born in ${user.birthPlace}', style: TextStyle(color: context.clr.txtSecondary, fontSize: 12)),
                ]),
              ]),
            ),

          Text('Kundli Services', style: TextStyle(color: context.clr.txtMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),

          _ServiceCard(
            icon: '🔮',
            title: 'Free Kundli',
            subtitle: 'Get your detailed birth chart with planet positions, houses, and nakshatra',
            color: context.clr.accent,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FreeKundliScreen())),
          ),
          const SizedBox(height: 12),
          _ServiceCard(
            icon: '💑',
            title: 'Kundli Matching',
            subtitle: 'Match kundlis for marriage compatibility using Ashtakoot method',
            color: context.clr.accentAlt,
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const KundliMatchingScreen())),
          ),
          const SizedBox(height: 12),
          _ServiceCard(
            icon: '❤️',
            title: 'Compatibility',
            subtitle: 'Check zodiac compatibility for love, friendship and work relationships',
            color: const Color(0xFFE91E63),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CompatibilityScreen())),
          ),

          const SizedBox(height: 24),
          Text('Quick Reference', style: TextStyle(color: context.clr.txtMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 1)),
          const SizedBox(height: 12),
          _buildZodiacGrid(context),
        ]),
      ),
    );
  }

  Widget _buildZodiacGrid(BuildContext context) {
    final signs = [
      {'sign': 'Aries', 'symbol': '♈', 'dates': 'Mar 21–Apr 19'},
      {'sign': 'Taurus', 'symbol': '♉', 'dates': 'Apr 20–May 20'},
      {'sign': 'Gemini', 'symbol': '♊', 'dates': 'May 21–Jun 20'},
      {'sign': 'Cancer', 'symbol': '♋', 'dates': 'Jun 21–Jul 22'},
      {'sign': 'Leo', 'symbol': '♌', 'dates': 'Jul 23–Aug 22'},
      {'sign': 'Virgo', 'symbol': '♍', 'dates': 'Aug 23–Sep 22'},
      {'sign': 'Libra', 'symbol': '♎', 'dates': 'Sep 23–Oct 22'},
      {'sign': 'Scorpio', 'symbol': '♏', 'dates': 'Oct 23–Nov 21'},
      {'sign': 'Sagittarius', 'symbol': '♐', 'dates': 'Nov 22–Dec 21'},
      {'sign': 'Capricorn', 'symbol': '♑', 'dates': 'Dec 22–Jan 19'},
      {'sign': 'Aquarius', 'symbol': '♒', 'dates': 'Jan 20–Feb 18'},
      {'sign': 'Pisces', 'symbol': '♓', 'dates': 'Feb 19–Mar 20'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, childAspectRatio: 1.1, crossAxisSpacing: 10, mainAxisSpacing: 10),
      itemCount: signs.length,
      itemBuilder: (_, i) {
        final s = signs[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.clr.border)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(s['symbol']!, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(s['sign']!, style: TextStyle(color: context.clr.txtPrimary, fontSize: 12, fontWeight: FontWeight.w600)),
            Text(s['dates']!, style: TextStyle(color: context.clr.txtMuted, fontSize: 9), textAlign: TextAlign.center),
          ]),
        );
      },
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ServiceCard({required this.icon, required this.title, required this.subtitle, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
        child: Row(children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(subtitle, style: TextStyle(color: context.clr.txtSecondary, fontSize: 12, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
          ])),
          Icon(Icons.arrow_forward_ios, color: color, size: 16),
        ]),
      ),
    );
  }
}
