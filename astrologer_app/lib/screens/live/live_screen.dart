import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import '../../services/socket_service.dart';
import '../../theme/app_theme.dart';

class LiveScreen extends StatefulWidget {
  const LiveScreen({super.key});

  @override
  State<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<LiveSession> _sessions = [];
  List<CommunityPost> _posts = [];
  bool _isLoading = true;
  bool _postsLoading = false;
  String? _filterCategory; // null = all
  String _sortBy = 'latest'; // latest | liked | commented

  // Must match categories used in astrologer post creation
  static const _categories = ['general', 'horoscope', 'tips', 'meditation', 'vastu'];

  static const _sortOptions = [
    {'key': 'latest',    'label': 'Latest'},
    {'key': 'liked',     'label': 'Most Liked'},
    {'key': 'commented', 'label': 'Most Commented'},
  ];

  List<CommunityPost> get _sortedPosts {
    final list = List<CommunityPost>.from(_posts);
    if (_sortBy == 'liked')     list.sort((a, b) => b.likesCount.compareTo(a.likesCount));
    if (_sortBy == 'commented') list.sort((a, b) => b.commentsCount.compareTo(a.commentsCount));
    return list;
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getLiveSessions(),
        ApiService.getCommunityPosts(category: _filterCategory),
      ]);
      if (mounted) setState(() {
        final all = results[0] as List<LiveSession>;
        _sessions = all.where((s) => s.status != 'ended').toList();
        _posts = results[1] as List<CommunityPost>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _sessions = _demoSessions();
        _posts = _demoPosts();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadPosts() async {
    if (mounted) setState(() => _postsLoading = true);
    try {
      final posts = await ApiService.getCommunityPosts(category: _filterCategory);
      if (mounted) setState(() { _posts = posts; _postsLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _posts = _demoPosts(); _postsLoading = false; });
    }
  }

  List<LiveSession> _demoSessions() => [
    LiveSession(id: '1', astrologerId: 'a1', astrologerName: 'Pandit Raj Sharma', title: 'Mercury Retrograde Survival Guide', description: 'Learn how to navigate this challenging period', status: 'live', viewerCount: 234, totalTips: 1250, startedAt: DateTime.now().subtract(const Duration(minutes: 15)).toIso8601String()),
    LiveSession(id: '2', astrologerId: 'a2', astrologerName: 'Dr. Priya Nair', title: 'Full Moon Tarot Reading', description: 'Special reading for all signs during full moon', status: 'scheduled', viewerCount: 0, totalTips: 0, scheduledAt: DateTime.now().add(const Duration(hours: 2)).toIso8601String()),
    LiveSession(id: '3', astrologerId: 'a3', astrologerName: 'Acharya Vikram', title: 'Vastu Tips for Home & Office', description: 'Transform your space with ancient Vastu wisdom', status: 'scheduled', viewerCount: 0, totalTips: 0, scheduledAt: DateTime.now().add(const Duration(hours: 5)).toIso8601String()),
  ];

  List<CommunityPost> _demoPosts() => [
    CommunityPost(id: '1', authorName: 'Pandit Raj Sharma', authorSign: 'Aries', astrologerName: 'Pandit Raj Sharma', isVerified: true, content: 'Mercury retrograde ends this week! Time to move forward with clarity and confidence. The cosmic energy is shifting — embrace new beginnings. ✨🔮', likesCount: 342, commentsCount: 45, isLiked: false, createdAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()),
    CommunityPost(id: '2', authorName: 'Priya_Scorpio', authorSign: 'Scorpio', content: 'My consultation with Pandit Raj was incredibly insightful. He predicted my job change 3 months in advance! Highly recommend 🌟', likesCount: 128, commentsCount: 23, isLiked: true, createdAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String()),
    CommunityPost(id: '3', authorName: 'Dr. Priya Nair', astrologerName: 'Dr. Priya Nair', isVerified: true, content: 'Full Moon in Scorpio this weekend — powerful time for transformation, releasing old patterns, and deep healing. Journal your intentions tonight 🌕', likesCount: 567, commentsCount: 89, isLiked: false, createdAt: DateTime.now().subtract(const Duration(hours: 8)).toIso8601String()),
    CommunityPost(id: '4', authorName: 'AstroLover_Rahul', authorSign: 'Leo', content: 'Which zodiac sign are you and how has your week been? Drop it below! My Leo energy is on fire this week 🔥', likesCount: 234, commentsCount: 156, isLiked: false, createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String()),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Live & Community'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.clr.accent,
          labelColor: context.clr.accent,
          unselectedLabelColor: context.clr.txtMuted,
          tabs: const [Tab(text: '🔴 Live Sessions'), Tab(text: '💬 Community')],
        ),
      ),
      body: _isLoading
          ? _buildFullShimmer()
          : TabBarView(controller: _tabController, children: [
              _buildLiveTab(),
              _buildCommunityTab(),
            ]),
    );
  }

  Widget _buildLiveTab() {
    final liveSessions = _sessions.where((s) => s.isLive).toList();
    final upcoming = _sessions.where((s) => !s.isLive).toList();

    return RefreshIndicator(
      onRefresh: _loadData,
      color: context.clr.accent,
      backgroundColor: context.clr.card,
      child: _sessions.isEmpty
          ? ListView(children: [
              const SizedBox(height: 80),
              Center(child: Icon(Icons.live_tv_outlined, size: 64, color: context.clr.txtMuted)),
              const SizedBox(height: 16),
              Center(child: Text('No live sessions right now', style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
              const SizedBox(height: 8),
              Center(child: Text('Check back soon for upcoming sessions', style: TextStyle(color: context.clr.txtMuted, fontSize: 13))),
            ])
          : ListView(padding: const EdgeInsets.all(16), children: [
              if (liveSessions.isNotEmpty) ...[
                Text('🔴 Live Now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
                const SizedBox(height: 12),
                ...liveSessions.map((s) => _buildLiveCard(s, isLive: true)),
                const SizedBox(height: 20),
              ],
              if (upcoming.isNotEmpty) ...[
                Text('📅 Upcoming', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
                const SizedBox(height: 12),
                ...upcoming.map((s) => _buildLiveCard(s, isLive: false)),
              ],
            ]),
    );
  }

  Widget _buildLiveCard(LiveSession session, {required bool isLive}) {
    return GestureDetector(
      onTap: () => isLive ? _joinLiveSession(session) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isLive ? context.clr.error.withValues(alpha: 0.5) : context.clr.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                // Background
                session.thumbnailUrl != null
                    ? Image.network(session.thumbnailUrl!, fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                            colors: isLive
                                ? [const Color(0xFF3A0D00), const Color(0xFF1A0500)]
                                : [const Color(0xFF1A1500), const Color(0xFF0D0D0D)],
                          ),
                        ),
                        child: Center(child: Icon(Icons.stars, size: 72, color: context.clr.accent.withValues(alpha: 0.25))),
                      ),
                // Gradient overlay at bottom
                Positioned.fill(child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withOpacity(0.7)],
                      stops: const [0.4, 1.0],
                    ),
                  ),
                )),
                // LIVE badge
                if (isLive)
                  Positioned(top: 12, left: 12, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: context.clr.error, borderRadius: BorderRadius.circular(12)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                      SizedBox(width: 4),
                      Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                    ]),
                  )),
                // Viewer count
                if (isLive)
                  Positioned(top: 12, right: 12, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(10)),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 12),
                      const SizedBox(width: 4),
                      Text('${session.viewerCount}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                    ]),
                  )),
                // Astrologer name at bottom
                Positioned(bottom: 12, left: 12, right: 60, child: Row(children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: session.thumbnailUrl != null ? NetworkImage(session.thumbnailUrl!) : null,
                    backgroundColor: context.clr.accent.withValues(alpha: 0.3),
                    child: session.thumbnailUrl == null
                        ? Text(session.astrologerName[0], style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold))
                        : null,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(session.astrologerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14), overflow: TextOverflow.ellipsis)),
                ])),
                // Join button overlay
                if (isLive)
                  Positioned(bottom: 10, right: 12, child: GestureDetector(
                    onTap: () => _joinLiveSession(session),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                      decoration: BoxDecoration(color: context.clr.error, borderRadius: BorderRadius.circular(20)),
                      child: const Text('Join Live', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  )),
              ]),
            ),
          ),
          // Info section
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(session.title, style: TextStyle(color: context.clr.txtPrimary, fontSize: 15, fontWeight: FontWeight.w600)),
              if (session.description != null) ...[
                const SizedBox(height: 4),
                Text(session.description!, style: TextStyle(color: context.clr.txtMuted, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 10),
              Row(children: [
                if (isLive) ...[
                  Icon(Icons.monetization_on, color: context.clr.accentAlt, size: 14),
                  const SizedBox(width: 4),
                  Text('₹${session.totalTips.toStringAsFixed(0)} tips', style: TextStyle(color: context.clr.accentAlt, fontSize: 12)),
                ] else ...[
                  Icon(Icons.schedule, color: context.clr.txtMuted, size: 14),
                  const SizedBox(width: 4),
                  Text(_formatSchedule(session.scheduledAt), style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
                  const Spacer(),
                  OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(80, 32),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      side: BorderSide(color: context.clr.accent),
                    ),
                    child: Text('Remind Me', style: TextStyle(fontSize: 12, color: context.clr.accent)),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatSchedule(String? iso) {
    if (iso == null) return 'TBD';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = dt.difference(now);
      if (diff.inHours < 1) return 'In ${diff.inMinutes}m';
      if (diff.inHours < 24) return 'In ${diff.inHours}h';
      return 'Tomorrow ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

  void _joinLiveSession(LiveSession session) {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => LiveViewScreen(session: session),
      fullscreenDialog: true,
    )).then((_) => SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge));
  }

  Widget _buildCommunityTab() {
    return Column(children: [
      Container(
        color: context.clr.bg,
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Category filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              _filterChip('All', _filterCategory == null, () {
                setState(() => _filterCategory = null);
                _loadPosts();
              }),
              ..._categories.map((c) => _filterChip(
                c[0].toUpperCase() + c.substring(1),
                _filterCategory == c,
                () {
                  setState(() => _filterCategory = _filterCategory == c ? null : c);
                  _loadPosts();
                },
              )),
            ]),
          ),
          const SizedBox(height: 8),
          // Sort row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: [
              Text('Sort:', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
              const SizedBox(width: 8),
              ..._sortOptions.map((s) => _filterChip(
                s['label']!,
                _sortBy == s['key'],
                () => setState(() => _sortBy = s['key']!),
                activeColor: context.clr.accentAlt,
              )),
            ]),
          ),
          const SizedBox(height: 10),
        ]),
      ),
      Expanded(child: _postsLoading
        ? _buildPostShimmer()
        : RefreshIndicator(
            onRefresh: _loadPosts,
            color: context.clr.accent,
            backgroundColor: context.clr.card,
            child: _sortedPosts.isEmpty
                ? Center(child: Text(
                    _filterCategory == null ? 'No posts yet.' : 'No posts in this category.',
                    style: TextStyle(color: context.clr.txtMuted)))
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                    itemCount: _sortedPosts.length,
                    itemBuilder: (_, i) => _buildPostCard(_sortedPosts[i], i),
                  ),
          )),
    ]);
  }

  Widget _filterChip(String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final color = activeColor ?? context.clr.accent;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? color : context.clr.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? color : context.clr.border),
        ),
        child: Text(label, style: TextStyle(color: isSelected ? Colors.white : context.clr.txtSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      ),
    );
  }

  Widget _buildPostCard(CommunityPost post, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clr.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: post.isPinned ? context.clr.accent.withValues(alpha: 0.3) : context.clr.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 20, backgroundColor: context.clr.accent.withValues(alpha: 0.2),
              child: Text(post.authorName[0], style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold))),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(post.authorName, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
              if (post.isVerified == true) ...[SizedBox(width: 4), Icon(Icons.verified, color: context.clr.accent, size: 14)],
            ]),
            if (post.authorSign != null)
              Text(post.authorSign!, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
          ])),
          Text(_timeAgo(post.createdAt), style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
        ]),
        const SizedBox(height: 12),
        Text(post.content, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, height: 1.6)),
        const SizedBox(height: 12),
        Row(children: [
          _actionBtn(Icons.favorite_border, '${post.likesCount}', post.isLiked ? context.clr.error : context.clr.txtMuted, () {
            ApiService.toggleLike(post.id);
            final idx = _posts.indexWhere((p) => p.id == post.id);
            if (idx != -1) setState(() => _posts[idx] = CommunityPost(
              id: post.id, authorName: post.authorName, content: post.content,
              likesCount: post.isLiked ? post.likesCount - 1 : post.likesCount + 1,
              commentsCount: post.commentsCount, isLiked: !post.isLiked,
              createdAt: post.createdAt, authorSign: post.authorSign,
              astrologerName: post.astrologerName, isVerified: post.isVerified,
            ));
          }),
          const SizedBox(width: 20),
          _actionBtn(Icons.chat_bubble_outline, '${post.commentsCount}', context.clr.txtMuted, () => _showCommentsSheet(post)),
          const SizedBox(width: 20),
          _actionBtn(Icons.share_outlined, 'Share', context.clr.txtMuted, () {}),
        ]),
      ]),
    );
  }

  Widget _actionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [Icon(icon, color: color, size: 18), const SizedBox(width: 4), Text(label, style: TextStyle(color: color, fontSize: 12))]),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  // ── Shimmer builders ──────────────────────────────────────────────────────

  Widget _buildFullShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.surface,
      highlightColor: context.clr.surfaceLight,
      child: ListView(padding: const EdgeInsets.all(16), children: [
        _shimmerLiveCard(),
        const SizedBox(height: 12),
        _shimmerLiveCard(),
        const SizedBox(height: 12),
        _shimmerLiveCard(),
      ]),
    );
  }

  Widget _shimmerLiveCard() {
    return Container(
      height: 240,
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(20)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(height: 170, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.vertical(top: Radius.circular(20)))),
        Padding(
          padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(height: 13, width: double.infinity, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 8),
            Container(height: 11, width: 160, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
          ]),
        ),
      ]),
    );
  }

  Widget _buildPostShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.surface,
      highlightColor: context.clr.surfaceLight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: context.clr.surface, shape: BoxShape.circle)),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 12, width: 120, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 10, width: 80, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
              ])),
            ]),
            const SizedBox(height: 12),
            Container(height: 12, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(height: 12, width: 220, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(height: 12, width: 160, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 40, height: 12, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
              const SizedBox(width: 20),
              Container(width: 40, height: 12, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
            ]),
          ]),
        ),
      ),
    );
  }

  // ── Comments sheet ─────────────────────────────────────────────────────────

  void _showCommentsSheet(CommunityPost post) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.clr.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _CommentsSheet(post: post),
    );
  }

  void _showCreatePostSheet() {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: context.clr.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 30),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Share with Community', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
          const SizedBox(height: 16),
          TextField(controller: ctrl, maxLines: 5, autofocus: true, style: TextStyle(color: context.clr.txtPrimary),
              decoration: InputDecoration(hintText: 'What\'s on your mind? Share astrology insights, experiences…', hintStyle: TextStyle(color: context.clr.txtMuted), border: InputBorder.none)),
          const SizedBox(height: 12),
          Row(children: [
            IconButton(icon: Icon(Icons.image_outlined, color: context.clr.txtMuted), onPressed: () {}),
            IconButton(icon: Icon(Icons.tag, color: context.clr.txtMuted), onPressed: () {}),
            const Spacer(),
            ElevatedButton(onPressed: () async {
              if (ctrl.text.trim().isEmpty) return;
              await ApiService.createPost(ctrl.text.trim());
              if (mounted) { Navigator.pop(context); _loadData(); }
            }, child: const Text('Post')),
          ]),
        ]),
      ),
    );
  }
}

