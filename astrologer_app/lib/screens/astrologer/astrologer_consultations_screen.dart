import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../services/api_service.dart';

import '../../theme/app_theme.dart';
import 'astrologer_chat_screen.dart';
import 'astrologer_call_screen.dart';

class AstrologerConsultationsScreen extends StatefulWidget {
  const AstrologerConsultationsScreen({super.key});

  @override
  State<AstrologerConsultationsScreen> createState() => _AstrologerConsultationsScreenState();
}

// Allow parent to trigger a refresh via GlobalKey
class AstrologerConsultationsKey extends GlobalKey<_AstrologerConsultationsScreenState> {
  const AstrologerConsultationsKey() : super.constructor();
  void refresh() => currentState?._loadConsultations();
}

class _AstrologerConsultationsScreenState extends State<AstrologerConsultationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  final Map<String, List<Map<String, dynamic>>> _consultations = {
    'active': [],
    'completed': [],
    'all': [],
  };
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
    _loadConsultations();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadConsultations() async {
    setState(() => _loading = true);
    try {
      final all = await ApiService.getAstrologerConsultations();
      if (!mounted) return;
      final items = all.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      setState(() {
        _consultations['all'] = items;
        _consultations['active'] = items.where((c) => ['active', 'accepted'].contains(c['status'])).toList();
        _consultations['completed'] = items.where((c) => ['completed', 'cancelled', 'missed'].contains(c['status'])).toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.clr.surface,
        title: const Text('Consultations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: context.clr.txtPrimary),
            onPressed: _loadConsultations,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: context.clr.accent,
          labelColor: context.clr.accent,
          unselectedLabelColor: context.clr.txtMuted,
          labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          tabs: [
            Tab(text: 'Active (${_consultations['active']!.length})'),
            const Tab(text: 'Completed'),
            const Tab(text: 'All'),
          ],
        ),
      ),
      body: _loading
          ? _buildShimmer()
          : TabBarView(
              controller: _tabCtrl,
              children: [
                _buildList(_consultations['active']!),
                _buildList(_consultations['completed']!),
                _buildList(_consultations['all']!),
              ],
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.card,
      highlightColor: context.clr.surface,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        itemBuilder: (_, __) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(children: [
            const CircleAvatar(radius: 24, backgroundColor: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Container(height: 13, width: 110, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                Container(height: 18, width: 56, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
              ]),
              const SizedBox(height: 8),
              Container(height: 11, width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              const SizedBox(height: 6),
              Container(height: 10, width: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            ])),
          ]),
        ),
      ),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, color: context.clr.txtMuted, size: 48),
            const SizedBox(height: 12),
            Text('No consultations', style: TextStyle(color: context.clr.txtMuted, fontSize: 14)),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadConsultations,
      color: context.clr.accent,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        itemBuilder: (_, i) => _buildCard(items[i]),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> c) {
    final status = c['status'] ?? 'completed';
    final type = c['type'] ?? 'chat';
    final userName = ((c['user_name'] ?? c['user']?['name'] ?? 'User') as String)
        .split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    final avatarUrl = c['user_avatar'] ?? c['user']?['avatar_url'];
    final isOnline = c['user_online'] ?? false;
    final durationSec = c['duration_seconds'] ?? 0;
    final amount = double.tryParse(c['total_amount']?.toString() ?? '0') ?? 0;
    final createdAt = _formatDate(c['created_at'] ?? '');
    final isActive = ['active', 'accepted'].contains(status);

    return GestureDetector(
      onTap: isActive ? () => _openActiveConsultation(c) : null,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isActive ? context.clr.accent.withValues(alpha: 0.4) : context.clr.border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: context.clr.accent.withValues(alpha: 0.2),
                  backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                  child: avatarUrl == null
                      ? Text(userName[0].toUpperCase(),
                          style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold, fontSize: 18))
                      : null,
                ),
                if (isOnline)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 10, height: 10,
                      decoration: BoxDecoration(
                        color: context.clr.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: context.clr.card, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(userName,
                          style: TextStyle(color: context.clr.txtPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
                      ),
                      _statusBadge(status),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _typeIcon(type),
                      const SizedBox(width: 4),
                      Text(_typeLabel(type),
                        style: TextStyle(color: context.clr.txtSecondary, fontSize: 12)),
                      const SizedBox(width: 8),
                      if (durationSec > 0) ...[
                        Icon(Icons.access_time, color: context.clr.txtMuted, size: 12),
                        const SizedBox(width: 2),
                        Text(_formatDuration(durationSec as int),
                          style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
                        const SizedBox(width: 8),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(createdAt, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
                      if (amount > 0)
                        Text('₹${amount.toStringAsFixed(0)}',
                          style: TextStyle(color: context.clr.success, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: context.clr.accent.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.arrow_forward_ios_rounded, color: context.clr.accent, size: 14),
              ),
          ],
        ),
      ),
    );
  }

  void _openActiveConsultation(Map<String, dynamic> c) {
    final type = c['type'] ?? 'chat';
    final consultationId = c['id'] ?? '';
    final userId = c['user']?['id']?.toString() ?? c['user_id']?.toString();
    final userName = ((c['user_name'] ?? c['user']?['name'] ?? 'User') as String)
        .split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
    if (type == 'chat') {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AstrologerChatScreen(consultationId: consultationId, userName: userName, userId: userId),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => AstrologerCallScreen(
          consultationId: consultationId,
          userName: userName,
          type: type,
          onEnd: () => Navigator.pop(context),
        ),
      ));
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'active': color = context.clr.success; label = 'Active'; break;
      case 'accepted': color = context.clr.accent; label = 'Accepted'; break;
      case 'completed': color = Colors.blue; label = 'Done'; break;
      case 'cancelled': color = context.clr.error; label = 'Cancelled'; break;
      case 'missed': color = Colors.orange; label = 'Missed'; break;
      default: color = context.clr.txtMuted; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w600)),
    );
  }

  Widget _typeIcon(String type) {
    IconData icon;
    Color color;
    switch (type) {
      case 'voice': icon = Icons.phone_rounded; color = Colors.green; break;
      case 'video': icon = Icons.videocam_rounded; color = Colors.blue; break;
      default: icon = Icons.chat_bubble_rounded; color = context.clr.accent;
    }
    return Icon(icon, size: 13, color: color);
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'voice': return 'Audio Call';
      case 'video': return 'Video Call';
      default: return 'Chat';
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return s > 0 ? '${m}m ${s}s' : '${m}m';
  }

  String _formatDate(String iso) {
    if (iso.isEmpty) return '';
    try {
      final dt = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inHours < 1) return '${diff.inMinutes}m ago';
      if (diff.inDays < 1) return '${diff.inHours}h ago';
      if (diff.inDays == 1) return 'Yesterday';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return '';
    }
  }
}
