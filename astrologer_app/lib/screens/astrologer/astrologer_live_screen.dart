import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shimmer/shimmer.dart';
import '../../cubits/live_cubit.dart';
import '../../models/astrologer.dart';
import '../../theme/app_theme.dart';
import 'astrologer_broadcast_screen.dart';

class AstrologerLiveScreen extends StatelessWidget {
  const AstrologerLiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => LiveCubit()..load(),
      child: const _AstrologerLiveView(),
    );
  }
}

class _AstrologerLiveView extends StatelessWidget {
  const _AstrologerLiveView();

  void _showCreateSheet(BuildContext context, LiveCubit cubit) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.clr.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        DateTime? scheduledAt;
        bool submitting = false;
        return StatefulBuilder(
          builder: (ctx, setModal) => Padding(
            padding: EdgeInsets.only(left: 24, right: 24, top: 24, bottom: MediaQuery.of(ctx).viewInsets.bottom + 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create Live Session', style: TextStyle(color: context.clr.txtPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _modalField(context, titleCtrl, 'Session Title'),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  style: TextStyle(color: context.clr.txtPrimary),
                  decoration: _inputDeco(context, 'Description (optional)'),
                ),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await _showDateTimePicker(ctx);
                    if (picked != null) setModal(() => scheduledAt = picked);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: context.clr.surface, borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: context.clr.border),
                    ),
                    child: Row(children: [
                      Icon(Icons.calendar_today, color: context.clr.txtMuted, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        scheduledAt != null
                            ? '${scheduledAt!.day}/${scheduledAt!.month}/${scheduledAt!.year} ${scheduledAt!.hour}:${scheduledAt!.minute.toString().padLeft(2, '0')}'
                            : 'Schedule date & time (optional)',
                        style: TextStyle(color: scheduledAt != null ? context.clr.txtPrimary : context.clr.txtMuted, fontSize: 14),
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
                      final success = await cubit.createSession({
                        'title': titleCtrl.text.trim(),
                        'description': descCtrl.text.trim(),
                        if (scheduledAt != null) 'scheduled_at': scheduledAt!.toIso8601String(),
                      });
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(success ? 'Live session created!' : 'Failed to create session'),
                        backgroundColor: success ? context.clr.success : context.clr.error,
                      ));
                    },
                    child: submitting
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Text('Create Session'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<DateTime?> _showDateTimePicker(BuildContext ctx) async {
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

  Widget _modalField(BuildContext context, TextEditingController ctrl, String label) => TextField(
    controller: ctrl,
    style: TextStyle(color: context.clr.txtPrimary),
    decoration: _inputDeco(context, label),
  );

  InputDecoration _inputDeco(BuildContext context, String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: context.clr.txtSecondary),
    filled: true,
    fillColor: context.clr.surface,
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.accent)),
  );

  Future<void> _startSession(BuildContext context, LiveCubit cubit, String id, List<LiveSession> sessions) async {
    final success = await cubit.startSession(id);
    if (!context.mounted) return;
    if (success) {
      try {
        final session = sessions.firstWhere((s) => s.id == id);
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => AstrologerBroadcastScreen(session: session),
        ));
      } catch (_) {}
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('Failed to start session'), backgroundColor: context.clr.error),
      );
    }
  }

  Future<void> _endSession(BuildContext context, LiveCubit cubit, String id) async {
    final success = await cubit.endSession(id);
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(success ? 'Session ended' : 'Failed to end session')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<LiveCubit, LiveState>(
      builder: (context, state) {
        final cubit = context.read<LiveCubit>();
        return Scaffold(
          appBar: AppBar(
            backgroundColor: context.clr.surface,
            title: const Text('Live Sessions', style: TextStyle(color: Colors.white)),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _showCreateSheet(context, cubit),
            backgroundColor: context.clr.accent,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('New Session', style: TextStyle(color: Colors.white)),
          ),
          body: state.loading
              ? _buildShimmer(context)
              : RefreshIndicator(
                  onRefresh: cubit.load,
                  color: context.clr.accent,
                  child: state.sessions.isEmpty
                      ? Center(child: Text('No live sessions yet.\nCreate one to get started!',
                          textAlign: TextAlign.center, style: TextStyle(color: context.clr.txtMuted)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: state.sessions.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (_, i) => _sessionCard(context, cubit, state.sessions[i], state.sessions),
                        ),
                ),
        );
      },
    );
  }

  Widget _buildShimmer(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: context.clr.card,
      highlightColor: context.clr.surface,
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

  Widget _sessionCard(BuildContext context, LiveCubit cubit, LiveSession session, List<LiveSession> sessions) {
    Color statusColor;
    switch (session.status) {
      case 'live': statusColor = context.clr.error; break;
      case 'ended': statusColor = context.clr.txtMuted; break;
      default: statusColor = const Color(0xFFFFD700);
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.clr.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: session.isLive ? context.clr.error.withValues(alpha: 0.4) : context.clr.border),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(
            session.title.split(' ').map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}').join(' '),
            style: TextStyle(color: context.clr.txtPrimary, fontSize: 15, fontWeight: FontWeight.bold),
          )),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (session.isLive) ...[
                Container(width: 6, height: 6, decoration: BoxDecoration(color: context.clr.error, shape: BoxShape.circle)),
                const SizedBox(width: 4),
              ],
              Text(session.status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ]),
          ),
        ]),
        if (session.description != null) ...[
          const SizedBox(height: 6),
          Text(session.description!, style: TextStyle(color: context.clr.txtSecondary, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        Row(children: [
          _statPill(context, Icons.people_outline, '${session.viewerCount} viewers'),
          const SizedBox(width: 8),
          _statPill(context, Icons.star_outline, '₹${session.totalTips.toStringAsFixed(0)} tips'),
        ]),
        if (session.status == 'scheduled' || session.status == 'live') ...[
          const SizedBox(height: 12),
          Row(children: [
            if (session.status == 'scheduled')
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _startSession(context, cubit, session.id, sessions),
                  style: ElevatedButton.styleFrom(backgroundColor: context.clr.success, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('Go Live'),
                ),
              ),
            if (session.isLive)
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _endSession(context, cubit, session.id),
                  style: ElevatedButton.styleFrom(backgroundColor: context.clr.error, foregroundColor: Colors.white, elevation: 0),
                  child: const Text('End Session'),
                ),
              ),
          ]),
        ],
      ]),
    );
  }

  Widget _statPill(BuildContext context, IconData icon, String label) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: context.clr.txtMuted, size: 14),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
    ]);
  }
}
