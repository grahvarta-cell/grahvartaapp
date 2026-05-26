import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'astrologer_broadcast_screen.dart';

class AstrologerLiveScreen extends StatefulWidget {
  const AstrologerLiveScreen({super.key});

  @override
  State<AstrologerLiveScreen> createState() => _AstrologerLiveScreenState();
}

class _AstrologerLiveScreenState extends State<AstrologerLiveScreen> {
  List<LiveSession> _sessions = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final sessions = await ApiService.getLiveSessions();
      if (mounted) setState(() { _sessions = sessions; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showCreateSheet() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime? scheduledAt;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Create Live Session', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _modalField(titleCtrl, 'Session Title'),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                style: const TextStyle(color: AppColors.textPrimary),
                decoration: _inputDeco('Description (optional)'),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () async {
                  final picked = await showDateTimePicker(ctx);
                  if (picked != null) setModal(() => scheduledAt = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface, borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      scheduledAt != null
                          ? '${scheduledAt!.day}/${scheduledAt!.month}/${scheduledAt!.year} ${scheduledAt!.hour}:${scheduledAt!.minute.toString().padLeft(2, '0')}'
                          : 'Schedule date & time (optional)',
                      style: TextStyle(color: scheduledAt != null ? AppColors.textPrimary : AppColors.textMuted, fontSize: 14),
                    ),
                  ]),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    if (titleCtrl.text.trim().isEmpty) return;
                    setModal(() => submitting = true);
                    try {
                      await ApiService.createLiveSession({
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Live session created!'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                      }
                    } finally {
                      setModal(() => submitting = false);
                    }
                  },
                  child: submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Create Session'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<DateTime?> showDateTimePicker(BuildContext ctx) async {
    final date = await showDatePicker(
      context: ctx,
      initialDate: DateTime.now().add(const Duration(hours: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
    );
    if (date == null) return null;
    final time = await showTimePicker(context: ctx, initialTime: TimeOfDay.now());
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Widget _modalField(TextEditingController ctrl, String label) => TextField(
    controller: ctrl,
    style: const TextStyle(color: AppColors.textPrimary),
    decoration: _inputDeco(label),
  );

  InputDecoration _inputDeco(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: AppColors.textSecondary),
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange)),
  );

  Future<void> _startSession(String id) async {
    try {
      await ApiService.startLiveSession(id);
      await _load();
      if (mounted) {
        final session = _sessions.firstWhere((s) => s.id == id);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AstrologerBroadcastScreen(session: session),
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  Future<void> _endSession(String id) async {
    try {
      await ApiService.endLiveSession(id);
      await _load();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Session ended')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text('Live Sessions', style: TextStyle(color: AppColors.textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreateSheet,
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('New Session', style: TextStyle(color: Colors.white)),
      ),
      body: _loading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.orange,
              child: _sessions.isEmpty
                  ? const Center(child: Text('No live sessions yet.\nCreate one to get started!', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _sessions.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => _sessionCard(_sessions[i]),
                    ),
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.card,
      highlightColor: AppColors.surface,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 4,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(height: 14, width: 160, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
              Container(height: 24, width: 60, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20))),
            ]),
            const SizedBox(height: 10),
            Container(height: 11, width: 220, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 6),
            Container(height: 11, width: 140, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
            const SizedBox(height: 14),
            Row(children: [
              Container(height: 20, width: 90, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
              const SizedBox(width: 8),
              Container(height: 20, width: 80, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
            ]),
          ]),
        ),
      ),
    );
  }

  Widget _sessionCard(LiveSession session) {
    Color statusColor;
    switch (session.status) {
      case 'live': statusColor = AppColors.error; break;
      case 'ended': statusColor = AppColors.textMuted; break;
      default: statusColor = const Color(0xFFFFD700);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: session.isLive ? AppColors.error.withOpacity(0.4) : AppColors.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(session.title.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' '), style: const TextStyle(color: AppColors.textPrimary, fontSize: 15, fontWeight: FontWeight.bold))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (session.isLive) ...[
                Container(width: 6, height: 6, decoration: BoxDecoration(color: AppColors.error, shape: BoxShape.circle)),
                const SizedBox(width: 4),
              ],
              Text(session.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        if (session.description != null) ...[
          const SizedBox(height: 6),
          Text(session.description!, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          _statPill(Icons.people_outline, '${session.viewerCount} viewers'),
          const SizedBox(width: 8),
          _statPill(Icons.star_outline, '₹${session.totalTips.toStringAsFixed(0)} tips'),
        ]),
        if (session.status == 'scheduled' || session.status == 'live') ...[
          const SizedBox(height: 12),
          Row(children: [
            if (session.status == 'scheduled')
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startSession(session.id),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Go Live'),
                ),
              ),
            if (session.isLive) ...[
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _endSession(session.id),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('End Session'),
                ),
              ),
            ],
          ]),
        ],
      ]),
    );
  }

  Widget _statPill(IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: AppColors.textMuted, size: 14),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
    ]);
  }
}