// ─── Comments sheet ───────────────────────────────────────────────────────────

class _CommentsSheet extends StatefulWidget {
  final CommunityPost post;
  const _CommentsSheet({required this.post});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  List<dynamic> _comments = [];
  bool _loading = true;
  bool _submitting = false;
  final _ctrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    try {
      final data = await ApiService.getPostComments(widget.post.id);
      if (mounted) setState(() { _comments = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final text = _ctrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.addComment(widget.post.id, text);
      _ctrl.clear();
      await _loadComments();
    } catch (_) {
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (_, scrollCtrl) => Column(children: [
        // Handle
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.clr.border, borderRadius: BorderRadius.circular(2)))),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(children: [
            Text('Comments', style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(width: 8),
            Text('(${widget.post.commentsCount})', style: TextStyle(color: context.clr.txtMuted, fontSize: 14)),
          ]),
        ),
        Divider(height: 1, color: context.clr.border),
        // Comment list
        Expanded(
          child: _loading
              ? Shimmer.fromColors(
                  baseColor: context.clr.surface,
                  highlightColor: context.clr.surfaceLight,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: 4,
                    itemBuilder: (_, __) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Container(width: 34, height: 34, decoration: BoxDecoration(color: context.clr.card, shape: BoxShape.circle)),
                        const SizedBox(width: 10),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(height: 11, width: 100, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(height: 6),
                          Container(height: 11, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(4))),
                          const SizedBox(height: 4),
                          Container(height: 11, width: 180, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(4))),
                        ])),
                      ]),
                    ),
                  ),
                )
              : _comments.isEmpty
                  ? Center(child: Text('No comments yet. Be the first!', style: TextStyle(color: context.clr.txtMuted)))
                  : ListView.builder(
                      controller: scrollCtrl,
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      itemCount: _comments.length,
                      itemBuilder: (_, i) {
                        final c = _comments[i] as Map<String, dynamic>;
                        final author = c['author_name'] ?? c['user_name'] ?? 'User';
                        final content = c['content'] ?? '';
                        final createdAt = c['created_at'] ?? '';
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            CircleAvatar(
                              radius: 17,
                              backgroundColor: context.clr.accent.withValues(alpha: 0.2),
                              child: Text(author.isNotEmpty ? author[0].toUpperCase() : '?',
                                  style: TextStyle(color: context.clr.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 10),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Row(children: [
                                Text(author, style: TextStyle(color: context.clr.txtPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
                                const SizedBox(width: 8),
                                Text(_timeAgo(createdAt), style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
                              ]),
                              const SizedBox(height: 3),
                              Text(content, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, height: 1.5)),
                            ])),
                          ]),
                        );
                      },
                    ),
        ),
        // Input bar
        SafeArea(
          child: Container(
            padding: EdgeInsets.fromLTRB(12, 10, 12, MediaQuery.of(context).viewInsets.bottom + 10),
            decoration: BoxDecoration(color: context.clr.surface, border: Border(top: BorderSide(color: context.clr.border))),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _ctrl,
                  style: TextStyle(color: context.clr.txtPrimary, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Write a comment…',
                    hintStyle: TextStyle(color: context.clr.txtMuted),
                    filled: true,
                    fillColor: context.clr.card,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _submit(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _submitting ? null : _submit,
                child: Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                  child: _submitting
                      ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                ),
              ),
            ]),
          ),
        ),
      ]),
    );
  }

  String _timeAgo(String iso) {
    try {
      final dt = DateTime.parse(iso);
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }
}

