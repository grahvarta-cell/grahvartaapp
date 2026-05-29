import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/astrologer.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AstrologerCommunityScreen extends StatefulWidget {
  const AstrologerCommunityScreen({super.key});

  @override
  State<AstrologerCommunityScreen> createState() => _AstrologerCommunityScreenState();
}

class _AstrologerCommunityScreenState extends State<AstrologerCommunityScreen> {
  List<CommunityPost> _posts = [];
  bool _loading = true;
  final _postCtrl = TextEditingController();
  String _selectedCategory = 'general';
  String? _filterCategory; // null = all
  String _sortBy = 'latest'; // latest | liked | commented
  bool _submitting = false;

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

  bool get _hasActiveFilter => _filterCategory != null || _sortBy != 'latest';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _postCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final posts = await ApiService.getCommunityPosts(category: _filterCategory);
      if (mounted) setState(() { _posts = posts; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createPost() async {
    final text = _postCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      await ApiService.createPost(text, category: _selectedCategory);
      _postCtrl.clear();
      await _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Post created!'), backgroundColor: context.clr.success),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _deletePost(String id) async {
    try {
      await ApiService.deletePost(id);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Post deleted')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error));
    }
  }

  Future<void> _toggleLike(String postId) async {
    await ApiService.toggleLike(postId);
    await _load();
  }

  void _openFilterSheet() {
    // local copies so changes only apply on Apply
    String tempCategory = _filterCategory ?? 'all';
    String tempSort = _sortBy;

    showModalBottomSheet(
      context: context,
      backgroundColor: context.clr.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setSheet) {
          return Padding(
            padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).padding.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // handle
                Center(
                  child: Container(
                    width: 40, height: 4,
                    decoration: BoxDecoration(color: context.clr.border, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                const SizedBox(height: 20),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text('Filter & Sort', style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {
                      setSheet(() { tempCategory = 'all'; tempSort = 'latest'; });
                    },
                    child: Text('Reset', style: TextStyle(color: context.clr.accent, fontSize: 13)),
                  ),
                ]),
                const SizedBox(height: 16),

                // Category section
                Text('Category', style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: [
                    _sheetChip('All', tempCategory == 'all', () => setSheet(() => tempCategory = 'all')),
                    ..._categories.map((c) => _sheetChip(
                      c[0].toUpperCase() + c.substring(1),
                      tempCategory == c,
                      () => setSheet(() => tempCategory = c),
                    )),
                  ],
                ),
                const SizedBox(height: 20),

                // Sort section
                Text('Sort By', style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                  children: _sortOptions.map((s) => _sheetChip(
                    s['label']!,
                    tempSort == s['key'],
                    () => setSheet(() => tempSort = s['key']!),
                    activeColor: context.clr.accentAlt,
                  )).toList(),
                ),
                const SizedBox(height: 24),

                // Apply button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      setState(() {
                        _filterCategory = tempCategory == 'all' ? null : tempCategory;
                        _sortBy = tempSort;
                      });
                      _load();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.clr.accent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Apply', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          );
        });
      },
    );
  }

  Widget _sheetChip(String label, bool isSelected, VoidCallback onTap, {Color? activeColor}) {
    final color = activeColor ?? context.clr.accent;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? color : context.clr.card,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? color : context.clr.border),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : context.clr.txtSecondary,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final myName = auth.astrologerProfile?.displayName ?? auth.user?.name ?? '';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.clr.surface,
        title: const Text('Community', style: TextStyle(color: Colors.white)),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.tune_rounded, color: context.clr.txtPrimary),
                onPressed: _openFilterSheet,
                tooltip: 'Filter & Sort',
              ),
              if (_hasActiveFilter)
                Positioned(
                  right: 10, top: 10,
                  child: Container(
                    width: 8, height: 8,
                    decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
        children: [
          _buildComposer(myName),
          Expanded(
            child: _loading
                ? _buildShimmer()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: context.clr.accent,
                    child: _sortedPosts.isEmpty
                        ? Center(child: Text(
                            _filterCategory == null ? 'No posts yet. Share something!' : 'No posts in this category.',
                            style: TextStyle(color: context.clr.txtMuted)))
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: _sortedPosts.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (_, i) => _postCard(_sortedPosts[i], myName),
                          ),
                  ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.card,
      highlightColor: context.clr.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(width: 32, height: 32, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              const SizedBox(width: 8),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Container(width: 120, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
                const SizedBox(height: 6),
                Container(width: 70, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              ]),
            ]),
            const SizedBox(height: 14),
            Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 8),
            Container(width: double.infinity, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 8),
            Container(width: 160, height: 12, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            const SizedBox(height: 14),
            Row(children: [
              Container(width: 40, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
              const SizedBox(width: 16),
              Container(width: 40, height: 10, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(6))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _buildComposer(String myName) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: context.clr.surface,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        const SizedBox(height: 12),
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: context.clr.accent.withValues(alpha: 0.2),
            child: Text(myName.isNotEmpty ? myName[0].toUpperCase() : 'A',
              style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _postCtrl,
              maxLines: 3,
              minLines: 1,
              style: TextStyle(color: context.clr.txtPrimary, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Share a tip, insight, or prediction...',
                hintStyle: TextStyle(color: context.clr.txtMuted),
                filled: true,
                fillColor: context.clr.card,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _submitting ? null : _createPost,
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
              child: _submitting
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _postCard(CommunityPost post, String myName) {
    final isMyPost = (post.astrologerName ?? post.authorName) == myName;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.clr.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.clr.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: context.clr.accent.withValues(alpha: 0.2),
            child: Text(post.authorName[0].toUpperCase(), style: TextStyle(color: context.clr.accent, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text(post.authorName, style: TextStyle(color: context.clr.txtPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              if (post.isVerified == true) ...[
                const SizedBox(width: 4),
                Icon(Icons.verified, color: context.clr.accent, size: 13),
              ],
            ]),
            Text(post.createdAt, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
          ])),
          if (isMyPost)
            IconButton(
              icon: Icon(Icons.delete_outline, color: context.clr.error, size: 18),
              onPressed: () => _deletePost(post.id),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
        ]),
        const SizedBox(height: 10),
        Text(post.content, style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, height: 1.4)),
        const SizedBox(height: 10),
        Row(children: [
          GestureDetector(
            onTap: () => _toggleLike(post.id),
            child: Row(children: [
              Icon(post.isLiked ? Icons.favorite : Icons.favorite_border, color: post.isLiked ? context.clr.error : context.clr.txtMuted, size: 18),
              const SizedBox(width: 4),
              Text('${post.likesCount}', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
            ]),
          ),
          const SizedBox(width: 16),
          Icon(Icons.comment_outlined, color: context.clr.txtMuted, size: 18),
          const SizedBox(width: 4),
          Text('${post.commentsCount}', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
        ]),
      ]),
    );
  }
}
