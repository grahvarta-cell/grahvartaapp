import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import '../../l10n/app_strings.dart';
import '../../models/astrologer.dart';
import '../../services/api_service.dart';
import '../../theme/app_theme.dart';

class WalletScreen extends StatefulWidget {
  final double? initialAmount;
  const WalletScreen({super.key, this.initialAmount});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late Razorpay _razorpay;
  WalletData? _wallet;
  List<WalletTransaction> _transactions = [];
  List<RechargeOffer> _offers = [];
  bool _isLoading = true;
  double _pendingAmount = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onPaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onPaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);
    _loadData().then((_) {
      if (widget.initialAmount != null && mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _showAddMoneySheet(presetAmount: widget.initialAmount));
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _razorpay.clear();
    super.dispose();
  }

  void _onPaymentSuccess(PaymentSuccessResponse response) async {
    try {
      final updated = await ApiService.verifyAndCredit({
        'order_id': response.orderId,
        'payment_id': response.paymentId,
        'signature': response.signature,
        'amount': _pendingAmount,
      });
      if (mounted) {
        setState(() => _wallet = updated);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('₹${_pendingAmount.toInt()} added to wallet!'),
          backgroundColor: context.clr.success,
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: $e'), backgroundColor: context.clr.error),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: context.clr.error),
    );
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('External wallet: ${response.walletName}')),
    );
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.getWallet(),
        ApiService.getTransactions(),
        ApiService.getRechargeOffers(),
      ]);
      if (mounted) setState(() {
        _wallet = results[0] as WalletData;
        _transactions = results[1] as List<WalletTransaction>;
        _offers = results[2] as List<RechargeOffer>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _wallet = WalletData(id: 'demo', balance: 250, totalAdded: 500, totalSpent: 250);
        _transactions = _demoTransactions();
        _offers = _demoOffers();
        _isLoading = false;
      });
    }
  }

  List<RechargeOffer> _demoOffers() => [
    RechargeOffer(id: 1, amount: 50,   bonusPercent: 50, label: '50% Extra'),
    RechargeOffer(id: 2, amount: 100,  bonusPercent: 50, label: '50% Extra'),
    RechargeOffer(id: 3, amount: 200,  bonusPercent: 25, label: '25% Extra'),
    RechargeOffer(id: 4, amount: 500,  bonusPercent: 20, label: '20% Extra'),
    RechargeOffer(id: 5, amount: 1000, bonusPercent: 15, label: '15% Extra'),
  ];

  List<WalletTransaction> _demoTransactions() => [
    WalletTransaction(id: '1', type: 'credit', amount: 500, description: 'Wallet recharge via Razorpay', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String()),
    WalletTransaction(id: '2', type: 'debit', amount: 144, description: 'Consultation - Pandit Raj Sharma (12 min)', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String()),
    WalletTransaction(id: '3', type: 'debit', amount: 45, description: 'Consultation - Dr. Priya Nair (3 min)', status: 'success', createdAt: DateTime.now().toIso8601String()),
    WalletTransaction(id: '4', type: 'credit', amount: 200, description: 'Wallet recharge via UPI', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String()),
    WalletTransaction(id: '5', type: 'refund', amount: 50, description: 'Refund for cancelled consultation', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String()),
  ];


  void _showAddMoneySheet({double? presetAmount}) {
    double selectedAmount = presetAmount ?? (_offers.isNotEmpty ? _offers[0].amount : 100);
    final customCtrl = TextEditingController(
      text: presetAmount != null && !_offers.any((o) => o.amount == presetAmount)
          ? presetAmount.toInt().toString()
          : '',
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.clr.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) {
        final selectedOffer = _offers.where((o) => o.amount == selectedAmount).firstOrNull;
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 30),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(ctx.s.addMoneyToWallet, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: context.clr.txtPrimary))),
              IconButton(icon: Icon(Icons.close, color: context.clr.txtMuted), onPressed: () => Navigator.pop(ctx)),
            ]),
            if (_offers.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Select an offer', style: TextStyle(color: context.clr.txtMuted, fontSize: 12)),
              const SizedBox(height: 12),
              Wrap(spacing: 10, runSpacing: 10, children: _offers.map((offer) {
                final isSelected = selectedAmount == offer.amount;
                return GestureDetector(
                  onTap: () => setS(() { selectedAmount = offer.amount; customCtrl.clear(); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? context.clr.accent.withValues(alpha: 0.15) : context.clr.card,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: isSelected ? context.clr.accent : context.clr.border, width: isSelected ? 1.5 : 1),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Text('Pay ₹${offer.amount.toInt()}', style: TextStyle(color: isSelected ? context.clr.accent : context.clr.txtSecondary, fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('Get ₹${offer.walletCredit.toInt()} 🎁', style: TextStyle(color: isSelected ? context.clr.success : context.clr.txtMuted, fontSize: 11)),
                    ]),
                  ),
                );
              }).toList()),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: customCtrl,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.clr.txtPrimary),
              onChanged: (v) => setS(() => selectedAmount = double.tryParse(v) ?? selectedAmount),
              decoration: InputDecoration(labelText: ctx.s.customAmount, prefixText: '₹ '),
            ),
            if (selectedOffer != null && selectedOffer.bonusPercent > 0) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(color: context.clr.success.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  const Text('🎁', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 8),
                  Text('You get ₹${selectedOffer.bonusAmount.toInt()} extra bonus!', style: TextStyle(color: context.clr.success, fontSize: 12, fontWeight: FontWeight.w600)),
                ]),
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () { Navigator.pop(ctx); _confirmAndPay(selectedAmount); },
              icon: const Icon(Icons.payment),
              label: Text('Pay ₹${selectedAmount.toInt()}'),
            ),
            const SizedBox(height: 8),
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Icon(Icons.lock, size: 12, color: context.clr.txtMuted),
              const SizedBox(width: 4),
              Text(context.s.securedByRazorpay, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ]),
          ]),
        );
      }),
    );
  }

  Future<void> _confirmAndPay(double amount) async {
    final offer = _offers.where((o) => o.amount == amount).firstOrNull;
    final bonusAmount = offer?.bonusAmount ?? 0;
    final walletCredit = amount + bonusAmount;
    final gst = amount * 0.18;
    final total = amount + gst;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.clr.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Confirm Payment', style: TextStyle(color: context.clr.txtPrimary, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _payRow('Base amount', '₹${amount.toStringAsFixed(2)}', context.clr.txtPrimary),
          if (bonusAmount > 0) ...[
            const SizedBox(height: 8),
            _payRow('Bonus 🎁', '+₹${bonusAmount.toStringAsFixed(2)}', context.clr.success),
            const SizedBox(height: 8),
            _payRow('Wallet credit', '₹${walletCredit.toStringAsFixed(2)}', context.clr.txtPrimary, bold: true),
          ],
          const SizedBox(height: 8),
          _payRow('GST (18%)', '₹${gst.toStringAsFixed(2)}', context.clr.txtSecondary),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: context.clr.border),
          ),
          _payRow('Total charged', '₹${total.toStringAsFixed(2)}', context.clr.accent, bold: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: context.clr.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Icon(Icons.info_outline, size: 14, color: context.clr.txtMuted),
              const SizedBox(width: 6),
              Expanded(child: Text(
                bonusAmount > 0
                    ? '₹${walletCredit.toStringAsFixed(0)} will be credited (₹${amount.toStringAsFixed(0)} + ₹${bonusAmount.toStringAsFixed(0)} bonus).'
                    : '₹${amount.toStringAsFixed(0)} will be credited to your wallet.',
                style: TextStyle(color: context.clr.txtMuted, fontSize: 11),
              )),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: context.clr.txtMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: context.clr.accent),
            child: Text('Pay ₹${total.toStringAsFixed(0)}'),
          ),
        ],
      ),
    );
    if (confirmed == true) _processPayment(amount);
  }

  Widget _payRow(String label, String value, Color valueColor, {bool bold = false}) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(label, style: TextStyle(color: context.clr.txtSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ],
  );

  Future<void> _processPayment(double amount) async {
    try {
      final order = await ApiService.createAddMoneyOrder(amount);
      final data = order['data'];
      // Use server-determined wallet_credit (includes bonus if applicable)
      _pendingAmount = (data['wallet_credit'] as num?)?.toDouble() ?? amount;

      final options = {
        'key': data['key'],
        'amount': data['amount'], // already in paise from backend
        'currency': data['currency'] ?? 'INR',
        'order_id': data['order_id'],
        'name': 'AstroVaak',
        'description': 'Wallet Recharge',
        'prefill': {
          'contact': '',
          'email': '',
        },
        'theme': {'color': '#FF6B35'},
      };

      _razorpay.open(options);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: context.clr.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: AppBar(
        title: Text(s.wallet),
        actions: [
          TextButton.icon(
            onPressed: _showAddMoneySheet,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('Add Money', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: context.clr.accent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white.withValues(alpha: 0.65),
          tabs: [Tab(text: s.wallet), Tab(text: s.transactions)],
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: context.clr.accent))
          : TabBarView(controller: _tabController, children: [
              _buildWalletTab(),
              _buildTransactionsTab(),
            ]),
    );
  }

  Widget _buildWalletTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        // Balance card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [context.clr.surface, context.clr.card]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: context.clr.accent.withValues(alpha: 0.3)),
          ),
          child: Column(children: [
            Text(context.s.availableBalance, style: TextStyle(color: context.clr.txtSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('₹${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}', style: TextStyle(color: context.clr.txtPrimary, fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statCol(context.s.totalAdded, '₹${_wallet?.totalAdded.toStringAsFixed(0) ?? 0}', context.clr.success),
              Container(height: 40, width: 1, color: context.clr.border),
              _statCol(context.s.totalSpent, '₹${_wallet?.totalSpent.toStringAsFixed(0) ?? 0}', context.clr.error),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // Recharge offers
        Align(alignment: Alignment.centerLeft, child: Text(context.s.quickAdd, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: context.clr.txtPrimary))),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 2.4,
          children: _offers.map((offer) => GestureDetector(
            onTap: () => _confirmAndPay(offer.amount),
            child: Container(
              decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.clr.border)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Stack(children: [
                Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('₹${offer.amount.toInt()}', style: TextStyle(color: context.clr.accent, fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('Get ₹${offer.walletCredit.toInt()}', style: TextStyle(color: context.clr.txtSecondary, fontSize: 12)),
                ]),
                if (offer.bonusPercent > 0)
                  Positioned(top: 0, right: 0, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: context.clr.success, borderRadius: BorderRadius.circular(6)),
                    child: Text('+${offer.bonusPercent}%', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  )),
              ]),
            ),
          )).toList(),
        ),
        const SizedBox(height: 20),

        ElevatedButton.icon(
          onPressed: _showAddMoneySheet,
          icon: const Icon(Icons.add_circle_outline),
          label: Text(context.s.addCustomAmount),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
        ),

        const SizedBox(height: 20),
        // Payment methods
        Align(alignment: Alignment.centerLeft, child: Text(context.s.acceptedPayments, style: TextStyle(fontSize: 14, color: context.clr.txtMuted))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: ['UPI', 'Debit Card', 'Credit Card', 'Net Banking', 'Wallet'].map((m) => Chip(
          label: Text(m, style: TextStyle(color: context.clr.txtSecondary, fontSize: 11)),
          backgroundColor: context.clr.card,
          side: BorderSide(color: context.clr.border),
        )).toList()),
      ]),
    );
  }

  Widget _statCol(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(label, style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
  ]);

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return  Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, color: context.clr.txtMuted, size: 48),
        SizedBox(height: 12),
        Text(context.s.noTransactions, style: TextStyle(color: context.clr.txtMuted)),
      ]));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (_, i) {
        final tx = _transactions[i];
        final isCredit = tx.isCredit;
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: context.clr.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: context.clr.border)),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isCredit ? context.clr.success.withValues(alpha: 0.15) : context.clr.error.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? context.clr.success : context.clr.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.description, style: TextStyle(color: context.clr.txtPrimary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(_formatDate(tx.createdAt), style: TextStyle(color: context.clr.txtMuted, fontSize: 11)),
            ])),
            const SizedBox(width: 8),
            Text('${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}', style: TextStyle(color: isCredit ? context.clr.success : context.clr.error, fontSize: 15, fontWeight: FontWeight.bold)),
          ]),
        );
      },
    );
  }

  String _formatDate(String iso) {
    try {
      return DateFormat('MMM d, h:mm a').format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return iso;
    }
  }
}
