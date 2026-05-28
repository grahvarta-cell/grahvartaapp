import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:percent_indicator/percent_indicator.dart';
import 'package:shimmer/shimmer.dart';
import '../../blocs/home/home_cubit.dart';
import '../../blocs/home/home_state.dart';
import '../../l10n/app_strings.dart';
import '../../models/astrologer.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import 'main_screen.dart';
import '../marketplace/astrologer_profile_screen.dart';
import '../notifications/notifications_screen.dart';
import '../wallet/wallet_screen.dart';
import '../profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<HomeCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final s = context.s;

    return Scaffold(
      body: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) {
          return RefreshIndicator(
            onRefresh: () => context.read<HomeCubit>().refresh(),
            color: context.clr.accent,
            backgroundColor: context.clr.card,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(user, s)),
                if (state is HomeLoading)
                  SliverToBoxAdapter(child: _buildShimmer())
                else if (state is HomeError)
                  SliverToBoxAdapter(child: _buildError(s))
                else if (state is HomeLoaded) ...[
                  SliverToBoxAdapter(child: _buildHoroscopeCard(state, s)),
                  SliverToBoxAdapter(child: _buildOnlineAstrologers(state, s)),
                  SliverToBoxAdapter(child: _buildScoresSection(state, s)),
                  SliverToBoxAdapter(child: _buildWhatCanIDoButton(s)),
                  const SliverToBoxAdapter(child: SizedBox(height: 100)),
                ] else ...[
                  // HomeInitial — show nothing yet
                  SliverToBoxAdapter(child: _buildShimmer()),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildError(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Column(
        children: [
          Icon(Icons.error_outline, color: context.clr.error, size: 48),
          const SizedBox(height: 12),
          Text('Could not load data', style: TextStyle(color: context.clr.txtPrimary, fontSize: 16)),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => context.read<HomeCubit>().refresh(),
            style: ElevatedButton.styleFrom(backgroundColor: context.clr.accent),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.surface,
      highlightColor: context.clr.surfaceLight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Horoscope card
            Container(height: 110, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(20))),
            const SizedBox(height: 24),
            // Section title
            Container(height: 16, width: 160, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 14),
            // Astrologer avatars row
            SizedBox(
              height: 100,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 5,
                itemBuilder: (_, __) => Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Column(children: [
                    Container(width: 60, height: 60, decoration: BoxDecoration(color: context.clr.card, shape: BoxShape.circle)),
                    const SizedBox(height: 6),
                    Container(height: 10, width: 48, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(4))),
                    const SizedBox(height: 4),
                    Container(height: 9, width: 36, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(4))),
                  ]),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Score circles row
            Row(children: List.generate(3, (i) => Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 12 : 0),
                height: 110,
                decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16)),
              ),
            ))),
            const SizedBox(height: 20),
            // CTA button
            Container(height: 52, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16))),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(User? user, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 0),
      child: Row(children: [
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: CircleAvatar(
            radius: 20,
            backgroundImage: user?.avatarUrl != null ? NetworkImage(user!.avatarUrl!) : null,
            backgroundColor: context.clr.accent.withValues(alpha: 0.2),
            child: user?.avatarUrl == null
                ? Text(user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                    style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold))
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Text('${user?.greeting ?? 'Hi'}, ${user?.name ?? ''}',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.clr.txtPrimary))),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.clr.border)),
            child: Row(children: [
              Icon(Icons.account_balance_wallet_outlined, color: context.clr.accentAlt, size: 14),
              const SizedBox(width: 4),
              Text(s.wallet, style: TextStyle(color: context.clr.accentAlt, fontSize: 12, fontWeight: FontWeight.w600)),
            ]),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const NotificationsScreen())),
          child: Stack(children: [
            Container(padding: const EdgeInsets.all(8), child: Icon(Icons.notifications_outlined, color: context.clr.txtPrimary)),
            Positioned(top: 6, right: 6, child: Container(width: 8, height: 8, decoration: BoxDecoration(color: context.clr.error, shape: BoxShape.circle))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildHoroscopeCard(HomeLoaded state, AppStrings s) {
    final h = state.horoscope;
    if (h == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [context.clr.surface, context.clr.card]),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.clr.accent.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Text('✨', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('${h.zodiacSign.isNotEmpty ? h.zodiacSign : ''} ${s.todaysHoroscope}',
                style: TextStyle(color: context.clr.accent, fontSize: 13, fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 10),
          Text(h.content, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.5), maxLines: 3, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 10),
          if (h.luckyColor != null)
            Text('Lucky color: ${h.luckyColor} · Lucky number: ${h.luckyNumber}',
                style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
        ]),
      ),
    );
  }

  Widget _buildOnlineAstrologers(HomeLoaded state, AppStrings s) {
    final astrologers = state.onlineAstrologers;
    final isRefreshing = state.astrologersRefreshing;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(s.onlineAstrologers, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: context.clr.txtPrimary)),
          Row(children: [
            GestureDetector(
              onTap: () => context.read<HomeCubit>().refreshAstrologers(),
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(8), border: Border.all(color: context.clr.border)),
                child: isRefreshing
                    ? SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: context.clr.accent))
                    : Icon(Icons.refresh, color: context.clr.accent, size: 16),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => mainTabNotifier.value = 1,
              child: Text(s.seeAll, style: TextStyle(color: context.clr.accent, fontSize: 14)),
            ),
          ]),
        ]),
      ),
      if (astrologers.isEmpty && !isRefreshing)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.border)),
            child: Row(children: [
              Icon(Icons.people_outline, color: context.clr.txtMuted, size: 32),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(s.noAstrologersOnline, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text('Check back later or browse all astrologers', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
              ])),
              GestureDetector(
                onTap: () => mainTabNotifier.value = 1,
                child: Text('Browse', style: TextStyle(color: context.clr.accent, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
            ]),
          ),
        )
      else
        SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: astrologers.length,
            itemBuilder: (_, i) => _buildAstrologerMini(astrologers[i]),
          ),
        ),
    ]);
  }

  Widget _buildAstrologerMini(Astrologer astrologer) {
    final initials = astrologer.displayName.isNotEmpty ? astrologer.displayName[0] : '?';
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AstrologerProfileScreen(astrologer: astrologer))),
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 12),
        child: Column(children: [
          Stack(children: [
            CircleAvatar(
              radius: 30,
              backgroundImage: astrologer.avatarUrl != null ? NetworkImage(astrologer.avatarUrl!) : null,
              backgroundColor: context.clr.accent.withValues(alpha: 0.2),
              child: astrologer.avatarUrl == null
                  ? Text(initials, style: TextStyle(color: context.clr.accent, fontSize: 20, fontWeight: FontWeight.bold))
                  : null,
            ),
            if (astrologer.isOnline)
              Positioned(bottom: 2, right: 2, child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(color: context.clr.success, shape: BoxShape.circle, border: Border.all(color: context.clr.bg, width: 2)),
              )),
          ]),
          const SizedBox(height: 6),
          Text(astrologer.displayName.split(' ').first, style: TextStyle(color: context.clr.txtPrimary, fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis, maxLines: 1),
          Text(astrologer.specializations.isNotEmpty ? astrologer.specializations[0] : '', style: TextStyle(color: context.clr.txtMuted, fontSize: 10)),
          Text('₹${astrologer.perMinuteRateChat.toInt()}/min', style: TextStyle(color: context.clr.accent, fontSize: 11, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  Widget _buildScoresSection(HomeLoaded state, AppStrings s) {
    final h = state.horoscope;
    final loveScore = h != null ? h.loveScore.toDouble() / 100 : 0.75;
    final friendScore = h != null ? h.friendshipScore.toDouble() / 100 : 0.60;
    final workScore = h != null ? h.workScore.toDouble() / 100 : 0.80;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: Row(children: [
        _buildScoreCircle(s.love, loveScore, '❤️', _loveDetail(loveScore), state, s),
        const SizedBox(width: 12),
        _buildScoreCircle(s.friendship, friendScore, '🤝', _friendDetail(friendScore), state, s),
        const SizedBox(width: 12),
        _buildScoreCircle(s.work, workScore, '💼', _workDetail(workScore), state, s),
      ]),
    );
  }

  String _loveDetail(double v) {
    if (v >= 0.8) return 'Stars are perfectly aligned for romance today. Express your feelings openly — your partner or a new connection will respond warmly. A great day for deep conversations and heartfelt gestures.';
    if (v >= 0.6) return 'Love energy is positive today. Small gestures of affection will go a long way. If single, keep your heart open — an interesting encounter may be around the corner.';
    if (v >= 0.4) return 'Your love life may feel a bit stagnant today. Avoid misunderstandings by choosing words carefully. Give your partner space and focus on self-love.';
    return 'Planetary tensions may create friction in relationships today. Stay calm, listen more than you speak, and avoid making big decisions about love right now.';
  }

  String _friendDetail(double v) {
    if (v >= 0.8) return 'Your social energy is at its peak! Reach out to old friends or make new connections. A gathering or reunion could bring unexpected joy. People are drawn to your warmth today.';
    if (v >= 0.6) return 'Friendships are supportive today. A friend may reach out needing your advice — lend a listening ear. Social interactions will leave you feeling uplifted.';
    if (v >= 0.4) return 'Keep social commitments light today. You may feel slightly withdrawn — it is okay to take some time for yourself rather than forcing social interactions.';
    return 'Be mindful of group dynamics today. Misunderstandings can arise easily. Avoid gossip and focus on one-on-one quality time with trusted friends.';
  }

  String _workDetail(double v) {
    if (v >= 0.8) return 'Exceptional day for career growth! Your ideas will impress superiors and colleagues alike. Take initiative on pending projects and push for that conversation you have been delaying.';
    if (v >= 0.6) return 'Steady and productive day ahead. Focus on completing existing tasks rather than starting new ones. Your dedication will be noticed by those around you.';
    if (v >= 0.4) return 'Work energy is moderate today. Avoid taking on extra responsibilities and prioritize what is most urgent. Double-check important documents before sending.';
    return 'Challenging energy for professional matters today. Postpone major decisions if possible. Focus on routine tasks and avoid conflicts with colleagues or superiors.';
  }

  void _showScoreDetail(String label, String emoji, double value, String detail, HomeLoaded state, AppStrings s) {
    final pct = (value * 100).toInt();
    final level = pct >= 80 ? s.excellent : pct >= 60 ? s.good : pct >= 40 ? s.average : s.low;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        decoration: BoxDecoration(
          color: context.clr.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: context.clr.border, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text(emoji, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 12),
          Text('$label Score', style: TextStyle(color: context.clr.txtPrimary, fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            CircularPercentIndicator(
              radius: 48, lineWidth: 6, percent: value.clamp(0.0, 1.0),
              center: Text('$pct%', style: TextStyle(color: context.clr.txtPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              progressColor: context.clr.accent, backgroundColor: context.clr.border, circularStrokeCap: CircularStrokeCap.round,
            ),
            const SizedBox(width: 20),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(level, style: TextStyle(color: pct >= 60 ? context.clr.accent : Colors.redAccent, fontSize: 22, fontWeight: FontWeight.bold)),
              Text(s.todaysOutlook, style: TextStyle(color: context.clr.txtMuted, fontSize: 13)),
              if (state.horoscope != null) ...[
                const SizedBox(height: 4),
                Text(state.horoscope!.zodiacSign, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13)),
              ],
            ]),
          ]),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(16), border: Border.all(color: context.clr.accent.withValues(alpha: 0.2))),
            child: Text(detail, style: TextStyle(color: context.clr.txtSecondary, fontSize: 14, height: 1.6)),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () { Navigator.pop(context); mainTabNotifier.value = 1; },
              style: ElevatedButton.styleFrom(backgroundColor: context.clr.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)), padding: const EdgeInsets.symmetric(vertical: 14)),
              child: Text(s.talkToAstrologer, style: const TextStyle(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildScoreCircle(String label, double value, String emoji, String detail, HomeLoaded state, AppStrings s) {
    return Expanded(child: GestureDetector(
      onTap: () => _showScoreDetail(label, emoji, value, detail, state, s),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16)),
        child: Column(children: [
          CircularPercentIndicator(
            radius: 36, lineWidth: 4, percent: value.clamp(0.0, 1.0),
            center: Text('${(value * 100).toInt()}%', style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, fontWeight: FontWeight.bold)),
            progressColor: context.clr.accent, backgroundColor: context.clr.border, circularStrokeCap: CircularStrokeCap.round,
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: context.clr.txtSecondary, fontSize: 12)),
        ]),
      ),
    ));
  }

  Widget _buildWhatCanIDoButton(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      child: ElevatedButton(
        onPressed: () => mainTabNotifier.value = 1,
        style: ElevatedButton.styleFrom(backgroundColor: context.clr.accent, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), padding: const EdgeInsets.symmetric(vertical: 16)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.auto_awesome, size: 18),
          const SizedBox(width: 8),
          Text(s.talkToAstrologer, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}
