import 'package:flutter/material.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class AstrologerEarningsScreen extends StatefulWidget {
  const AstrologerEarningsScreen({super.key});

  @override
  State<AstrologerEarningsScreen> createState() => _AstrologerEarningsScreenState();
}

class _AstrologerEarningsScreenState extends State<AstrologerEarningsScreen> {
  Map<String, dynamic>? _wallet;
  List<dynamic> _transactions = [];
  List<dynamic> _withdrawals = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    final walletFuture = ApiService.getAstrologerWallet().catchError((_) => <String, dynamic>{});
    final txFuture = ApiService.getAstrologerTransactions().catchError((_) => <dynamic>[]);
    final wdFuture = ApiService.getWithdrawals().catchError((_) => <dynamic>[]);
    final results = await Future.wait([walletFuture, txFuture, wdFuture]);
    if (mounted) {
      setState(() {
        final walletResp = results[0] as Map<String, dynamic>;
        _wallet = walletResp['data'] as Map<String, dynamic>? ?? walletResp;
        _transactions = results[1] as List;
        _withdrawals = results[2] as List;
        _loading = false;
      });
    }
  }

  void _showWithdrawalSheet() {
    final amountCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final accountCtrl = TextEditingController();
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 24,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request Withdrawal', style: TextStyle(color: AppColors.textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _modalField(amountCtrl, 'Amount (₹)', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _modalField(bankCtrl, 'Bank Name'),
              const SizedBox(height: 12),
              _modalField(accountCtrl, 'Account Number', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _modalField(ifscCtrl, 'IFSC Code'),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: submitting ? null : () async {
                    final amount = double.tryParse(amountCtrl.text);
                    if (amount == null || amount <= 0) return;
                    setModalState(() => submitting = true);
                    try {
                      await ApiService.requestWithdrawal(amount, {
                        'bank_name': bankCtrl.text.trim(),
                        'account_number': accountCtrl.text.trim(),
                        'ifsc_code': ifscCtrl.text.trim(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      await _load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Withdrawal request submitted!'), backgroundColor: AppColors.success),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
                      }
                    } finally {
                      setModalState(() => submitting = false);
                    }
                  },
                  child: submitting
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Submit Request'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _modalField(TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.orange)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          title: const Text('Earnings & Wallet', style: TextStyle(color: AppColors.textPrimary)),
          bottom: const TabBar(
            indicatorColor: AppColors.orange,
            labelColor: AppColors.orange,
            unselectedLabelColor: AppColors.textMuted,
            tabs: [Tab(text: 'Transactions'), Tab(text: 'Withdrawals')],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.account_balance_wallet_outlined, color: AppColors.textPrimary),
              onPressed: _showWithdrawalSheet,
              tooltip: 'Request Withdrawal',
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
            : Column(
                children: [
                  _buildWalletCard(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildTransactionsList(),
                        _buildWithdrawalsList(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildWalletCard() {
    final walletData = _wallet?['wallet'] as Map? ?? _wallet ?? {};
    final statsData = _wallet?['stats'] as Map? ?? {};
    final balance = double.tryParse(walletData['balance']?.toString() ?? '0') ?? 0;
    final totalEarned = double.tryParse(walletData['total_earned']?.toString() ?? '0') ?? 0;
    final thisMonth = double.tryParse(statsData['this_month']?.toString() ?? '0') ?? 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.orange, AppColors.orange.withOpacity(0.7)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Available Balance', style: TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 4),
          Text('₹${balance.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('Lifetime: ₹${totalEarned.toStringAsFixed(2)}', style: const TextStyle(color: Colors.white60, fontSize: 12)),
          const SizedBox(height: 12),
          Row(children: [
            _walletStat('This Month', '₹${thisMonth.toStringAsFixed(0)}'),
            const SizedBox(width: 24),
            _walletStat('Total Earned', '₹${totalEarned.toStringAsFixed(0)}'),
          ]),
        ],
      ),
    );
  }

  Widget _walletStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    ],
  );

  Widget _buildTransactionsList() {
    if (_transactions.isEmpty) {
      return const Center(child: Text('No transactions yet', style: TextStyle(color: AppColors.textMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = _transactions[i] as Map;
        final isCredit = (t['type_label'] ?? t['type'] ?? '') == 'credit' || t['type'] == 'earning';
        final amount = double.tryParse(t['amount']?.toString() ?? '0') ?? 0;
        final sessionType = (t['type']?.toString() ?? 'chat').toUpperCase();
        final userName = t['user_name']?.toString() ?? 'User';
        final duration = int.tryParse(t['duration_seconds']?.toString() ?? '0') ?? 0;
        final durationLabel = duration > 0 ? ' · ${duration ~/ 60}m ${duration % 60}s' : '';
        String dateLabel = '';
        try {
          final dt = DateTime.parse(t['created_at'].toString()).toLocal();
          dateLabel = '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2,'0')}:${dt.minute.toString().padLeft(2,'0')}';
        } catch (_) { dateLabel = t['created_at']?.toString() ?? ''; }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward, color: AppColors.success, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$sessionType with $userName$durationLabel', style: const TextStyle(color: AppColors.textPrimary, fontSize: 13)),
              const SizedBox(height: 2),
              Text(dateLabel, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            Text('+₹${amount.toStringAsFixed(0)}',
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        );
      },
    );
  }

  Widget _buildWithdrawalsList() {
    if (_withdrawals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.account_balance_outlined, color: AppColors.textMuted, size: 48),
            const SizedBox(height: 12),
            const Text('No withdrawal requests', style: TextStyle(color: AppColors.textMuted)),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _showWithdrawalSheet, child: const Text('Request Withdrawal')),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: _withdrawals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final w = _withdrawals[i] as Map;
        final status = w['status'] ?? 'pending';
        Color statusColor;
        switch (status) {
          case 'approved': statusColor = AppColors.success; break;
          case 'rejected': statusColor = AppColors.error; break;
          default: statusColor = const Color(0xFFFFD700);
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            const Icon(Icons.account_balance_outlined, color: AppColors.textMuted, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('₹${double.tryParse(w['amount']?.toString() ?? '0')?.toStringAsFixed(0)}',
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(w['created_at'] ?? '', style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      },
    );
  }
}
