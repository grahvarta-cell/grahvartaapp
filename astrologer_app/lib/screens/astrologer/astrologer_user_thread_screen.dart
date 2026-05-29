import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AstrologerUserThreadScreen extends StatefulWidget {
  final String userId;
  final String userName;

  const AstrologerUserThreadScreen({super.key, required this.userId, required this.userName});

  @override
  State<AstrologerUserThreadScreen> createState() => _AstrologerUserThreadScreenState();
}

class _AstrologerUserThreadScreenState extends State<AstrologerUserThreadScreen> {
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

  void _onScroll() {
    if (_scrollController.position.pixels <= 80 && _hasMore && !_loadingMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    if (widget.userId.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final data = await ApiService.getAstrologerUserMessages(widget.userId);
      final msgs = List<dynamic>.from(data['messages'] ?? []);
      if (mounted) {
        setState(() {
          _messages = msgs;
          _hasMore = data['has_more'] == true;
          _oldestTimestamp = msgs.isNotEmpty ? msgs.first['created_at'] : null;
          _isLoading = false;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _oldestTimestamp == null) return;
    setState(() => _loadingMore = true);
    try {
      final data = await ApiService.getAstrologerUserMessages(widget.userId, before: _oldestTimestamp);
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

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
  }

  String _timeLabel(String iso) {
    try {
      final dt = DateTime.parse(iso).toLocal();
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) { return ''; }
  }

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
    final initials = widget.userName.split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

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
            Text(widget.userName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.clr.txtPrimary)),
            Text('All sessions', style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
          ]),
        ]),
      ),
      bottomNavigationBar: _buildFooter(),
      body: _isLoading
          ? _buildShimmer()
          : Column(children: [
              if (_loadingMore)
                LinearProgressIndicator(color: context.clr.accent, backgroundColor: context.clr.surface),
              Expanded(child: _buildMessageList()),
            ]),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.card,
      highlightColor: context.clr.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 10,
        itemBuilder: (_, i) {
          final isMe = i % 3 != 0;
          final width = (i % 3 == 0 ? 200.0 : i % 3 == 1 ? 150.0 : 240.0);
          return Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              margin: const EdgeInsets.only(bottom: 10),
              width: width,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isMe ? 18 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 18),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMessageList() {
    if (_messages.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.chat_bubble_outline_rounded, color: context.clr.txtMuted, size: 48),
        const SizedBox(height: 12),
        Text('No messages yet with ${widget.userName}', style: TextStyle(color: context.clr.txtMuted, fontSize: 13)),
      ]));
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
      itemCount: _messages.length,
      itemBuilder: (_, i) {
        final msg = _messages[i];
        final prev = i > 0 ? _messages[i - 1] : null;
        final showDate = prev == null || _dateHeader(msg['created_at']) != _dateHeader(prev['created_at']);
        return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if (showDate) _buildDateHeader(_dateHeader(msg['created_at'])),
          _buildBubble(msg),
        ]);
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
            decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.clr.border)),
            child: Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
          ),
        ),
        Expanded(child: Divider(color: context.clr.border)),
      ]),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final type = msg['message_type'] ?? 'text';
    final role = msg['sender_role'] ?? msg['sender_type'] ?? 'user';

    if (type == 'session_start' || type == 'session_end') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Center(child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: context.clr.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.clr.accent.withValues(alpha: 0.2)),
          ),
          child: Text(msg['message'] ?? msg['content'] ?? '', style: TextStyle(color: context.clr.accent, fontSize: 11, fontWeight: FontWeight.w500)),
        )),
      );
    }

    final isMe = role == 'astrologer';
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Center(child: Text(widget.userName[0].toUpperCase(), style: TextStyle(color: context.clr.accent, fontSize: 12, fontWeight: FontWeight.w700))),
            ),
            const SizedBox(width: 6),
          ],
          Flexible(child: Column(
            crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.68),
                decoration: BoxDecoration(
                  color: isMe ? context.clr.accent : context.clr.card,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isMe ? 18 : 4),
                    bottomRight: Radius.circular(isMe ? 4 : 18),
                  ),
                  border: isMe ? null : Border.all(color: context.clr.border),
                ),
                child: Text(
                  msg['message'] ?? msg['content'] ?? '',
                  style: TextStyle(color: isMe ? Colors.white : context.clr.txtPrimary, fontSize: 13, height: 1.4),
                ),
              ),
              const SizedBox(height: 2),
              Text(_timeLabel(msg['created_at'] ?? ''), style: TextStyle(color: context.clr.txtMuted, fontSize: 10)),
            ],
          )),
          if (isMe) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).viewPadding.bottom + 12),
      decoration: BoxDecoration(color: context.clr.surface, border: Border(top: BorderSide(color: context.clr.border))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(Icons.lock_outline_rounded, color: context.clr.txtMuted, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text('Read-only history. Consult with this user to chat.', style: TextStyle(color: context.clr.txtMuted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(color: context.clr.accent, borderRadius: BorderRadius.circular(10)),
            child: const Text('Back', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
