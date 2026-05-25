import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'astrologer_own_profile_screen.dart';
import 'astrologer_earnings_screen.dart';

class AstrologerDashboardScreen extends StatefulWidget {
  const AstrologerDashboardScreen({super.key});

  @override
  State<AstrologerDashboardScreen> createState() => _AstrologerDashboardScreenState();
}

class _AstrologerDashboardScreenState extends State<AstrologerDashboardScreen> {
  Map<String, dynamic>? _dashboard;
  bool _loading = true;
  bool _toggling = false;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) setState(() => _loading = true);
    try {
      final data = await ApiService.getAstrologerDashboard();
      if (mounted) setState(() { _dashboard = data['data']; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _toggleAvailability() async {
    final auth = context.read<AuthProvider>();
    final current = auth.astrologerProfile?.isAvailable ?? true;
    setState(() => _toggling = true);
    try {
      await ApiService.updateAvailability(!current);
      await auth.refreshAstrologerProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(!current ? 'You are now available' : 'You are now offline'), backgroundColor: AppColors.success),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to update availability'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final astrologer = auth.astrologerProfile;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AstrologerOwnProfileScreen())),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: astrologer?.avatarUrl != null ? NetworkImage(astrologer!.avatarUrl!) : null,
              backgroundColor: AppColors.orange.withOpacity(0.2),
              child: astrologer?.avatarUrl == null
                  ? Text(
                      (auth.user?.name?.isNotEmpty == true ? auth.user!.name[0].toUpperCase() : 'A'),
                      style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Welcome, ${auth.user?.name?.split(' ').first ?? ''} ✨',
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
            const Text('Performance Overview', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
          ],
        ),
        actions: [
          if (astrologer != null)
            GestureDetector(
              onTap: _toggling ? null : _toggleAvailability,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: astrologer.isAvailable ? AppColors.success.withOpacity(0.2) : AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: astrologer.isAvailable ? AppColors.success : AppColors.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(astrologer.isAvailable ? Icons.toggle_on_rounded : Icons.toggle_off_rounded,
                    color: astrologer.isAvailable ? AppColors.success : AppColors.textMuted, size: 18),
                  const SizedBox(width: 4),
                  Text(astrologer.isAvailable ? 'Online' : 'Offline',
                    style: TextStyle(
                      color: astrologer.isAvailable ? AppColors.success : AppColors.textMuted,
                      fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textPrimary),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AstrologerEarningsScreen())),
            tooltip: 'Wallet',
          ),
        ],
      ),
      body: _loading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _loadDashboard,
              color: AppColors.orange,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStats(astrologer),
                    const SizedBox(height: 20),
                    _buildRecentConsultations(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShimmer() {
    final base = AppColors.card;
    final highlight = AppColors.surface;
    return Shimmer.fromColors(
      baseColor: base,
      highlightColor: highlight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Stat cards grid — 2×2
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.4,
            children: List.generate(4, (_) => Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            )),
          ),
          const SizedBox(height: 20),
          // Section title
          Container(height: 16, width: 180, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          // Recent consultation rows
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: Column(children: List.generate(4, (i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(children: [
                Container(width: 40, height: 40, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(height: 12, width: 120, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                ])),
                Container(height: 14, width: 40, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              ]),
            ))),
          ),
        ]),
      ),
    );
  }

  Widget _buildStats(AstrologerProfile? astrologer) {
    final stats = _dashboard?['stats'] ?? {};
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.4,
      children: [
        _statCard(Icons.people_rounded, 'Consultations', '${stats['total'] ?? 0}', AppColors.orange),
        _statCard(Icons.star_rounded, 'Rating', '${(double.tryParse(astrologer?.rating.toString() ?? '0') ?? 0).toStringAsFixed(1)} (${astrologer?.reviewCount ?? 0})', const Color(0xFFFFD700)),
        _statCard(Icons.trending_up_rounded, 'Total Earnings', '₹${(double.tryParse(stats['total_revenue']?.toString() ?? '0') ?? 0).toStringAsFixed(0)}', AppColors.success),
        _statCard(Icons.access_time_rounded, 'Avg Duration', '${((double.tryParse(stats['avg_duration']?.toString() ?? '0') ?? 0) / 60).round()}m', Colors.blue),
      ],
    );
  }

  Widget _statCard(IconData icon, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const Spacer(),
          Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _buildRecentConsultations() {
    final recent = (_dashboard?['recent_consultations'] as List?) ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Consultations', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: recent.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('No consultations yet', style: TextStyle(color: AppColors.textMuted))),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: recent.length > 5 ? 5 : recent.length,
                  separatorBuilder: (_, __) => const Divider(color: AppColors.border, height: 1),
                  itemBuilder: (_, i) {
                    final c = recent[i] as Map;
                    final name = ((c['user_name'] ?? 'User') as String).split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
                    final type = c['type'] ?? 'chat';
                    final mins = ((double.tryParse(c['duration_seconds']?.toString() ?? '0') ?? 0) / 60).round();
                    final amount = double.tryParse(c['total_amount']?.toString() ?? '0') ?? 0;
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.orange.withOpacity(0.2),
                        child: Text(name[0].toUpperCase(), style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold)),
                      ),
                      title: Text(name, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14)),
                      subtitle: Text('$type · ${mins}m', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      trailing: Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold)),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
