import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'thread_screen.dart';

class ChatHistoryScreen extends StatefulWidget {
  const ChatHistoryScreen({super.key});

  @override
  State<ChatHistoryScreen> createState() => _ChatHistoryScreenState();
}

class _ChatHistoryScreenState extends State<ChatHistoryScreen> {
  List<dynamic> _threads = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ApiService.getChatThreads();
      if (mounted) setState(() { _threads = data; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _isLoading = false; _error = e.toString(); });
    }
  }

  String _timeLabel(String? iso) {
    if (iso == null) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: const Text('Chat History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
            onPressed: () {},
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : _error != null
              ? _buildError()
              : _threads.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.orange,
                  backgroundColor: AppColors.card,
                  child: ListView.separated(
                    itemCount: _threads.length,
                    separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.border, indent: 76),
                    itemBuilder: (_, i) => _ThreadTile(thread: _threads[i], timeLabel: _timeLabel(_threads[i]['last_message_at'])),
                  ),
                ),
    );
  }

  Widget _buildError() => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.wifi_off_rounded, color: AppColors.textMuted, size: 48),
        const SizedBox(height: 16),
        const Text('Could not load chats', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(_error ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 12), textAlign: TextAlign.center),
        const SizedBox(height: 20),
        ElevatedButton.icon(
          onPressed: _load,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Retry'),
        ),
      ]),
    ),
  );

  Widget _buildEmpty() => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(color: AppColors.card, shape: BoxShape.circle),
        child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.textMuted, size: 36),
      ),
      const SizedBox(height: 16),
      const Text('No conversations yet', style: TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w600)),
      const SizedBox(height: 6),
      const Text('Start a consultation to begin chatting', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
    ]),
  );
}

class _ThreadTile extends StatelessWidget {
  final Map<String, dynamic> thread;
  final String timeLabel;

  const _ThreadTile({required this.thread, required this.timeLabel});

  @override
  Widget build(BuildContext context) {
    final unread = int.tryParse(thread['unread_count']?.toString() ?? '0') ?? 0;
    final rating = double.tryParse(thread['rating']?.toString() ?? '0') ?? 0.0;
    final initials = (thread['astrologer_name'] as String? ?? '?')
        .split(' ').map((w) => w.isNotEmpty ? w[0] : '').take(2).join().toUpperCase();

    return InkWell(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ThreadScreen(
          astrologerId: thread['astrologer_id']?.toString() ?? '',
          astrologerName: thread['astrologer_name']?.toString() ?? 'Astrologer',
          astrologerAvatar: thread['astrologer_avatar']?.toString(),
          rating: rating,
        )),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(children: [
          // Avatar
          Stack(children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: AppColors.orange.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Center(child: Text(initials, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w700, fontSize: 16))),
            ),
            // Online indicator placeholder
            Positioned(
              bottom: 2, right: 2,
              child: Container(
                width: 12, height: 12,
                decoration: BoxDecoration(
                  color: AppColors.success,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.background, width: 2),
                ),
              ),
            ),
          ]),
          const SizedBox(width: 12),

          // Name + last message
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(
                  thread['astrologer_name'] ?? 'Astrologer',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 14,
                  ),
                )),
                Text(timeLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
              ]),
              const SizedBox(height: 3),
              Row(children: [
                Expanded(child: Text(
                  thread['last_message'] ?? 'Start a conversation',
                  style: TextStyle(
                    color: unread > 0 ? AppColors.textSecondary : AppColors.textMuted,
                    fontSize: 12,
                    fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )),
                if (unread > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(10)),
                    child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ],
              ]),
            ],
          )),
        ]),
      ),
    );
  }
}
