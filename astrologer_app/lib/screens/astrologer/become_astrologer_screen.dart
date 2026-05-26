import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'astrologer_setup_profile_screen.dart';

class BecomeAstrologerScreen extends StatelessWidget {
  const BecomeAstrologerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Become an Astrologer', style: TextStyle(color: AppColors.textPrimary)),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Container(
              width: 96, height: 96,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.orange.withOpacity(0.3), width: 2),
              ),
              child: const Icon(Icons.auto_awesome, color: AppColors.orange, size: 44),
            ),
            const SizedBox(height: 24),
            const Text('Share Your Knowledge', style: TextStyle(color: AppColors.textPrimary, fontSize: 26, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'Join our community of expert astrologers and help thousands of people navigate their lives through cosmic wisdom.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
            ),
            const SizedBox(height: 32),
            ..._benefits.map(_buildBenefit),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange.withOpacity(0.2)),
              ),
              child: const Column(
                children: [
                  Text('How It Works', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 12),
                  _Step(num: '1', text: 'Create your astrologer profile'),
                  _Step(num: '2', text: 'Wait for admin approval (24-48hrs)'),
                  _Step(num: '3', text: 'Go online and start accepting consultations'),
                  _Step(num: '4', text: 'Earn per minute for chat, call & video'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AstrologerSetupProfileScreen())),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                child: const Text('Get Started', style: TextStyle(fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _benefits = [
    ('₹ Earn Per Minute', 'Set your own rates for chat, call, and video consultations', Icons.monetization_on_outlined),
    ('🌟 Build Your Brand', 'Grow your reputation with ratings and reviews', Icons.star_border),
    ('📱 Mobile Dashboard', 'Manage everything from your phone — accept/reject, go live, withdraw', Icons.phone_android),
    ('🔴 Live Sessions', 'Host live astrology sessions and earn tips from viewers', Icons.live_tv_outlined),
  ];

  Widget _buildBenefit((String title, String desc, IconData icon) b) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
          child: Icon(b.$3, color: AppColors.orange, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(b.$1, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(b.$2, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12, height: 1.3)),
        ])),
      ]),
    );
  }
}

class _Step extends StatelessWidget {
  final String num;
  final String text;
  const _Step({required this.num, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Container(
          width: 24, height: 24,
          decoration: const BoxDecoration(color: AppColors.orange, shape: BoxShape.circle),
          child: Center(child: Text(num, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
        ),
        const SizedBox(width: 10),
        Text(text, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
      ]),
    );
  }
}
