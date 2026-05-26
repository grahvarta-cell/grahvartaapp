import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class AstrologerPendingScreen extends StatefulWidget {
  const AstrologerPendingScreen({super.key});

  @override
  State<AstrologerPendingScreen> createState() => _AstrologerPendingScreenState();
}

class _AstrologerPendingScreenState extends State<AstrologerPendingScreen> {
  bool _refreshing = false;

  Future<void> _refresh() async {
    setState(() => _refreshing = true);
    try {
      await context.read<AuthProvider>().refreshAstrologerProfile();
      if (!mounted) return;

      final profile = context.read<AuthProvider>().astrologerProfile;
      if (profile == null) {
        _snack('Could not fetch profile status. Try again.', error: true);
      } else if (profile.isApproved) {
        // AstrologerMainScreen will rebuild automatically via watch — just show a message
        _snack('Profile approved! Loading dashboard...', success: true);
      } else if (profile.approvalStatus == 'rejected') {
        _snack('Profile was not approved. Contact support.', error: true);
      } else {
        _snack('Still pending review. Please wait.');
      }
    } catch (e) {
      if (mounted) _snack('Error: ${e.toString()}', error: true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  void _snack(String msg, {bool error = false, bool success = false}) {
    Color bg = AppColors.surface;
    if (error) bg = AppColors.error;
    if (success) bg = AppColors.success;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: bg),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<AuthProvider>().astrologerProfile;
    final isRejected = profile?.approvalStatus == 'rejected';

    return WillPopScope(
      onWillPop: () async {
        SystemNavigator.pop();
        return false;
      },
      child: Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Status icon
                Container(
                  width: 96, height: 96,
                  decoration: BoxDecoration(
                    color: (isRejected ? AppColors.error : const Color(0xFFFFD700)).withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: (isRejected ? AppColors.error : const Color(0xFFFFD700)).withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    isRejected ? Icons.cancel_outlined : Icons.hourglass_top_rounded,
                    color: isRejected ? AppColors.error : const Color(0xFFFFD700),
                    size: 44,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  isRejected ? 'Profile Not Approved' : 'Pending Approval',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(
                  isRejected
                      ? 'Your astrologer profile was not approved by the admin. Please contact support for assistance.'
                      : 'Your astrologer profile has been submitted and is under review. Our team will approve it within 24–48 hours.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 32),
                // Progress steps
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      _step('Profile submitted', true),
                      _divider(),
                      _step('Admin review', isRejected),
                      _divider(),
                      _step('Start accepting consultations', false),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                // Refresh button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _refreshing ? null : _refresh,
                    icon: _refreshing
                        ? const SizedBox(
                            width: 16, height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.orange),
                          )
                        : const Icon(Icons.refresh_rounded, size: 18),
                    label: Text(_refreshing ? 'Checking...' : 'Refresh Status'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.orange,
                      side: const BorderSide(color: AppColors.orange),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (!isRejected) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'You\'ll also receive a push notification\nwhen your profile is reviewed.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ));
  }

  Widget _step(String label, bool done) {
    return Row(children: [
      Container(
        width: 28, height: 28,
        decoration: BoxDecoration(
          color: done ? AppColors.success.withOpacity(0.2) : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: done ? AppColors.success : AppColors.border),
        ),
        child: Icon(
          done ? Icons.check : Icons.circle_outlined,
          color: done ? AppColors.success : AppColors.textMuted,
          size: 16,
        ),
      ),
      const SizedBox(width: 12),
      Text(label, style: TextStyle(color: done ? AppColors.textPrimary : AppColors.textMuted, fontSize: 14)),
    ]);
  }

  Widget _divider() => Container(
    margin: const EdgeInsets.only(left: 14, top: 4, bottom: 4),
    width: 1, height: 16,
    color: AppColors.border,
  );
}
