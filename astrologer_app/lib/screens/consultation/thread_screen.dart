import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ThreadScreen extends StatefulWidget {
  final String astrologerId;
  final String astrologerName;
  final String? astrologerAvatar;
  final double rating;

  const ThreadScreen({
    super.key,
    required this.astrologerId,
    required this.astrologerName,
    this.astrologerAvatar,
    this.rating = 0,
  });

  @override
  State<ThreadScreen> createState() => _ThreadScreenState();
}

class _ThreadScreenState extends State<ThreadScreen> {
  final _scrollController = ScrollController();
  List<dynamic> _messages = [];
  bool _isLoading = true;
  bool _hasMore = true;
  bool _loadingMore = false;
  String? _oldestTimestamp;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Load more when scrolled to top (older messages)
  void _onScroll() {
    if (_scrollController.position.pixels <= 80 && _hasMore && !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (widget.astrologerId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await ApiService.getThreadMessages(widget.astrologerId);
      final msgs = List<dynamic>.from(data['messages'] ?? []);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _hasMore = data['has_more'] == true;
          _oldestTimestamp = msgs.isNotEmpty ? msgs.first['created_at'] : null;
          _isLoading = false;
        });
        // Scroll to bottom after load
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom(animate: false));
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _oldestTimestamp == null) return;
    setState(() => _loadingMore = true);
    try {
      final data = await ApiService.getThreadMessages(widget.astrologerId, before: _oldestTimestamp);
      final older = List<dynamic>.from(data['messages'] ?? []);
      if (mounted) {
        setState(() {
          _messages = [...older, ..._messages];
          _hasMore = data['has_more'] == true;
          _oldestTimestamp = older.isNotEmpty ? older.first['created_at'] : _oldestTimestamp;
          _loadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  void _scrollToBottom({bool animate = false}) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    if (animate) {
      _scrollController.animateTo(max, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _scrollController.jumpTo(max);
    }
  }

  String _timeLabel(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) { return ''; }
  }

  // Group messages by date for date headers
  String _dateHeader(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final msgDay = DateTime(dt.year, dt.month, dt.day);
      if (msgDay == today) return 'Today';
      if (msgDay == today.subtract(const Duration(days: 1))) return 'Yesterday';
      return '${dt.day} ${_monthName(dt.month)} ${dt.year}';
    } catch (_) { return ''; }
  }

  String _monthName(int m) => const ['', 'Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][m];

  @override
  Widget build(BuildContext context) {
    final initials = widget.astrologerName
        .split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.clr.surface,
        titleSpacing: 0,
        title: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: context.clr.accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: context.clr.accent.withValues(alpha: 0.3)),
            ),
            child: Center(child: Text(initials, style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.w700, fontSize: 13))),
          ),
          const SizedBox(width: 10),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.astrologerName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.clr.txtPrimary)),
            Row(children: [
              Icon(Icons.star_rounded, color: context.clr.accentAlt, size: 12),
              const SizedBox(width: 2),
              Text(widget.rating.toStringAsFixed(1), style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
              const SizedBox(width: 6),
              Text('All sessions', style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ]),
          ]),
        ]),
        actions: [
          IconButton(icon: Icon(Icons.call_rounded, color: context.clr.txtSecondary, size: 20), onPressed: () {}),
          IconButton(icon: Icon(Icons.videocam_rounded, color: context.clr.txtSecondary, size: 20), onPressed: () {}),
        ],
      ),
      bottomNavigationBar: _buildReadOnlyFooter(),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.clr.accent))
          : Column(children: [
              if (_loadingMore)
                LinearProgressIndicator(color: context.clr.accent, backgroundColor: context.clr.surface),
              Expanded(child: _buildMessageList()),
            ]),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.chat_bubble_outline_rounded, color: context.clr.txtMuted, size: 48),
          const SizedBox(height: 12),
          Text('No messages yet with ${widget.astrologerName}', style: TextStyle(color: context.clr.txtMuted, fontSize: 13)),
        ]),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final prev = i > 0 ? _messages[i - 1] : null;

        // Show date header when date changes
        final showDate = prev == null ||
            _dateHeader(msg['created_at']) != _dateHeader(prev['created_at']);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _buildDateHeader(_dateHeader(msg['created_at'])),
            _buildBubble(msg),
          ],
        );
      },
    );
  }

  Widget _buildDateHeader(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(child: Divider(color: context.clr.border)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: context.clr.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.clr.border),
            ),
            child: Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
          ),
        ),
        Expanded(child: Divider(color: context.clr.border)),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final type = msg['message_type'] ?? 'text';
    final role = msg['sender_role'] ?? 'user';

    // Session divider
    if (type == 'session_start' || type == 'session_end') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: context.clr.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: context.clr.accent.withValues(alpha: 0.2)),
            ),
            child: Text(msg['message'] ?? '', style: TextStyle(color: context.clr.accent, fontSize: 11, fontWeight: FontWeight.w500)),
          ),
        ),
      );
    }

    final isUser = role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text('A', style: TextStyle(color: context.clr.accent, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                  decoration: BoxDecoration(
                    color: isUser ? context.clr.accent : context.clr.card,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null : Border.all(color: context.clr.border),
                  ),
                  child: Text(
                    msg['message'] ?? '',
                    style: TextStyle(
                      color: isUser ? Colors.white : context.clr.txtPrimary,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _timeLabel(msg['created_at'] ?? ''),
                  style: TextStyle(color: context.clr.txtMuted, fontSize: 10),
                ),
              ],
            ),
          ),
          if (isUser) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildReadOnlyFooter() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: context.clr.surface,
        border: Border(top: BorderSide(color: context.clr.border)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(Icons.lock_outline_rounded, color: context.clr.txtMuted, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Read-only history. Start a new consultation to chat.',
            style: TextStyle(color: context.clr.txtMuted, fontSize: 12),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: context.clr.accent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
