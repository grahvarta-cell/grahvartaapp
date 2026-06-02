import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';
import '../../blocs/marketplace/marketplace_cubit.dart';
import '../../blocs/marketplace/marketplace_state.dart';
import '../../l10n/app_strings.dart';
import '../../models/astrologer.dart';
import '../../theme/app_theme.dart';
import 'astrologer_profile_screen.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _specializations = [
    'All', 'Vedic', 'Tarot', 'Numerology', 'Vastu', 'KP System', 'Western', 'Palmistry', 'Face Reading'
  ];

  static const _specialColors = [
    Color(0xFF027DFD),
    Color(0xFFF25D50),
    Color(0xFF6200EE),
    Color(0xFF1CDAC5),
    Color(0xFF0553B1),
    Color(0xFFE8762A),
  ];
  Color _cardAccent(int index) => _specialColors[index % _specialColors.length];

  static const _categoryColors = <String, Color>{
    'Vedic':        Color(0xFF027DFD),
    'Tarot':        Color(0xFF6200EE),
    'Numerology':   Color(0xFFF25D50),
    'Palmistry':    Color(0xFF1CDAC5),
    'Vastu':        Color(0xFFE8762A),
    'KP System':    Color(0xFF0553B1),
    'Western':      Color(0xFF9C27B0),
    'Face Reading': Color(0xFFF25D50),
  };

  final List<Map<String, String>> _sortOptions = [
    {'key': 'rating',     'label': 'Top Rated'},
    {'key': 'experience', 'label': 'Experience'},
    {'key': 'popular',    'label': 'Popular'},
    {'key': 'price_low',  'label': 'Price: Low'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<MarketplaceCubit>().load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocBuilder<MarketplaceCubit, MarketplaceState>(
        builder: (context, state) {
          final isLoading = state is MarketplaceLoading || state is MarketplaceInitial;
          final loaded = state is MarketplaceLoaded ? state : null;

          return NestedScrollView(
            headerSliverBuilder: (_, __) => [
              SliverToBoxAdapter(child: _buildHeader(loaded)),
              SliverToBoxAdapter(child: _buildSearchBar(loaded)),
              SliverToBoxAdapter(child: _buildFilters(loaded)),
              SliverToBoxAdapter(child: _buildSpecializationChips(loaded)),
            ],
            body: isLoading
                ? _buildShimmer()
                : RefreshIndicator(
                    onRefresh: () => context.read<MarketplaceCubit>().load(),
                    color: context.clr.accent,
                    backgroundColor: context.clr.card,
                    child: state is MarketplaceError
                        ? ListView(children: [
                            const SizedBox(height: 80),
                            Center(child: Icon(Icons.error_outline, size: 64, color: context.clr.error)),
                            const SizedBox(height: 16),
                            Center(child: Text('Could not load astrologers', style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
                            const SizedBox(height: 8),
                            Center(child: Text('Pull down to retry', style: TextStyle(color: context.clr.txtMuted, fontSize: 13))),
                          ])
                        : loaded != null && loaded.astrologers.isEmpty
                            ? ListView(children: [
                                const SizedBox(height: 80),
                                Center(child: Icon(Icons.search_off_rounded, size: 64, color: context.clr.txtMuted)),
                                const SizedBox(height: 16),
                                Center(child: Text('No astrologers found', style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.w600))),
                                const SizedBox(height: 8),
                                Center(child: Text('Try changing your filters or check back later', style: TextStyle(color: context.clr.txtMuted, fontSize: 13))),
                              ])
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                                itemCount: loaded?.astrologers.length ?? 0,
                                itemBuilder: (_, i) => _buildAstrologerCard(loaded!.astrologers[i], i),
                              ),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.surface,
      highlightColor: context.clr.surfaceLight,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
        itemCount: 5,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(20)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 64, height: 64, decoration: BoxDecoration(color: context.clr.surfaceLight, shape: BoxShape.circle)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(height: 14, width: 140, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 11, width: 100, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 8),
                Container(height: 11, width: 160, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(4))),
              ])),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Container(height: 22, width: 70, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(8))),
                const SizedBox(height: 8),
                Container(height: 14, width: 55, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(4))),
              ]),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Container(height: 26, width: 60, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 6),
              Container(height: 26, width: 55, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(10))),
              const SizedBox(width: 6),
              Container(height: 26, width: 50, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(10))),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: Container(height: 38, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 38, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(12)))),
              const SizedBox(width: 8),
              Expanded(child: Container(height: 38, decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(12)))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildHeader(MarketplaceLoaded? loaded) {
    final onlineCount = loaded?.astrologers.where((a) => a.isOnline).length ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 56, 20, 8),
      child: Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(context.s.talkToAstrologers, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
          const SizedBox(height: 2),
          Text('$onlineCount online now', style: TextStyle(color: context.clr.accent, fontSize: 13)),
        ])),
        IconButton(icon: Icon(Icons.tune_rounded, color: context.clr.txtPrimary), onPressed: () => _showFilterSheet(loaded)),
      ]),
    );
  }

  Widget _buildSearchBar(MarketplaceLoaded? loaded) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.clr.border)),
        child: TextField(
          style: TextStyle(color: context.clr.txtPrimary),
          decoration: InputDecoration(
            hintText: context.s.searchHint,
            hintStyle: TextStyle(color: context.clr.txtMuted),
            prefixIcon: Icon(Icons.search, color: context.clr.txtMuted),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (q) => context.read<MarketplaceCubit>().search(q),
        ),
      ),
    );
  }

  Widget _buildFilters(MarketplaceLoaded? loaded) {
    final onlineOnly = loaded?.onlineOnly ?? false;
    final selectedSort = loaded?.sortBy ?? 'rating';
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(children: [
        _filterChip('Online Only', onlineOnly, (_) => context.read<MarketplaceCubit>().toggleOnline()),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(children: _sortOptions.map((s) {
              final isSelected = s['key'] == selectedSort;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: GestureDetector(
                  onTap: () => context.read<MarketplaceCubit>().changeSortBy(s['key']!),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected ? context.clr.accent : context.clr.card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? context.clr.accent : context.clr.border),
                    ),
                    child: Text(s['label']!, style: TextStyle(color: isSelected ? Colors.white : context.clr.txtSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                  ),
                ),
              );
            }).toList()),
          ),
        ),
      ]),
    );
  }

  Widget _filterChip(String label, bool value, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: value ? context.clr.accent.withValues(alpha: 0.15) : context.clr.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: value ? context.clr.accent : context.clr.border),
        ),
        child: Row(children: [
          if (value) Icon(Icons.check, color: context.clr.accent, size: 14),
          if (value) const SizedBox(width: 4),
          Text(label, style: TextStyle(color: value ? context.clr.accent : context.clr.txtSecondary, fontSize: 12)),
        ]),
      ),
    );
  }

  Widget _buildSpecializationChips(MarketplaceLoaded? loaded) {
    final selectedSpec = loaded?.selectedSpecialization;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SizedBox(
        height: 44,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: _specializations.length,
          itemBuilder: (_, i) {
            final spec = _specializations[i];
            final isSelected = (spec == 'All' && selectedSpec == null) || spec == selectedSpec;
            final chipColor = _categoryColors[spec] ?? context.clr.accent;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => context.read<MarketplaceCubit>().filterSpecialization(spec == 'All' ? null : spec),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? chipColor : context.clr.surfaceLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(spec, style: TextStyle(color: isSelected ? Colors.white : context.clr.txtSecondary, fontSize: 12, fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAstrologerCard(Astrologer astrologer, int index) {
    final accent = _cardAccent(index);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AstrologerProfileScreen(astrologer: astrologer))),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: context.clr.border),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            _buildAvatar(astrologer, accent),
            const SizedBox(width: 12),
            Expanded(child: _buildAstrologerInfo(astrologer)),
            _buildOnlineIndicator(astrologer, accent),
          ]),
          const SizedBox(height: 12),
          _buildSpecChips(astrologer),
          const SizedBox(height: 12),
          _buildConsultButtons(astrologer),
        ]),
      ),
    );
  }

  Widget _buildAvatar(Astrologer astrologer, Color accent) {
    return Stack(children: [
      CircleAvatar(
        radius: 32,
        backgroundColor: accent.withValues(alpha: 0.2),
        backgroundImage: astrologer.avatarUrl != null ? NetworkImage(astrologer.avatarUrl!) : null,
        child: astrologer.avatarUrl == null
            ? Text(astrologer.displayName[0], style: TextStyle(color: accent, fontSize: 22, fontWeight: FontWeight.bold))
            : null,
      ),
      if (astrologer.isOnline)
        Positioned(bottom: 2, right: 2, child: Container(
          width: 13, height: 13,
          decoration: BoxDecoration(color: context.clr.success, shape: BoxShape.circle, border: Border.all(color: context.clr.card, width: 2)),
        )),
    ]);
  }

  Widget _buildAstrologerInfo(Astrologer astrologer) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Text(astrologer.displayName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.clr.txtPrimary)),
        const SizedBox(width: 4),
        if (astrologer.isVerified) Icon(Icons.verified, color: context.clr.accent, size: 14),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        RatingBarIndicator(rating: astrologer.rating, itemSize: 13, itemBuilder: (_, __) => Icon(Icons.star, color: context.clr.accentAlt)),
        const SizedBox(width: 4),
        Text('${astrologer.ratingFormatted} (${astrologer.reviewCount})', style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
      ]),
      const SizedBox(height: 4),
      Row(children: [
        _infoTag(Icons.work_outline, astrologer.experienceText),
        const SizedBox(width: 8),
        _infoTag(Icons.people_outline, '${astrologer.totalConsultations}+ clients'),
      ]),
    ]);
  }

  Widget _infoTag(IconData icon, String text) {
    return Row(children: [
      Icon(icon, size: 11, color: context.clr.txtMuted),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
    ]);
  }

  Widget _buildOnlineIndicator(Astrologer astrologer, Color accent) {
    return Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: astrologer.isOnline ? context.clr.success.withValues(alpha: 0.15) : context.clr.border,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          astrologer.isOnline ? 'Available' : 'Offline',
          style: TextStyle(color: astrologer.isOnline ? context.clr.success : context.clr.txtMuted, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ),
      if (astrologer.queueCount > 0) ...[
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
          child: Text('${astrologer.queueCount} in queue', style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.w600)),
        ),
      ],
      const SizedBox(height: 6),
      Text('₹${astrologer.perMinuteRateChat.toInt()}/min', style: TextStyle(color: accent, fontSize: 13, fontWeight: FontWeight.bold)),
    ]);
  }

  Widget _buildSpecChips(Astrologer astrologer) {
    return Wrap(spacing: 6, runSpacing: 4, children: [
      ...astrologer.specializations.take(3).map((s) {
        final c = _categoryColors[s] ?? context.clr.accent;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(color: c.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: c.withValues(alpha: 0.3))),
          child: Text(s, style: TextStyle(color: c, fontSize: 11)),
        );
      }),
      ...astrologer.languages.take(2).map((l) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: context.clr.surfaceLight, borderRadius: BorderRadius.circular(10)),
        child: Text(l, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
      )),
    ]);
  }

  Widget _buildConsultButtons(Astrologer astrologer) {
    return Row(children: [
      Expanded(child: _consultBtn(Icons.chat_bubble_outline, 'Chat', context.clr.accent, () => _startConsultation(astrologer, 'chat'))),
      const SizedBox(width: 8),
      Expanded(child: _consultBtn(Icons.phone_outlined, 'Call', const Color(0xFF4CAF50), () => _startConsultation(astrologer, 'voice'))),
      const SizedBox(width: 8),
      Expanded(child: _consultBtn(Icons.videocam_outlined, 'Video', const Color(0xFF2196F3), () => _startConsultation(astrologer, 'video'))),
    ]);
  }

  Widget _consultBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, color: Colors.white, size: 15),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }

  void _startConsultation(Astrologer astrologer, String type) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AstrologerProfileScreen(astrologer: astrologer, startType: type)));
  }

  void _showFilterSheet(MarketplaceLoaded? loaded) {
    final cubit = context.read<MarketplaceCubit>();
    final selectedSort = loaded?.sortBy ?? 'rating';
    showModalBottomSheet(
      context: context,
      backgroundColor: context.clr.surface,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) => StatefulBuilder(
        builder: (_, setSheet) => SizedBox(
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(context.s.filterSort, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.clr.txtPrimary)),
              const SizedBox(height: 20),
              Text(context.s.sortBy, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13)),
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 3.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: _sortOptions.map((s) {
                  final isSel = s['key'] == selectedSort;
                  return GestureDetector(
                    onTap: () {
                      cubit.changeSortBy(s['key']!);
                      Navigator.pop(sheetCtx);
                    },
                    child: Container(
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isSel ? context.clr.accent : context.clr.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: isSel ? context.clr.accent : context.clr.border),
                      ),
                      child: Text(s['label']!, style: TextStyle(color: isSel ? Colors.white : context.clr.txtSecondary, fontSize: 13, fontWeight: isSel ? FontWeight.w600 : FontWeight.normal)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
            ]),
          ),
        ),
      ),
    );
  }
}
