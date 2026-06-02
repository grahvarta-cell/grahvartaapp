import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/notifications_cubit.dart';
import '../../theme/app_theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => NotificationsCubit()..load(),
      child: const _NotificationsView(),
    );
  }
}

class _NotificationsView extends StatelessWidget {
  const _NotificationsView();

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

  Color _getIconColor(BuildContext context, String? type) {
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
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<NotificationsCubit, NotificationsState>(
      builder: (context, state) {
        final cubit = context.read<NotificationsCubit>();
        final unreadCount = state.unreadCount;

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
                TextButton(
                  onPressed: cubit.markAllRead,
                  child: Text('Mark all read', style: TextStyle(color: context.clr.accent, fontSize: 12)),
                ),
            ],
          ),
          body: state.loading
              ? Center(child: CircularProgressIndicator(color: context.clr.accent))
              : state.notifications.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.notifications_none, size: 64, color: context.clr.txtMuted),
                      const SizedBox(height: 12),
                      Text('No notifications yet', style: TextStyle(color: context.clr.txtMuted)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: cubit.load,
                      color: context.clr.accent,
                      backgroundColor: context.clr.card,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.notifications.length,
                        itemBuilder: (_, i) {
                          final n = state.notifications[i];
                          final isUnread = n['is_read'] == false;
                          final iconColor = _getIconColor(context, n['type']);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isUnread ? context.clr.accent.withValues(alpha: 0.05) : context.clr.card,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isUnread ? context.clr.accent.withValues(alpha: 0.2) : context.clr.border,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: 44, height: 44,
                                decoration: BoxDecoration(
                                  color: iconColor.withValues(alpha: 0.15),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(_getIcon(n['type']), color: iconColor, size: 22),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n['title'] ?? '',
                                  style: TextStyle(
                                    color: context.clr.txtPrimary,
                                    fontSize: 13,
                                    fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                  )),
                                if (n['body'] != null) ...[
                                  const SizedBox(height: 3),
                                  Text(n['body'],
                                    style: TextStyle(color: context.clr.txtMuted, fontSize: 12),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis),
                                ],
                                const SizedBox(height: 4),
                                Text(_timeAgo(n['created_at'] ?? ''),
                                  style: TextStyle(color: context.clr.txtMuted, fontSize: 10)),
                              ])),
                              if (isUnread)
                                Container(
                                  width: 8, height: 8,
                                  decoration: BoxDecoration(color: context.clr.accent, shape: BoxShape.circle),
                                ),
                            ]),
                          );
                        },
                      ),
                    ),
        );
      },
    );
  }
}
