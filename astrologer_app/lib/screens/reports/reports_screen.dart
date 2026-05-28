import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import '../../models/family_member.dart';
import '../../models/report.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../wallet/wallet_screen.dart';
import 'report_detail_screen.dart';
import 'unlocked_reports_screen.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  TabController? _tabController;
  List<Report> _reports = [];
  List<FamilyMember> _familyMembers = [];
  bool _isLoading = true;
  bool _freeUsed = false;
  int _planCredits = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ApiService.getReports(),
        ApiService.getFamilyMembers(),
        ApiService.getReportCredits(),
      ]);
      if (mounted) setState(() {
        _reports = results[0] as List<Report>;
        _familyMembers = results[1] as List<FamilyMember>;
        final credits = results[2] as Map<String, dynamic>;
        _freeUsed = credits['free_used'] as bool? ?? false;
        _planCredits = credits['plan_credits'] as int? ?? 0;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // Group reports by category preserving order
  Map<String, List<Report>> get _grouped {
    final map = <String, List<Report>>{};
    for (final r in _reports) {
      map.putIfAbsent(r.category, () => []).add(r);
    }
    return map;
  }

  void _onReportTap(Report report) async {
    if (_freeUsed && _planCredits <= 0) {
      _showPlansSheet(report, null);
      return;
    }
    final selection = await _showPersonPicker(report);
    if (selection == null) return;
    final familyMemberId = selection['person'] == 'self' ? null : selection['person'] as String?;
    final language = selection['language'] as String? ?? 'English';
    _doUnlockAndNavigate(report, familyMemberId, language: language);
  }

  Future<void> _doUnlockAndNavigate(Report report, String? familyMemberId, {String language = 'English'}) async {
    if (!mounted) return;
    showDialog(context: context, barrierDismissible: false, builder: (_) => const _LoadingDialog());
    try {
      final result = await ApiService.unlockReport(report.id, familyMemberId: familyMemberId, language: language);
      if (!mounted) return;
      Navigator.pop(context); // close loading dialog
      if (mounted) setState(() { _freeUsed = true; if (_planCredits > 0) _planCredits--; });
      final unlockId = result['data']['id'] as String;
      final didRate = await Navigator.push<bool>(context, MaterialPageRoute(
        builder: (_) => ReportDetailScreen(unlockId: unlockId, reportId: report.id),
      ));
      if (didRate == false && mounted) _showRatingDialog(report.id);
    } on ApiException catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // close loading dialog
      if (e.statusCode == 402) {
        // No credits — show plans
        _showPlansSheet(report, familyMemberId);
      } else {
        _showSnack(e.message);
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(e.toString());
    }
  }

  Future<Map<String, dynamic>?> _showPersonPicker(Report report) async {
    final user = context.read<AuthProvider>().user;
    String selectedLanguage = 'English';
    const languages = ['English', 'Hindi', 'Tamil', 'Telugu', 'Bengali', 'Marathi', 'Gujarati', 'Kannada'];

    return showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: context.clr.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) => SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.clr.border, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Generate ${report.name} for', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 17)),
              const SizedBox(height: 4),
              Text('Choose who this report is for', style: TextStyle(color: context.clr.txtMuted, fontSize: 13)),
              const SizedBox(height: 16),
              _personTile(ctx, '🌟', user?.name ?? 'You', 'Self', () => Navigator.pop(ctx, {'person': 'self', 'language': selectedLanguage})),
              if (_familyMembers.isNotEmpty) ...[
                Divider(color: context.clr.border, height: 20),
                ..._familyMembers.map((fm) => _personTile(ctx, '👤', fm.name, fm.relationship ?? 'Family', () => Navigator.pop(ctx, {'person': fm.id, 'language': selectedLanguage}))),
              ],
              Divider(color: context.clr.border, height: 24),
              Text('Report Language', style: TextStyle(color: context.clr.txtSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.clr.border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedLanguage,
                    isExpanded: true,
                    dropdownColor: context.clr.surface,
                    style: TextStyle(color: context.clr.txtPrimary, fontSize: 14),
                    icon: Icon(Icons.keyboard_arrow_down, color: context.clr.txtMuted),
                    items: languages.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                    onChanged: (v) => setS(() => selectedLanguage = v ?? 'English'),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _personTile(BuildContext ctx, String emoji, String name, String sub, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: context.clr.accent.withValues(alpha: 0.15),
        child: Text(emoji, style: const TextStyle(fontSize: 18)),
      ),
      title: Text(name, style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.w600)),
      subtitle: Text(sub, style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
      trailing: Icon(Icons.chevron_right, color: context.clr.txtMuted),
      onTap: onTap,
    );
  }

  void _showPlansSheet(Report report, String? familyMemberId) async {
    List<ReportPlan> plans = [];
    try { plans = await ApiService.getReportPlans(); } catch (_) {}

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: context.clr.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PlansSheet(
        plans: plans,
        report: report,
        onPlanPurchased: () {
          setState(() => _planCredits++);
          Navigator.pop(context);
          _showPersonPickerThenUnlock(report);
        },
        onAddMoney: (ReportPlan plan) async {
          Navigator.pop(context); // close plans sheet
          await Navigator.push(context, MaterialPageRoute(
            builder: (_) => WalletScreen(initialAmount: plan.price.toDouble()),
          ));
          if (!mounted) return;
          // Check if balance is now sufficient — if yes, auto-purchase and unlock
          try {
            final credits = await ApiService.getReportCredits();
            final walletBalance = (credits['wallet_balance'] as num?)?.toDouble() ?? 0.0;
            if (walletBalance >= plan.price) {
              // Auto-buy the plan then show person picker
              showDialog(context: context, barrierDismissible: false, builder: (_) => const _LoadingDialog());
              await ApiService.purchaseReportPlan(plan.name);
              if (!mounted) return;
              Navigator.pop(context); // close loading
              setState(() => _planCredits++);
              _showPersonPickerThenUnlock(report);
            } else {
              // Still insufficient — reopen plans sheet
              _showPlansSheet(report, familyMemberId);
            }
          } catch (_) {
            if (mounted) _showPlansSheet(report, familyMemberId);
          }
        },
      ),
    );
  }

  Future<void> _showPersonPickerThenUnlock(Report report) async {
    final selection = await _showPersonPicker(report);
    if (selection == null) return;
    final familyMemberId = selection['person'] == 'self' ? null : selection['person'] as String?;
    final language = selection['language'] as String? ?? 'English';
    _doUnlockAndNavigate(report, familyMemberId, language: language);
  }

  void _showRatingDialog(String reportId) {
    showDialog(context: context, builder: (_) => _RatingDialog(reportId: reportId));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: context.clr.surface));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.clr.surface,
        title: Text('Astro Reports', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.clr.txtPrimary),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController!,
          indicatorColor: context.clr.accent,
          indicatorWeight: 3,
          labelColor: context.clr.accent,
          unselectedLabelColor: context.clr.txtMuted,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'All Reports'),
            Tab(text: 'My Reports'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController!,
        children: [
          _isLoading
              ? _buildShimmer()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: context.clr.accent,
                  child: _buildBody(),
                ),
          const UnlockedReportsScreen(embedded: true),
        ],
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
          // Banner shimmer
          Container(height: 72, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16))),
          const SizedBox(height: 20),
          // Category label
          Container(height: 14, width: 140, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          // 2-column grid shimmer — 3 rows
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(children: [
              Expanded(child: _shimmerCard()),
              const SizedBox(width: 10),
              Expanded(child: _shimmerCard()),
            ]),
          )),
          const SizedBox(height: 16),
          Container(height: 14, width: 120, decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(6))),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _shimmerCard()),
            const SizedBox(width: 10),
            Expanded(child: _shimmerCard()),
          ]),
        ],
      ),
    );
  }

  Widget _shimmerCard() {
    return Container(
      height: 200,
      decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(16)),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(8))),
          const SizedBox(height: 10),
          Container(height: 12, width: double.infinity, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 6),
          Container(height: 12, width: 80, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 12),
          Container(height: 10, width: double.infinity, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
          const SizedBox(height: 5),
          Container(height: 10, width: 100, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4))),
          const Spacer(),
          Container(height: 30, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(10))),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final grouped = _grouped;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        if (!_freeUsed) ...[
          _buildFreeUnlockBanner(),
          const SizedBox(height: 16),
        ],
        ...grouped.entries.map((entry) => _buildCategory(entry.key, entry.value)),
      ],
    );
  }

  Widget _buildFreeUnlockBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [context.clr.accent.withValues(alpha: 0.2), context.clr.accentAlt.withValues(alpha: 0.1)]),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: context.clr.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('1 Free Report Unlock!', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                SizedBox(height: 2),
                Text('Tap any report to use your free unlock', style: TextStyle(color: context.clr.txtSecondary, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategory(String category, List<Report> reports) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 10),
          child: Row(children: [
            Container(width: 4, height: 18, decoration: BoxDecoration(color: context.clr.accent, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 8),
            Text(category, style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 15, letterSpacing: 0.2)),
          ]),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.63,
          ),
          itemCount: reports.length,
          itemBuilder: (_, i) => _ReportCard(report: reports[i], onTap: () => _onReportTap(reports[i])),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

// ── Report card ───────────────────────────────────────────────────────────────

class _ReportCard extends StatelessWidget {
  final Report report;
  final VoidCallback onTap;

  const _ReportCard({required this.report, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: context.clr.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.clr.border),
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Text(report.icon, style: const TextStyle(fontSize: 34)),
            const SizedBox(height: 8),
            // Name
            Text(report.name, style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            // Rating + unlock count
            Row(children: [
              Icon(Icons.star_rounded, color: context.clr.accentAlt, size: 13),
              const SizedBox(width: 2),
              Text(report.avgRating.toStringAsFixed(1), style: TextStyle(color: context.clr.accentAlt, fontSize: 11, fontWeight: FontWeight.w600)),
              const SizedBox(width: 4),
              Expanded(child: Text('${_formatCount(report.unlockCount)} unlocked', style: TextStyle(color: context.clr.txtMuted, fontSize: 10), overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            // Inclusions — show 2
            ...report.inclusions.take(2).map((inc) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('✓ ', style: TextStyle(color: context.clr.accent, fontSize: 10)),
                Expanded(child: Text(inc, style: TextStyle(color: context.clr.txtSecondary, fontSize: 10), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ]),
            )),
            // Random comment
            if (report.randomComment != null) ...[
              const SizedBox(height: 6),
              Divider(color: context.clr.border, height: 1),
              const SizedBox(height: 6),
              Text('"${report.randomComment!.reviewText}"', style: TextStyle(color: context.clr.txtMuted, fontSize: 10), maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
            const Spacer(),
            // Unlock button
            SizedBox(
              width: double.infinity,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(color: context.clr.accent, borderRadius: BorderRadius.circular(10)),
                child: const Center(child: Text('Unlock', style: TextStyle(color: AppColors.white, fontSize: 12, fontWeight: FontWeight.bold))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}

// ── Plans bottom sheet ────────────────────────────────────────────────────────

class _PlansSheet extends StatefulWidget {
  final List<ReportPlan> plans;
  final Report report;
  final VoidCallback onPlanPurchased;
  final void Function(ReportPlan plan) onAddMoney;

  const _PlansSheet({required this.plans, required this.report, required this.onPlanPurchased, required this.onAddMoney});

  @override
  State<_PlansSheet> createState() => _PlansSheetState();
}

class _PlansSheetState extends State<_PlansSheet> {
  String? _selectedPlan;
  bool _isBuying = false;
  bool _loadingWallet = true;
  double _walletBalance = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchWallet();
  }

  Future<void> _fetchWallet() async {
    try {
      final wallet = await ApiService.getWallet();
      if (mounted) setState(() { _walletBalance = (wallet.balance as num).toDouble(); _loadingWallet = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingWallet = false);
    }
  }

  Future<void> _buy(ReportPlan plan) async {
    if (_walletBalance < plan.price) {
      widget.onAddMoney(plan);
      return;
    }
    setState(() => _isBuying = true);
    try {
      await ApiService.purchaseReportPlan(plan.name);
      if (mounted) widget.onPlanPurchased();
    } catch (e) {
      if (mounted) {
        setState(() => _isBuying = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: context.clr.border, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text('Unlock Report', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 18)),
          const SizedBox(height: 4),
          Text('Choose a plan to unlock ${widget.report.name}', style: TextStyle(color: context.clr.txtMuted, fontSize: 13), textAlign: TextAlign.center),
          const SizedBox(height: 4),
          _loadingWallet
              ? Container(height: 16, width: 120, decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(4)))
              : Text('Wallet Balance: ₹${_walletBalance.toStringAsFixed(0)}', style: TextStyle(color: context.clr.accentAlt, fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          ...widget.plans.map((plan) => _PlanCard(
            plan: plan,
            isSelected: _selectedPlan == plan.name,
            walletBalance: _walletBalance,
            isLoadingWallet: _loadingWallet,
            onSelect: () => setState(() => _selectedPlan = plan.name),
            onBuy: (_isBuying || _loadingWallet) ? null : () => _buy(plan),
          )),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final ReportPlan plan;
  final bool isSelected;
  final double walletBalance;
  final bool isLoadingWallet;
  final VoidCallback onSelect;
  final VoidCallback? onBuy;

  const _PlanCard({required this.plan, required this.isSelected, required this.walletBalance, required this.isLoadingWallet, required this.onSelect, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    final canAfford = !isLoadingWallet && walletBalance >= plan.price;
    final isGold = plan.name == 'gold';
    return GestureDetector(
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? context.clr.accent.withValues(alpha: 0.12) : context.clr.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? context.clr.accent : (isGold ? context.clr.accentAlt.withValues(alpha: 0.5) : context.clr.border), width: isSelected ? 1.5 : 1),
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text(plan.label, style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold, fontSize: 15)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: context.clr.success.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                  child: Text('${plan.discount}% OFF', style: TextStyle(color: context.clr.success, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
                if (isGold)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: context.clr.accentAlt.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text('POPULAR', style: TextStyle(color: context.clr.accentAlt, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
              ]),
              const SizedBox(height: 4),
              Wrap(spacing: 8, runSpacing: 2, crossAxisAlignment: WrapCrossAlignment.center, children: [
                Text('₹${plan.price}', style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold, fontSize: 18)),
                Text('₹${plan.actualPrice}', style: TextStyle(color: context.clr.txtMuted, fontSize: 13, decoration: TextDecoration.lineThrough)),
                Text('${plan.credits} reports unlock', style: TextStyle(color: context.clr.txtSecondary, fontSize: 12)),
              ]),
            ]),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: ElevatedButton(
              onPressed: onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: canAfford ? context.clr.accent : context.clr.surface,
                foregroundColor: canAfford ? AppColors.white : context.clr.txtSecondary,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: canAfford ? BorderSide.none : BorderSide(color: context.clr.border)),
              ),
              child: Text(canAfford ? 'Buy' : 'Add Money', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ),
        ]),
      ),
    );
  }
}

// ── Rating dialog ─────────────────────────────────────────────────────────────

class _RatingDialog extends StatefulWidget {
  final String reportId;
  const _RatingDialog({required this.reportId});

  @override
  State<_RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<_RatingDialog> {
  int _rating = 5;
  final _reviewCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() { _reviewCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    try {
      await ApiService.submitReportReview(widget.reportId, _rating, _reviewCtrl.text.trim());
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: context.clr.card,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Rate this Report', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold)),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        Text('How was your report experience?', style: TextStyle(color: context.clr.txtSecondary, fontSize: 13)),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: List.generate(5, (i) => GestureDetector(
          onTap: () => setState(() => _rating = i + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded, color: context.clr.accentAlt, size: 36),
          ),
        ))),
        const SizedBox(height: 16),
        TextField(
          controller: _reviewCtrl,
          style: TextStyle(color: context.clr.txtPrimary),
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Share your experience (optional)',
            hintStyle: TextStyle(color: context.clr.txtMuted),
            filled: true,
            fillColor: context.clr.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.accent)),
          ),
        ),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text('Skip', style: TextStyle(color: context.clr.txtMuted))),
        ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(backgroundColor: context.clr.accent, foregroundColor: AppColors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: _submitting ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2)) : const Text('Submit'),
        ),
      ],
    );
  }
}

// ── Loading dialog ────────────────────────────────────────────────────────────

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    return const Dialog(
      backgroundColor: context.clr.card,
      child: Padding(
        padding: EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          CircularProgressIndicator(color: context.clr.accent),
          SizedBox(height: 16),
          Text('Generating your report...', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('This may take a few seconds', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
        ]),
      ),
    );
  }
}
