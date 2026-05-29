import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  List<dynamic> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getNotifications();
      if (mounted) setState(() { _notifications = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _notifications = _demoNotifications(); _isLoading = false; });
    }
  }

  List<Map<String, dynamic>> _demoNotifications() => [
    {'id': '1', 'title': '🔮 Your daily Scorpio prediction is ready', 'body': 'The stars have a special message for you today.', 'type': 'daily_horoscope', 'is_read': false, 'created_at': DateTime.now().subtract(const Duration(hours: 1)).toIso8601String()},
    {'id': '2', 'title': '🔴 Pandit Raj Sharma is Live!', 'body': 'Mercury Retrograde Survival Guide — join now', 'type': 'live_started', 'is_read': false, 'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String()},
    {'id': '3', 'title': '✅ Consultation completed', 'body': 'Your 12-minute session with Dr. Priya Nair — ₹180 charged', 'type': 'consultation_ended', 'is_read': true, 'created_at': DateTime.now().subtract(const Duration(days: 1)).toIso8601String()},
    {'id': '4', 'title': '💰 Wallet credited', 'body': '₹500 added to your wallet successfully', 'type': 'wallet_credit', 'is_read': true, 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
    {'id': '5', 'title': '🌕 Full Moon Alert', 'body': 'Full Moon in Scorpio tonight — powerful time for manifestation!', 'type': 'cosmic_event', 'is_read': true, 'created_at': DateTime.now().subtract(const Duration(days: 3)).toIso8601String()},
    {'id': '6', 'title': '⭐ New review received', 'body': 'Rahul M. left you a 5-star review', 'type': 'review', 'is_read': true, 'created_at': DateTime.now().subtract(const Duration(days: 4)).toIso8601String()},
  ];

  Future<void> _markAllRead() async {
    await ApiService.markAllNotificationsRead();
    setState(() {
      _notifications = _notifications.map((n) => {...n, 'is_read': true}).toList();
    });
  }

  IconData _getIcon(String? type) {
    switch (type) {
      case 'daily_horoscope': return Icons.auto_awesome;
      case 'live_started': return Icons.fiber_manual_record;
      case 'consultation_ended': return Icons.check_circle_outline;
      case 'wallet_credit': return Icons.account_balance_wallet_outlined;
      case 'cosmic_event': return Icons.brightness_3;
      case 'review': return Icons.star_outline;
      default: return Icons.notifications_outlined;
    }
  }

  Color _getIconColor(String? type) {
    switch (type) {
      case 'daily_horoscope': return context.clr.accent;
      case 'live_started': return context.clr.error;
      case 'consultation_ended': return context.clr.success;
      case 'wallet_credit': return context.clr.accentAlt;
      case 'cosmic_event': return const Color(0xFF9C27B0);
      case 'review': return context.clr.accentAlt;
      default: return context.clr.txtMuted;
    }
  }

  String _timeAgo(String iso) {
    try {
      final diff = DateTime.now().difference(DateTime.parse(iso));
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _notifications.where((n) => n['is_read'] == false).length;

    return Scaffold(
      appBar: AppBar(
        title: Row(children: [
          const Text('Notifications'),
          if (unreadCount > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: context.clr.accent, borderRadius: BorderRadius.circular(12)),
              child: Text('$unreadCount', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        actions: [
          if (unreadCount > 0)
            TextButton(onPressed: _markAllRead, child: Text('Mark all read', style: TextStyle(color: context.clr.accent, fontSize: 12))),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.clr.accent))
          : _notifications.isEmpty
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.notifications_none, size: 64, color: context.clr.txtMuted),
                  const SizedBox(height: 12),
                  Text('No notifications yet', style: TextStyle(color: context.clr.txtMuted)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: context.clr.accent,
                  backgroundColor: context.clr.card,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) {
                      final n = _notifications[i];
                      final isUnread = n['is_read'] == false;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUnread ? context.clr.accent.withValues(alpha: 0.05) : context.clr.card,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: isUnread ? context.clr.accent.withValues(alpha: 0.2) : context.clr.border),
                        ),
                        child: Row(children: [
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(color: _getIconColor(n['type']).withOpacity(0.15), shape: BoxShape.circle),
                            child: Icon(_getIcon(n['type']), color: _getIconColor(n['type']), size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(n['title'] ?? '', style: TextStyle(color: context.clr.txtPrimary, fontSize: 13, fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal)),
                            if (n['body'] != null) ...[
                              const SizedBox(height: 3),
                              Text(n['body'], style: TextStyle(color: context.clr.txtMuted, fontSize: 12), maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                            const SizedBox(height: 4),
                            Text(_timeAgo(n['created_at'] ?? ''), style: TextStyle(color: context.clr.txtMuted, fontSize: 10)),
                          ])),
                          if (isUnread)
                            Container(width: 8, height: 8, decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle)),
                        ]),
                      );
                    },
                  ),
                ),
    );
  }
}
