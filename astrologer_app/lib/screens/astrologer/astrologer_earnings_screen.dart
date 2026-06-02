import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../cubits/earnings_cubit.dart';
import '../../theme/app_theme.dart';

class AstrologerEarningsScreen extends StatelessWidget {
  const AstrologerEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => EarningsCubit()..load(),
      child: const _AstrologerEarningsView(),
    );
  }
}

class _AstrologerEarningsView extends StatelessWidget {
  const _AstrologerEarningsView();

  void _showWithdrawalSheet(BuildContext context, EarningsCubit cubit) {
    final amountCtrl = TextEditingController();
    final bankCtrl = TextEditingController();
    final ifscCtrl = TextEditingController();
    final accountCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.clr.card,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        bool submitting = false;
        return StatefulBuilder(
          builder: (ctx, setModalState) => Padding(
            padding: EdgeInsets.only(
              left: 24, right: 24, top: 24,
              bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Request Withdrawal', style: TextStyle(color: context.clr.txtPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _modalField(context, amountCtrl, 'Amount (₹)', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _modalField(context, bankCtrl, 'Bank Name'),
                const SizedBox(height: 12),
                _modalField(context, accountCtrl, 'Account Number', keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                _modalField(context, ifscCtrl, 'IFSC Code'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: submitting ? null : () async {
                      final amount = double.tryParse(amountCtrl.text);
                      if (amount == null || amount <= 0) return;
                      setModalState(() => submitting = true);
                      final success = await cubit.requestWithdrawal(amount, {
                        'bank_name': bankCtrl.text.trim(),
                        'account_number': accountCtrl.text.trim(),
                        'ifsc_code': ifscCtrl.text.trim(),
                      });
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(success ? 'Withdrawal request submitted!' : 'Failed to submit request'),
                          backgroundColor: success ? context.clr.success : context.clr.error,
                        ));
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
        );
      },
    );
  }

  Widget _modalField(BuildContext context, TextEditingController ctrl, String label, {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: TextStyle(color: context.clr.txtPrimary),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: context.clr.txtSecondary),
        filled: true,
        fillColor: context.clr.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.clr.accent)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<EarningsCubit, EarningsState>(
      builder: (context, state) {
        final cubit = context.read<EarningsCubit>();
        return DefaultTabController(
          length: 2,
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: context.clr.surface,
              title: const Text('Earnings & Wallet', style: TextStyle(color: Colors.white)),
              bottom: TabBar(
                indicatorColor: context.clr.accent,
                labelColor: context.clr.accent,
                unselectedLabelColor: context.clr.txtMuted,
                tabs: const [Tab(text: 'Transactions'), Tab(text: 'Withdrawals')],
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.account_balance_wallet_outlined, color: context.clr.txtPrimary),
                  onPressed: () => _showWithdrawalSheet(context, cubit),
                  tooltip: 'Request Withdrawal',
                ),
              ],
            ),
            body: state.loading
                ? Center(child: CircularProgressIndicator(color: context.clr.accent))
                : Column(
                    children: [
                      _buildWalletCard(context, state),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildTransactionsList(context, state),
                            _buildWithdrawalsList(context, state, cubit),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        );
      },
    );
  }

  Widget _buildWalletCard(BuildContext context, EarningsState state) {
    final walletData = state.wallet?['wallet'] as Map? ?? state.wallet ?? {};
    final statsData = state.wallet?['stats'] as Map? ?? {};
    final balance = double.tryParse(walletData['balance']?.toString() ?? '0') ?? 0;
    final totalEarned = double.tryParse(walletData['total_earned']?.toString() ?? '0') ?? 0;
    final thisMonth = double.tryParse(statsData['this_month']?.toString() ?? '0') ?? 0;
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [context.clr.accent, context.clr.accent.withValues(alpha: 0.7)],
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

  Widget _buildTransactionsList(BuildContext context, EarningsState state) {
    if (state.transactions.isEmpty) {
      return Center(child: Text('No transactions yet', style: TextStyle(color: context.clr.txtMuted)));
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.transactions.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final t = state.transactions[i] as Map;
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
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.clr.border)),
          child: Row(children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: context.clr.success.withValues(alpha: 0.15), shape: BoxShape.circle),
              child: Icon(Icons.arrow_downward, color: context.clr.success, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('$sessionType with $userName$durationLabel', style: TextStyle(color: context.clr.txtPrimary, fontSize: 13)),
              const SizedBox(height: 2),
              Text(dateLabel, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ])),
            Text('+₹${amount.toStringAsFixed(0)}',
              style: TextStyle(color: context.clr.success, fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
        );
      },
    );
  }

  Widget _buildWithdrawalsList(BuildContext context, EarningsState state, EarningsCubit cubit) {
    if (state.withdrawals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_outlined, color: context.clr.txtMuted, size: 48),
            const SizedBox(height: 12),
            Text('No withdrawal requests', style: TextStyle(color: context.clr.txtMuted)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _showWithdrawalSheet(context, cubit),
              child: const Text('Request Withdrawal'),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.withdrawals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, i) {
        final w = state.withdrawals[i] as Map;
        final status = w['status'] ?? 'pending';
        Color statusColor;
        switch (status) {
          case 'approved': statusColor = context.clr.success; break;
          case 'rejected': statusColor = context.clr.error; break;
          default: statusColor = const Color(0xFFFFD700);
        }
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: context.clr.border)),
          child: Row(children: [
            Icon(Icons.account_balance_outlined, color: context.clr.txtMuted, size: 24),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('₹${double.tryParse(w['amount']?.toString() ?? '0')?.toStringAsFixed(0)}',
                style: TextStyle(color: context.clr.txtPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              Text(w['created_at'] ?? '', style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ])),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(status.toUpperCase(), style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ]),
        );
      },
    );
  }
}