// ─── Full-screen Live View ────────────────────────────────────────────────────

class LiveViewScreen extends StatefulWidget {
  final LiveSession session;
  const LiveViewScreen({super.key, required this.session});

  @override
  State<LiveViewScreen> createState() => _LiveViewScreenState();
}

class _LiveViewScreenState extends State<LiveViewScreen> {
  final _chatCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final List<Map<String, String>> _chatMessages = [];
  int _viewerCount = 0;
  final _socket = SocketService.instance;

  // Agora
  RtcEngine? _engine;
  int _remoteUid = 0;
  bool _remoteJoined = false;

  @override
  void initState() {
    super.initState();
    _viewerCount = widget.session.viewerCount;

    // Register listeners BEFORE joining so no events are missed
    _socket.on('viewer_count', (data) {
      if (mounted) setState(() => _viewerCount = (data as Map)['count'] ?? _viewerCount);
    });
    _socket.on('live_chat_message', (data) {
      if (mounted) {
        final d = Map<String, dynamic>.from(data as Map);
        final user = d['user'] ?? 'User';
        setState(() => _chatMessages.add({'user': user, 'message': d['message'] ?? '', 'avatar': user[0].toUpperCase()}));
        _scrollToBottom();
      }
    });
    _socket.on('new_tip', (data) {
      if (mounted) {
        final d = Map<String, dynamic>.from(data as Map);
        final user = d['user'] ?? 'User';
        setState(() => _chatMessages.add({'user': user, 'message': '💎 sent ₹${d['amount']} tip! ${d['message'] ?? ''}', 'avatar': user[0].toUpperCase(), 'isTip': 'true'}));
        _scrollToBottom();
      }
    });

    // Join after listeners are set up
    _socket.joinLive(widget.session.id);
    _initAgora();
  }

