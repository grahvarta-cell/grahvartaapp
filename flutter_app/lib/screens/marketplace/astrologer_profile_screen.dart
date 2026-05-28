import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../consultation/chat_screen.dart';
import '../consultation/call_screen.dart';
import '../wallet/wallet_screen.dart';

class AstrologerProfileScreen extends StatefulWidget {
  final Astrologer astrologer;
  final String? startType;
  const AstrologerProfileScreen({super.key, required this.astrologer, this.startType});

  @override
  State<AstrologerProfileScreen> createState() => _AstrologerProfileScreenState();
}

class _AstrologerProfileScreenState extends State<AstrologerProfileScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _heroController;
  late AnimationController _contentController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  List<Review> _reviews = [];
  bool _loadingReviews = true;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() => _selectedTab = _tabController.index));

    _heroController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _contentController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));

    _fadeAnim = CurvedAnimation(parent: _contentController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _contentController, curve: Curves.easeOutCubic));

    _heroController.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _contentController.forward());

    _loadReviews();

    if (widget.startType != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _startConsultation(widget.startType!));
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _heroController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    try {
      final data = await ApiService.getAstrologerReviews(widget.astrologer.id);
      if (mounted) setState(() { _reviews = data; _loadingReviews = false; });
    } catch (_) {
      if (mounted) setState(() { _reviews = _demoReviews(); _loadingReviews = false; });
    }
  }

  List<Review> _demoReviews() => [
    Review(id: '1', userName: 'Rahul M.', rating: 5, reviewText: 'Absolutely amazing! The reading was spot-on and gave me clarity I needed.', createdAt: '2024-01-15'),
    Review(id: '2', userName: 'Priya S.', rating: 5, reviewText: 'Very insightful session. Pandit ji explained everything clearly and the predictions came true!', createdAt: '2024-01-10'),
    Review(id: '3', userName: 'Anonymous', rating: 4, reviewText: 'Good consultation. Would recommend to others looking for genuine astrological guidance.', createdAt: '2024-01-05'),
  ];

  Future<void> _startConsultation(String type) async {
    HapticFeedback.mediumImpact();

    // Check wallet balance before starting
    try {
      final walletData = await ApiService.getWallet();
      final balance = walletData.balance;
      final a = widget.astrologer;
      final rate = type == 'chat'
          ? a.perMinuteRateChat
          : type == 'voice'
              ? a.perMinuteRateCall
              : a.perMinuteRateVideo;
      final minRequired = rate * 2; // minimum 2 minutes balance required

      if (balance < minRequired) {
        if (!mounted) return;
        _showLowBalanceDialog(balance, minRequired, rate);
        return;
      }
    } catch (_) {
      // If wallet check fails, let the socket handle insufficient_balance
    }

    if (!mounted) return;
    if (type == 'chat') {
      Navigator.push(context, _fadeRoute(ChatScreen(astrologer: widget.astrologer)));
    } else {
      Navigator.push(context, _fadeRoute(CallScreen(astrologer: widget.astrologer, callType: type)));
    }
  }

  void _showLowBalanceDialog(double balance, double required, double rate) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.account_balance_wallet, color: context.clr.accent),
          const SizedBox(width: 8),
          Text('Low Balance', style: TextStyle(color: context.clr.txtPrimary)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your wallet balance is ₹${balance.toStringAsFixed(2)}.', style: TextStyle(color: context.clr.txtSecondary)),
          const SizedBox(height: 6),
          Text('Minimum ₹${required.toStringAsFixed(0)} required (2 min @ ₹${rate.toInt()}/min).', style: TextStyle(color: context.clr.txtMuted, fontSize: 13)),
          const SizedBox(height: 12),
          Text('Please add money to your wallet to continue.', style: TextStyle(color: context.clr.txtSecondary, fontSize: 13)),
        ]),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: context.clr.txtMuted)),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
            },
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Money'),
          ),
        ],
      ),
    );
  }

  Route _fadeRoute(Widget page) => PageRouteBuilder(
    pageBuilder: (_, __, ___) => page,
    transitionDuration: const Duration(milliseconds: 400),
    transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
  );

  @override
  Widget build(BuildContext context) {
    final a = widget.astrologer;
    final statusBarH = MediaQuery.of(context).padding.top;

    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(children: [
        // ── Main scrollable content ──────────────────────────────────────────
        CustomScrollView(slivers: [
          // Hero header
          SliverToBoxAdapter(child: _buildHero(a, statusBarH)),

          // Tab bar
          SliverAppBar(
            pinned: true,
            automaticallyImplyLeading: false,
            toolbarHeight: 0,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.none,
              background: _buildTabBar(),
            ),
            expandedHeight: 56,
            collapsedHeight: 56,
          ),

          // Tab content
          SliverFillRemaining(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: TabBarView(controller: _tabController, children: [
                  _buildOverview(a),
                  _buildReviews(),
                ]),
              ),
            ),
          ),
        ]),

        // ── Floating back button ─────────────────────────────────────────────
        Positioned(
          top: statusBarH + 12,
          left: 16,
          child: _GlassButton(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
          ),
        ),

        // ── Bottom consult bar ───────────────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0, child: _buildConsultBar(a)),
      ]),
    );
  }

  // ─── Hero ──────────────────────────────────────────────────────────────────
  Widget _buildHero(Astrologer a, double statusBarH) {
    return AnimatedBuilder(
      animation: _heroController,
      builder: (_, child) => Opacity(opacity: _heroController.value, child: child),
      child: Container(
        height: 340 + statusBarH,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [context.clr.surface, context.clr.card, context.clr.bg],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(children: [
          // Subtle radial glow
          Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
            gradient: RadialGradient(
              center: const Alignment(0, -0.4),
              radius: 0.9,
              colors: [context.clr.accent.withValues(alpha: 0.12), Colors.transparent],
            ),
          ))),

          // Star dots decoration
          ..._buildStarDots(),

          // Content
          Padding(
            padding: EdgeInsets.fromLTRB(20, statusBarH + 48, 20, 0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              // Avatar
              Stack(alignment: Alignment.center, children: [
                // Outer glow ring
                AnimatedBuilder(
                  animation: _heroController,
                  builder: (_, __) => Container(
                    width: 114 + (_heroController.value * 6),
                    height: 114 + (_heroController.value * 6),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(colors: [
                        context.clr.accent.withValues(alpha: 0.6 * _heroController.value),
                        context.clr.accentAlt.withValues(alpha: 0.4 * _heroController.value),
                        context.clr.accent.withValues(alpha: 0.6 * _heroController.value),
                      ]),
                    ),
                  ),
                ),
                // Avatar
                Container(
                  width: 104, height: 104,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: context.clr.bg, width: 3),
                  ),
                  child: ClipOval(
                    child: a.avatarUrl != null
                        ? Image.network(a.avatarUrl!, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _avatarPlaceholder(a))
                        : _avatarPlaceholder(a),
                  ),
                ),
                // Online dot
                if (a.isOnline)
                  Positioned(bottom: 4, right: 4, child: Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      color: context.clr.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: context.clr.bg, width: 3),
                    ),
                  )),
                // Verified badge
                if (a.isVerified)
                  Positioned(top: 2, right: 2, child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                    child: const Icon(Icons.verified_rounded, color: Colors.white, size: 12),
                  )),
              ]),

              const SizedBox(height: 14),

              // Name
              Text(a.displayName, style: TextStyle(
                color: context.clr.txtPrimary, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 0.3,
              )),

              const SizedBox(height: 6),

              // Rating row
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                RatingBarIndicator(
                  rating: a.rating,
                  itemSize: 15,
                  itemBuilder: (_, __) => Icon(Icons.star_rounded, color: context.clr.accentAlt),
                ),
                const SizedBox(width: 6),
                Text('${a.ratingFormatted}', style: TextStyle(color: context.clr.accentAlt, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(width: 4),
                Text('· ${a.reviewCount} reviews', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
              ]),

              const SizedBox(height: 16),

              // Stats row
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  color: context.clr.surface.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: context.clr.border),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  _heroStat('${a.experienceYears}+', 'Years Exp.'),
                  _heroDivider(),
                  _heroStat('${(a.totalConsultations / 1000).toStringAsFixed(1)}K', 'Clients'),
                  _heroDivider(),
                  _heroStat('₹${a.perMinuteRateChat.toInt()}', '/min chat'),
                ]),
              ),

            ]),
          ),
        ]),
      ),
    );
  }

  Widget _avatarPlaceholder(Astrologer a) => Container(
    color: context.clr.accent.withValues(alpha: 0.15),
    child: Center(child: Text(
      a.displayName.isNotEmpty ? a.displayName[0] : '?',
      style: TextStyle(fontSize: 40, color: context.clr.accent, fontWeight: FontWeight.bold),
    )),
  );

  Widget _heroStat(String val, String label) => Column(children: [
    Text(val, style: TextStyle(color: context.clr.accent, fontSize: 17, fontWeight: FontWeight.bold)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 10)),
  ]);

  Widget _heroDivider() => Container(
    width: 1, height: 30, margin: const EdgeInsets.symmetric(horizontal: 20),
    color: context.clr.border,
  );

  List<Widget> _buildStarDots() {
    const dots = [
      [30.0, 30.0, 3.0], [320.0, 20.0, 2.0], [50.0, 180.0, 2.5],
      [340.0, 160.0, 1.5], [180.0, 14.0, 2.0], [100.0, 140.0, 1.5], [260.0, 110.0, 3.0],
    ];
    return dots.map((d) => Positioned(
      left: d[0], top: d[1],
      child: AnimatedBuilder(
        animation: _heroController,
        builder: (_, __) => Opacity(
          opacity: _heroController.value * 0.5,
          child: Container(
            width: d[2], height: d[2],
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
      ),
    )).toList();
  }

  // ─── Tab bar ───────────────────────────────────────────────────────────────
  Widget _buildTabBar() {
    return Container(
      color: context.clr.bg,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        child: Row(children: [
          Expanded(child: _tabChip(0, Icons.info_outline_rounded, 'Overview')),
          const SizedBox(width: 8),
          Expanded(child: _tabChip(1, Icons.star_outline_rounded, 'Reviews')),
        ]),
      ),
    );
  }

  Widget _tabChip(int index, IconData icon, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        _tabController.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? context.clr.accent : context.clr.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? context.clr.accent : context.clr.border),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 14, color: isSelected ? Colors.white : context.clr.txtMuted),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(
            color: isSelected ? Colors.white : context.clr.txtMuted,
            fontSize: 13, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          )),
        ]),
      ),
    );
  }

  // ─── Overview tab ──────────────────────────────────────────────────────────
  Widget _buildOverview(Astrologer a) {
    return ListView(padding: const EdgeInsets.fromLTRB(20, 20, 20, 110), children: [
      if (a.bio != null) ...[
        _sectionHeader('About', Icons.person_outline_rounded),
        const SizedBox(height: 10),
        _GlassCard(child: Text(a.bio!, style: TextStyle(color: context.clr.txtSecondary, fontSize: 14, height: 1.7))),
        const SizedBox(height: 22),
      ],

      _sectionHeader('Specializations', Icons.auto_awesome_rounded),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: a.specializations.map((s) => _SpecTag(label: s)).toList()),
      const SizedBox(height: 22),

      _sectionHeader('Languages', Icons.language_rounded),
      const SizedBox(height: 10),
      Wrap(spacing: 8, runSpacing: 8, children: a.languages.map((l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: context.clr.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.clr.border),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Text('🌐', style: TextStyle(fontSize: 13)),
          const SizedBox(width: 5),
          Text(l, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13)),
        ]),
      )).toList()),
      const SizedBox(height: 22),

      _sectionHeader('Consultation Rates', Icons.payments_outlined),
      const SizedBox(height: 10),
      _AnimatedRateCard(icon: Icons.chat_bubble_outline_rounded, label: 'Chat', sublabel: 'Text consultation', rate: a.perMinuteRateChat, color: context.clr.accent, delay: 0),
      const SizedBox(height: 8),
      _AnimatedRateCard(icon: Icons.phone_outlined, label: 'Voice Call', sublabel: 'Audio consultation', rate: a.perMinuteRateCall, color: context.clr.success, delay: 80),
      const SizedBox(height: 8),
      _AnimatedRateCard(icon: Icons.videocam_outlined, label: 'Video Call', sublabel: 'Face-to-face session', rate: a.perMinuteRateVideo, color: const Color(0xFF2196F3), delay: 160),
    ]);
  }

  Widget _sectionHeader(String title, IconData icon) => Row(children: [
    Icon(icon, size: 16, color: context.clr.accent),
    const SizedBox(width: 8),
    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: context.clr.txtPrimary)),
  ]);

  // ─── Reviews tab ───────────────────────────────────────────────────────────
  Widget _buildReviews() {
    if (_loadingReviews) {
      return Center(child: CircularProgressIndicator(color: context.clr.accent, strokeWidth: 2));
    }
    if (_reviews.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.star_outline_rounded, size: 52, color: context.clr.txtMuted),
        const SizedBox(height: 12),
        Text('No reviews yet', style: TextStyle(color: context.clr.txtMuted, fontSize: 15)),
      ]));
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
      itemCount: _reviews.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _ReviewCard(review: _reviews[i], index: i),
    );
  }

  // ─── Consult bar ───────────────────────────────────────────────────────────
  Widget _buildConsultBar(Astrologer a) {
    return Container(
          padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
          decoration: BoxDecoration(
            color: context.clr.surface.withValues(alpha: 0.95),
            border: Border(top: BorderSide(color: context.clr.border)),
          ),
          child: Row(children: [
            // Call buttons
            _ConsultIconBtn(
              icon: Icons.phone_rounded,
              color: context.clr.success,
              tooltip: '₹${a.perMinuteRateCall.toInt()}/min',
              onTap: () => _startConsultation('voice'),
            ),
            const SizedBox(width: 10),
            _ConsultIconBtn(
              icon: Icons.videocam_rounded,
              color: const Color(0xFF2196F3),
              tooltip: '₹${a.perMinuteRateVideo.toInt()}/min',
              onTap: () => _startConsultation('video'),
            ),
            const SizedBox(width: 12),
            // Chat button
            Expanded(child: GestureDetector(
              onTap: a.isOnline ? () => _startConsultation('chat') : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: 50,
                decoration: BoxDecoration(
                  gradient: a.isOnline
                      ? LinearGradient(colors: [context.clr.accent, Color(0xFFB85C1A)])
                      : null,
                  color: a.isOnline ? null : context.clr.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: a.isOnline ? null : Border.all(color: context.clr.border),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.chat_bubble_rounded, size: 18,
                    color: a.isOnline ? Colors.white : context.clr.txtMuted),
                  const SizedBox(width: 8),
                  Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(a.isOnline ? 'Chat Now' : 'Offline',
                      style: TextStyle(color: a.isOnline ? Colors.white : context.clr.txtMuted,
                        fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('₹${a.perMinuteRateChat.toInt()}/min',
                      style: TextStyle(color: a.isOnline ? Colors.white.withOpacity(0.7) : context.clr.txtMuted,
                        fontSize: 11)),
                  ]),
                ]),
              ),
            )),
          ]),
    );
  }
}

