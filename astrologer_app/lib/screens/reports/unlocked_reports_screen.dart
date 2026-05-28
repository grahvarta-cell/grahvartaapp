import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/report.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import 'report_detail_screen.dart';

class UnlockedReportsScreen extends StatefulWidget {
  final bool embedded;
  const UnlockedReportsScreen({super.key, this.embedded = false});

  @override
  State<UnlockedReportsScreen> createState() => _UnlockedReportsScreenState();
}

class _UnlockedReportsScreenState extends State<UnlockedReportsScreen> {
  List<ReportUnlock> _unlocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getUnlockedReports();
      if (mounted) setState(() { _unlocks = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.embedded ? null : AppBar(
        backgroundColor: context.clr.surface,
        title: Text('My Reports', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.clr.txtPrimary),
        elevation: 0,
      ),
      body: _isLoading
          ? _buildShimmer()
          : RefreshIndicator(
              onRefresh: _load,
              color: context.clr.accent,
              child: _unlocks.isEmpty ? _buildEmpty() : _buildList(),
            ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: context.clr.surface,
      highlightColor: context.clr.surfaceLight,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          // Category label
          Container(height: 12, width: 100, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          ...List.generate(5, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              height: 76,
              decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.all(14),
              child: Row(children: [
                Container(width: 50, height: 50, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(12))),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(height: 13, width: double.infinity, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 7),
                  Container(height: 11, width: 100, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 10, width: 70, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
                ])),
              ]),
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Text('📭', style: TextStyle(fontSize: 64)),
        const SizedBox(height: 16),
        Text('No unlocked reports yet', style: TextStyle(color: context.clr.txtSecondary, fontSize: 16)),
        const SizedBox(height: 8),
        Text('Go to Reports and unlock your first one', style: TextStyle(color: context.clr.txtMuted, fontSize: 13)),
        const SizedBox(height: 24),
        OutlinedButton(
          onPressed: () => Navigator.pop(context),
          style: OutlinedButton.styleFrom(foregroundColor: context.clr.accent, side: BorderSide(color: context.clr.accent), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          child: const Text('Browse Reports'),
        ),
      ]),
    );
  }

  Widget _buildList() {
    // Group by category
    final grouped = <String, List<ReportUnlock>>{};
    for (final u in _unlocks) {
      grouped.putIfAbsent(u.category, () => []).add(u);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: grouped.entries.map((entry) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, bottom: 10),
            child: Text(entry.key, style: TextStyle(color: context.clr.txtMuted, fontSize: 12, fontWeight: FontWeight.w600, letterSpacing: 0.8)),
          ),
          ...entry.value.map((u) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _UnlockCard(unlock: u),
          )),
        ],
      )).toList(),
    );
  }
}

class _UnlockCard extends StatelessWidget {
  final ReportUnlock unlock;
  const _UnlockCard({required this.unlock});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ReportDetailScreen(unlockId: unlock.id, reportId: unlock.reportId),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: context.clr.border),
        ),
        child: Row(children: [
          Container(
            width: 50, height: 50,
            decoration: BoxDecoration(color: context.clr.accent.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(unlock.icon, style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(unlock.reportName, style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 3),
            Text('For ${unlock.personLabel}', style: TextStyle(color: context.clr.accent, fontSize: 12, fontWeight: FontWeight.w500)),
            const SizedBox(height: 3),
            Text(_formatDate(unlock.createdAt), style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, color: context.clr.txtMuted, size: 16),
        ]),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw).toLocal();
      const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
      return '${d.day} ${months[d.month - 1]} ${d.year}';
    } catch (_) { return ''; }
  }
}