  Future<void> _initAgora() async {
    try {
      // uid=0 lets Agora auto-assign a unique uid per viewer
      final tokenData = await ApiService.getAgoraToken(widget.session.id, uid: 0);
      final token = tokenData['data']?['token'] ?? tokenData['token'];
      const appId = 'e2e9d562aa754dcca16a5219e557b133';

      _engine = createAgoraRtcEngine();
      await _engine!.initialize(const RtcEngineContext(appId: appId));
      await _engine!.enableVideo();

      _engine!.registerEventHandler(RtcEngineEventHandler(
        onUserJoined: (_, uid, __) {
          if (mounted) setState(() { _remoteUid = uid; _remoteJoined = true; });
        },
        onUserOffline: (_, uid, __) {
          if (mounted) setState(() => _remoteJoined = false);
        },
      ));

      await _engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      await _engine!.joinChannel(
        token: token ?? '',
        channelId: widget.session.id,
        uid: 0,
        options: const ChannelMediaOptions(
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.clientRoleAudience,
        ),
      );
    } catch (e) {
      debugPrint('Agora audience error: $e');
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _socket.leaveLive(widget.session.id);
    _socket.off('viewer_count');
    _socket.off('live_chat_message');
    _socket.off('new_tip');
    _chatCtrl.dispose();
    _scrollCtrl.dispose();
    _engine?.leaveChannel();
    _engine?.release();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.black,
      body: Stack(children: [
        // ── Full-screen background ──────────────────────────────────────────
        Positioned.fill(child: _buildBackground()),

        // ── Gradient overlays ───────────────────────────────────────────────
        Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter, end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.4), Colors.transparent, Colors.transparent, Colors.black.withOpacity(0.85)],
            stops: const [0.0, 0.25, 0.55, 1.0],
          ),
        ))),

        // ── Top bar: back + astrologer info + LIVE badge ────────────────────
        Positioned(
          top: 0, left: 0, right: 0,
          child: SafeArea(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: Colors.black38, shape: BoxShape.circle),
                child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 16),
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: context.clr.accent.withValues(alpha: 0.3),
              child: Text(widget.session.astrologerName[0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.session.astrologerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
              Text(widget.session.title, style: const TextStyle(color: Colors.white70, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
            ])),
            // Viewer count
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Colors.black38, borderRadius: BorderRadius.circular(10)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.remove_red_eye_outlined, color: Colors.white70, size: 12),
                const SizedBox(width: 4),
                Text('$_viewerCount', style: const TextStyle(color: Colors.white70, fontSize: 11)),
              ]),
            ),
            const SizedBox(width: 8),
            // LIVE badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: context.clr.error, borderRadius: BorderRadius.circular(10)),
              child: const Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.fiber_manual_record, color: Colors.white, size: 8),
                SizedBox(width: 4),
                Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.8)),
              ]),
            ),
          ]),
        ))),

        // ── Chat messages overlay ───────────────────────────────────────────
        Positioned(
          left: 0, right: 0, bottom: 80,
          child: SizedBox(
            height: 220,
            child: ListView.builder(
              controller: _scrollCtrl,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              itemCount: _chatMessages.length,
              itemBuilder: (_, i) => _buildChatBubble(_chatMessages[i]),
            ),
          ),
        ),

        // ── Bottom input bar ────────────────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0, child: _buildInputBar()),
      ]),
    );
  }

  Widget _buildBackground() {
    if (_remoteJoined && _engine != null) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine!,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.session.id),
        ),
      );
    }
    if (widget.session.thumbnailUrl != null) {
      return Image.network(
        widget.session.thumbnailUrl!,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _gradientBackground(),
      );
    }
    return _gradientBackground();
  }

  Widget _gradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.3),
          radius: 1.0,
          colors: [Color(0xFF4A1800), Color(0xFF1A0800), Color(0xFF000000)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(
          radius: 72,
          backgroundColor: context.clr.accent.withValues(alpha: 0.15),
          child: Text(widget.session.astrologerName[0], style: TextStyle(fontSize: 56, color: context.clr.accent, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 20),
        // Decorative stars
        const _StarField(),
      ])),
    );
  }

  Widget _buildChatBubble(Map<String, String> msg) {
    final isTip = msg['isTip'] == 'true';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        // Avatar
        CircleAvatar(
          radius: 14,
          backgroundColor: isTip ? context.clr.accentAlt.withValues(alpha: 0.8) : context.clr.accent.withValues(alpha: 0.7),
          child: Text(msg['avatar'] ?? '?', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(width: 8),
        // Message bubble
        Flexible(child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: isTip ? context.clr.accentAlt.withValues(alpha: 0.25) : Colors.black.withOpacity(0.45),
                borderRadius: BorderRadius.circular(16),
                border: isTip ? Border.all(color: context.clr.accentAlt.withValues(alpha: 0.4)) : null,
              ),
              child: RichText(text: TextSpan(style: const TextStyle(fontSize: 13), children: [
                TextSpan(text: '${msg['user']}  ', style: TextStyle(color: isTip ? context.clr.accentAlt : context.clr.accent, fontWeight: FontWeight.bold, fontSize: 12)),
                TextSpan(text: msg['message'], style: const TextStyle(color: Colors.white, fontSize: 13)),
              ])),
            ),
          ),
        )),
      ]),
    );
  }

  Widget _buildInputBar() {
    return SafeArea(
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            color: Colors.black.withOpacity(0.4),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(children: [
              // Chat input
              Expanded(child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.white.withOpacity(0.15)),
                ),
                child: TextField(
                  controller: _chatCtrl,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Send a message…',
                    hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              )),
              const SizedBox(width: 8),
              // Send button
              GestureDetector(
                onTap: _sendMessage,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
              const SizedBox(width: 8),
              // Gift/tip button
              GestureDetector(
                onTap: _showTipDialog,
                child: Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: context.clr.accentAlt.withValues(alpha: 0.85), shape: BoxShape.circle),
                  child: const Center(child: Text('🎁', style: TextStyle(fontSize: 20))),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _socket.sendLiveChat(widget.session.id, text);
    // Optimistic local add
    setState(() => _chatMessages.add({'user': 'You', 'message': text, 'avatar': 'Y'}));
    _chatCtrl.clear();
    _scrollToBottom();
  }

  void _showTipDialog() {
    double tipAmount = 50;
    final msgCtrl = TextEditingController();
    showModalBottomSheet(
      context: context, backgroundColor: context.clr.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Send a Gift 🎁', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: [50, 100, 200, 500, 1000].map((amt) => GestureDetector(
            onTap: () => setS(() => tipAmount = amt.toDouble()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: tipAmount == amt ? context.clr.accentAlt : context.clr.card,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('₹$amt', style: TextStyle(color: tipAmount == amt ? Colors.black : context.clr.txtSecondary, fontWeight: FontWeight.w600)),
            ),
          )).toList()),
          const SizedBox(height: 12),
          TextField(controller: msgCtrl, style: TextStyle(color: context.clr.txtPrimary),
              decoration: InputDecoration(hintText: 'Add a message…', hintStyle: TextStyle(color: context.clr.txtMuted))),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              _socket.sendTip(widget.session.id, tipAmount, msgCtrl.text);
              Navigator.pop(ctx);
            },
            icon: const Text('🎁'),
            label: Text('Send ₹${tipAmount.toInt()} Gift'),
            style: ElevatedButton.styleFrom(backgroundColor: context.clr.accentAlt, foregroundColor: Colors.black),
          ),
        ]),
      )),
    );
  }
}

// Simple animated star field for background decoration
class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200, height: 80,
      child: CustomPaint(painter: _StarPainter()),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withOpacity(0.6);
    final positions = [
      Offset(20, 10), Offset(60, 30), Offset(100, 8), Offset(140, 25), Offset(180, 12),
      Offset(40, 55), Offset(90, 65), Offset(130, 50), Offset(170, 70), Offset(10, 70),
    ];
    final sizes = [2.0, 1.5, 2.5, 1.0, 2.0, 1.5, 2.0, 1.0, 2.5, 1.5];
    for (int i = 0; i < positions.length; i++) {
      canvas.drawCircle(positions[i], sizes[i], paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