// ─── Sticky tab delegate ───────────────────────────────────────────────────────
// ─── Glass card ──────────────────────────────────────────────────────────────
class _GlassCard extends StatelessWidget {
  final Widget child;
  const _GlassCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clr.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: child,
    );
  }
}

// ─── Spec tag ─────────────────────────────────────────────────────────────────
class _SpecTag extends StatefulWidget {
  final String label;
  const _SpecTag({required this.label});
  @override State<_SpecTag> createState() => _SpecTagState();
}
class _SpecTagState extends State<_SpecTag> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 180));
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: 1.0 - (_ctrl.value * 0.04), child: child),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [context.clr.accent.withValues(alpha: 0.15), context.clr.accent.withValues(alpha: 0.08)]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.clr.accent.withValues(alpha: 0.3)),
          ),
          child: Text(widget.label, style: TextStyle(color: context.clr.accent, fontSize: 13, fontWeight: FontWeight.w500)),
        ),
      ),
    );
  }
}

// ─── Animated rate card ───────────────────────────────────────────────────────
class _AnimatedRateCard extends StatefulWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final double rate;
  final Color color;
  final int delay;
  const _AnimatedRateCard({required this.icon, required this.label, required this.sublabel, required this.rate, required this.color, required this.delay});

  @override State<_AnimatedRateCard> createState() => _AnimatedRateCardState();
}
class _AnimatedRateCardState extends State<_AnimatedRateCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: context.clr.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: widget.color.withOpacity(0.15)),
          ),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
              child: Icon(widget.icon, color: widget.color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.label, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
              Text(widget.sublabel, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: widget.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Text('₹${widget.rate.toInt()}/min', style: TextStyle(color: widget.color, fontSize: 13, fontWeight: FontWeight.bold)),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─── Review card ──────────────────────────────────────────────────────────────
class _ReviewCard extends StatefulWidget {
  final Review review;
  final int index;
  const _ReviewCard({required this.review, required this.index});
  @override State<_ReviewCard> createState() => _ReviewCardState();
}
class _ReviewCardState extends State<_ReviewCard> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.index * 80), () { if (mounted) _ctrl.forward(); });
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final colors = [context.clr.accent, const Color(0xFF9C27B0), const Color(0xFF2196F3), context.clr.success];
    final avatarColor = colors[widget.index % colors.length];

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.clr.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.05)),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: avatarColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Text(r.userName[0], style: TextStyle(color: avatarColor, fontSize: 16, fontWeight: FontWeight.bold))),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(r.userName, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                RatingBarIndicator(
                  rating: r.rating.toDouble(),
                  itemSize: 12,
                  itemBuilder: (_, __) => Icon(Icons.star_rounded, color: context.clr.accentAlt),
                ),
              ])),
              Text(r.createdAt.length > 10 ? r.createdAt.substring(0, 10) : r.createdAt,
                  style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ]),
            if (r.reviewText != null && r.reviewText!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(r.reviewText!, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.6)),
            ],
          ]),
        ),
      ),
    );
  }
}

// ─── Glass floating button ────────────────────────────────────────────────────
class _GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  const _GlassButton({required this.onTap, required this.child});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.4),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
        ),
        child: Center(child: child),
      ),
    );
  }
}

// ─── Consult icon button ──────────────────────────────────────────────────────
class _ConsultIconBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;
  const _ConsultIconBtn({required this.icon, required this.color, required this.tooltip, required this.onTap});
  @override State<_ConsultIconBtn> createState() => _ConsultIconBtnState();
}
class _ConsultIconBtnState extends State<_ConsultIconBtn> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() { super.initState(); _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.92, upperBound: 1.0, value: 1.0); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) { HapticFeedback.selectionClick(); _ctrl.reverse(); },
      onTapUp: (_) { _ctrl.forward(); widget.onTap(); },
      onTapCancel: () => _ctrl.forward(),
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, child) => Transform.scale(scale: _ctrl.value, child: child),
        child: Tooltip(
          message: widget.tooltip,
          child: Container(
            width: 50, height: 50,
            decoration: BoxDecoration(
              color: widget.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: widget.color.withOpacity(0.25)),
            ),
            child: Icon(widget.icon, color: widget.color, size: 22),
          ),
        ),
      ),
    );
  }
}
