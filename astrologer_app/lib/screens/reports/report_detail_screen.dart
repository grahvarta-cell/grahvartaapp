import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/report.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class ReportDetailScreen extends StatefulWidget {
  final String unlockId;
  final String reportId;

  const ReportDetailScreen({super.key, required this.unlockId, required this.reportId});

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  ReportUnlock? _unlock;
  bool _isLoading = true;
  bool _hasRated = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final data = await ApiService.getReportDetail(widget.unlockId);
      if (mounted) setState(() { _unlock = data; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _onWillPop() async {
    // Return false to caller if user hasn't rated → triggers rating dialog
    Navigator.pop(context, !_hasRated);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildShimmer(),
      );
    }
    if (_unlock == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, iconTheme: const IconThemeData(color: AppColors.textPrimary)),
        body: const Center(child: Text('Report not found', style: TextStyle(color: AppColors.textSecondary))),
      );
    }
    return PopScope(
      canPop: false,
      onPopInvoked: (_) => _onWillPop(),
      child: _buildContent(),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: AppColors.surface,
      highlightColor: AppColors.surfaceLight,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card shimmer
            Container(
              height: 100,
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
            ),
            const SizedBox(height: 20),
            // Section blocks
            ...List.generate(4, (_) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Container(
                decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16)),
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // Section title
                  Row(children: [
                    Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(2))),
                    const SizedBox(width: 8),
                    Container(height: 13, width: 160, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
                  ]),
                  const SizedBox(height: 12),
                  // Body lines
                  Container(height: 11, width: double.infinity, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 11, width: double.infinity, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
                  const SizedBox(height: 6),
                  Container(height: 11, width: 200, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(4))),
                ]),
              ),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    final unlock = _unlock!;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: _onWillPop,
        ),
        centerTitle: false,
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(unlock.reportName,
                style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 16),
                overflow: TextOverflow.ellipsis),
            Text('For ${unlock.personLabel}',
                style: const TextStyle(color: AppColors.orange, fontSize: 12)),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AppColors.orange.withOpacity(0.2), AppColors.gold.withOpacity(0.08)]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.orange.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Text(unlock.icon, style: const TextStyle(fontSize: 48)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(unlock.reportName,
                          style: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
                      const SizedBox(height: 4),
                      Text(unlock.category, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text('For ${unlock.personLabel}',
                            style: const TextStyle(color: AppColors.orange, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (unlock.aiContent != null)
              _buildAiContent(unlock.aiContent!)
            else
              const Center(child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Report content is being generated...', style: TextStyle(color: AppColors.textSecondary)),
              )),
            const SizedBox(height: 32),
            _buildRateButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildAiContent(String content) {
    // Parse lines into sections — heading = ## or # lines
    final lines = content.split('\n');
    final sections = <Map<String, String>>[];
    String? currentTitle;
    final bodyLines = <String>[];

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('##') || (trimmed.startsWith('#') && !trimmed.startsWith('###'))) {
        // Save previous section
        if (bodyLines.isNotEmpty || currentTitle != null) {
          sections.add({'title': currentTitle ?? '', 'body': bodyLines.join('\n').trim()});
          bodyLines.clear();
        }
        currentTitle = trimmed.replaceAll(RegExp(r'^#+\s*'), '').trim();
      } else {
        bodyLines.add(trimmed);
      }
    }
    // Save last section
    if (bodyLines.isNotEmpty || currentTitle != null) {
      sections.add({'title': currentTitle ?? '', 'body': bodyLines.join('\n').trim()});
    }

    // If no sections detected, show full content as one block
    if (sections.isEmpty || (sections.length == 1 && sections[0]['title']!.isEmpty)) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
        child: Text(_cleanMarkdown(content), style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, height: 1.7)),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: sections.map((section) {
        final title = section['title'] ?? '';
        final body = _cleanMarkdown(section['body'] ?? '');
        if (body.isEmpty && title.isEmpty) return const SizedBox.shrink();
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.border)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (title.isNotEmpty) ...[
                Row(children: [
                  Container(width: 4, height: 16, decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 8),
                  Expanded(child: Text(title, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.bold, fontSize: 14))),
                ]),
                const SizedBox(height: 10),
              ],
              if (body.isNotEmpty)
                Text(body, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13, height: 1.7)),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _cleanMarkdown(String text) {
    return text
        .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'\*(.+?)\*'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'__(.+?)__'), (m) => m[1]!)
        .replaceAllMapped(RegExp(r'`(.+?)`'), (m) => m[1]!)
        .replaceAll(RegExp(r'^[-*]\s+', multiLine: true), '• ')
        .replaceAll(RegExp(r'^\d+\.\s+', multiLine: true), '')
        .replaceAll(RegExp(r'^---+$', multiLine: true), '')
        .trim();
  }

  Widget _buildRateButton() {
    if (_hasRated) {
      return const Center(child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle, color: AppColors.success, size: 18),
        SizedBox(width: 6),
        Text('Thanks for your rating!', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600)),
      ]));
    }
    return OutlinedButton.icon(
      onPressed: _showRatingDialog,
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.orange,
        side: const BorderSide(color: AppColors.orange),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        minimumSize: const Size(double.infinity, 0),
      ),
      icon: const Icon(Icons.star_border_rounded),
      label: const Text('Rate this Report', style: TextStyle(fontWeight: FontWeight.w600)),
    );
  }

  void _showRatingDialog() {
    showDialog(
      context: context,
      builder: (_) => _InlineRatingDialog(
        reportId: widget.reportId,
        onSubmitted: () => setState(() => _hasRated = true),
      ),
    );
  }
}

// ── Inline rating dialog (used from detail screen directly) ──────────────────

class _InlineRatingDialog extends StatefulWidget {
  final String reportId;
  final VoidCallback onSubmitted;
  const _InlineRatingDialog({required this.reportId, required this.onSubmitted});

  @override
  State<_InlineRatingDialog> createState() => _InlineRatingDialogState();
}

class _InlineRatingDialogState extends State<_InlineRatingDialog> {
  int _rating = 5;
  final _ctrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.submitReportReview(widget.reportId, _rating, _ctrl.text.trim());
      widget.onSubmitted();
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Rate this Report', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const Text('How useful was this report?', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded, color: AppColors.gold, size: 36),
          ),
        ))),
        const SizedBox(height: 16),
        TextField(
          controller: _ctrl,
          style: const TextStyle(color: AppColors.textPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Share your thoughts (optional)',
            hintStyle: const TextStyle(color: AppColors.textMuted),
            filled: true, fillColor: AppColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Skip', style: TextStyle(color: AppColors.textMuted))),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Text('Submit'),
        ),
      ],
    );
  }
}
