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
  List<SubscriptionPlan> _plans = [];
  bool _isLoading = true;
  double _pendingAmount = 0;

  final List<double> _quickAmounts = [100, 200, 500, 1000, 2000, 5000];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
          backgroundColor: AppColors.success,
        ));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment verification failed: $e'), backgroundColor: AppColors.error),
      );
    }
  }

  void _onPaymentError(PaymentFailureResponse response) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Payment failed: ${response.message}'), backgroundColor: AppColors.error),
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
        ApiService.getSubscriptionPlans(),
      ]);
      if (mounted) setState(() {
        _wallet = results[0] as WalletData;
        _transactions = results[1] as List<WalletTransaction>;
        _plans = results[2] as List<SubscriptionPlan>;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() {
        _wallet = WalletData(id: 'demo', balance: 250, totalAdded: 500, totalSpent: 250);
        _transactions = _demoTransactions();
        _plans = _demoPlans();
        _isLoading = false;
      });
    }
  }

  List<WalletTransaction> _demoTransactions() => [
    WalletTransaction(id: '1', type: 'credit', amount: 500, description: 'Wallet recharge via Razorpay', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String()),
    WalletTransaction(id: '2', type: 'debit', amount: 144, description: 'Consultation - Pandit Raj Sharma (12 min)', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String()),
    WalletTransaction(id: '3', type: 'debit', amount: 45, description: 'Consultation - Dr. Priya Nair (3 min)', status: 'success', createdAt: DateTime.now().toIso8601String()),
    WalletTransaction(id: '4', type: 'credit', amount: 200, description: 'Wallet recharge via UPI', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String()),
    WalletTransaction(id: '5', type: 'refund', amount: 50, description: 'Refund for cancelled consultation', status: 'success', createdAt: DateTime.now().subtract(const Duration(days: 7)).toIso8601String()),
  ];

  List<SubscriptionPlan> _demoPlans() => [
    SubscriptionPlan(id: '1', name: 'Basic', price: 0, durationDays: 0, features: ['5 free daily predictions', 'Basic horoscope', 'Community access']),
    SubscriptionPlan(id: '2', name: 'Silver', price: 299, durationDays: 30, freeMinutes: 5, discountPercent: 10, features: ['Unlimited horoscopes', '5 free chat minutes', 'Priority queue', 'Ad-free']),
    SubscriptionPlan(id: '3', name: 'Gold', price: 599, durationDays: 30, freeMinutes: 15, discountPercent: 20, features: ['All Silver features', '15 free chat minutes', '10% call discount', 'Birth chart PDF']),
    SubscriptionPlan(id: '4', name: 'Platinum', price: 999, durationDays: 30, freeMinutes: 30, discountPercent: 30, features: ['All Gold features', '30 free minutes', '20% discount', 'Exclusive live sessions', 'Personal astrologer']),
  ];

  void _showAddMoneySheet({double? presetAmount}) {
    double _selectedAmount = presetAmount ?? 200;
    final _customCtrl = TextEditingController(text: presetAmount != null && !_quickAmounts.contains(presetAmount) ? presetAmount.toInt().toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 30),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(ctx.s.addMoneyToWallet, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary))),
            IconButton(icon: const Icon(Icons.close, color: AppColors.textMuted), onPressed: () => Navigator.pop(ctx)),
          ]),
          const SizedBox(height: 16),
          Wrap(spacing: 10, runSpacing: 10, children: _quickAmounts.map((amt) => GestureDetector(
            onTap: () => setS(() { _selectedAmount = amt; _customCtrl.text = ''; }),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              decoration: BoxDecoration(
                color: _selectedAmount == amt ? AppColors.orange : AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _selectedAmount == amt ? AppColors.orange : AppColors.border),
              ),
              child: Text('₹${amt.toInt()}', style: TextStyle(color: _selectedAmount == amt ? Colors.white : AppColors.textSecondary, fontWeight: FontWeight.w600)),
            ),
          )).toList()),
          const SizedBox(height: 16),
          TextField(
            controller: _customCtrl,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: AppColors.textPrimary),
            onChanged: (v) => setS(() => _selectedAmount = double.tryParse(v) ?? _selectedAmount),
            decoration: InputDecoration(labelText: ctx.s.customAmount, prefixText: '₹ '),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () { Navigator.pop(ctx); _confirmAndPay(_selectedAmount); },
            icon: const Icon(Icons.payment),
            label: Text('Pay ₹${_selectedAmount.toInt()}'),
          ),
          const SizedBox(height: 8),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.lock, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(context.s.securedByRazorpay, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
          ]),
        ]),
      )),
    );
  }

  Future<void> _confirmAndPay(double amount) async {
    final gst = amount * 0.18;
    final total = amount + gst;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Payment', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _payRow('Wallet credit', '₹${amount.toStringAsFixed(2)}', AppColors.textPrimary),
          const SizedBox(height: 8),
          _payRow('GST (18%)', '₹${gst.toStringAsFixed(2)}', AppColors.textSecondary),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: AppColors.border),
          ),
          _payRow('Total charged', '₹${total.toStringAsFixed(2)}', AppColors.orange, bold: true),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.info_outline, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(child: Text('₹${amount.toStringAsFixed(0)} will be credited to your wallet after payment.', style: const TextStyle(color: AppColors.textMuted, fontSize: 11))),
            ]),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.orange),
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
      Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
      Text(value, style: TextStyle(color: valueColor, fontSize: 14, fontWeight: bold ? FontWeight.bold : FontWeight.normal)),
    ],
  );

  Future<void> _processPayment(double amount) async {
    try {
      _pendingAmount = amount;
      final order = await ApiService.createAddMoneyOrder(amount);
      final data = order['data'];

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
        SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
      );
    }
  }

  Future<void> _purchasePlan(SubscriptionPlan plan) async {
    if (plan.price == 0) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Subscribe to ${plan.name}?', style: const TextStyle(color: AppColors.textPrimary)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('₹${plan.price.toInt()}/month will be deducted from your wallet.', style: const TextStyle(color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Text('Wallet balance: ₹${_wallet?.balance.toStringAsFixed(0) ?? 0}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Subscribe')),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await ApiService.purchaseSubscription(plan.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Subscribed to ${plan.name}!'), backgroundColor: AppColors.success));
        _loadData();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Text(s.walletAndPlans),
        actions: [
          TextButton.icon(
            onPressed: _showAddMoneySheet,
            icon: const Icon(Icons.add, color: AppColors.orange),
            label: Text(s.addMoney, style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600)),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.orange,
          labelColor: AppColors.orange,
          unselectedLabelColor: AppColors.textMuted,
          tabs: [Tab(text: s.wallet), Tab(text: s.transactions), Tab(text: 'Plans')],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.orange))
          : TabBarView(controller: _tabController, children: [
              _buildWalletTab(),
              _buildTransactionsTab(),
              _buildPlansTab(),
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
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [Color(0xFF2A1500), Color(0xFF1A0D00)]),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.orange.withOpacity(0.3)),
          ),
          child: Column(children: [
            Text(context.s.availableBalance, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
            const SizedBox(height: 8),
            Text('₹${_wallet?.balance.toStringAsFixed(2) ?? '0.00'}', style: const TextStyle(color: AppColors.textPrimary, fontSize: 36, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
              _statCol(context.s.totalAdded, '₹${_wallet?.totalAdded.toStringAsFixed(0) ?? 0}', AppColors.success),
              Container(height: 40, width: 1, color: AppColors.border),
              _statCol(context.s.totalSpent, '₹${_wallet?.totalSpent.toStringAsFixed(0) ?? 0}', AppColors.error),
            ]),
          ]),
        ),
        const SizedBox(height: 20),

        // Quick add
        Align(alignment: Alignment.centerLeft, child: Text(context.s.quickAdd, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10, crossAxisSpacing: 10,
          childAspectRatio: 2.5,
          children: _quickAmounts.map((amt) => GestureDetector(
            onTap: () => _confirmAndPay(amt),
            child: Container(
              decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
              child: Center(child: Text('₹${amt.toInt()}', style: const TextStyle(color: AppColors.orange, fontWeight: FontWeight.w600))),
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
        Align(alignment: Alignment.centerLeft, child: Text(context.s.acceptedPayments, style: const TextStyle(fontSize: 14, color: AppColors.textMuted))),
        const SizedBox(height: 10),
        Wrap(spacing: 8, children: ['UPI', 'Debit Card', 'Credit Card', 'Net Banking', 'Wallet'].map((m) => Chip(
          label: Text(m, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11)),
          backgroundColor: AppColors.card,
          side: const BorderSide(color: AppColors.border),
        )).toList()),
      ]),
    );
  }

  Widget _statCol(String label, String value, Color color) => Column(children: [
    Text(value, style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold)),
    const SizedBox(height: 4),
    Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
  ]);

  Widget _buildTransactionsTab() {
    if (_transactions.isEmpty) {
      return  Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.receipt_long_outlined, color: AppColors.textMuted, size: 48),
        SizedBox(height: 12),
        Text(context.s.noTransactions, style: const TextStyle(color: AppColors.textMuted)),
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
          decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.border)),
          child: Row(children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isCredit ? AppColors.success.withOpacity(0.15) : AppColors.error.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(isCredit ? Icons.arrow_downward : Icons.arrow_upward, color: isCredit ? AppColors.success : AppColors.error, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tx.description, style: const TextStyle(color: AppColors.textPrimary, fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(_formatDate(tx.createdAt), style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
            ])),
            const SizedBox(width: 8),
            Text('${isCredit ? '+' : '-'}₹${tx.amount.toStringAsFixed(0)}', style: TextStyle(color: isCredit ? AppColors.success : AppColors.error, fontSize: 15, fontWeight: FontWeight.bold)),
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

  Widget _buildPlansTab() {
    final planColors = [AppColors.textMuted, const Color(0xFFC0C0C0), AppColors.gold, AppColors.orange];
    final planIcons = ['⭐', '🥈', '🥇', '💎'];

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _plans.length,
      itemBuilder: (_, i) {
        final plan = _plans[i];
        final color = planColors[i % planColors.length];
        final isPopular = plan.name == 'Gold';

        return Stack(children: [
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isPopular ? AppColors.orange : AppColors.border, width: isPopular ? 1.5 : 1),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Text(planIcons[i % planIcons.length], style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(plan.name, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
                  if (plan.price > 0)
                    Text('₹${plan.price.toInt()}/month', style: const TextStyle(color: AppColors.textSecondary, fontSize: 13))
                  else
                    Text(context.s.freeForever, style: const TextStyle(color: AppColors.success, fontSize: 13)),
                ])),
                if (plan.price > 0)
                  ElevatedButton(
                    onPressed: () => _purchasePlan(plan),
                    style: ElevatedButton.styleFrom(backgroundColor: color, minimumSize: const Size(80, 36), padding: EdgeInsets.zero),
                    child: Text(context.s.buyText, style: const TextStyle(fontSize: 13)),
                  ),
              ]),
              if (plan.freeMinutes > 0) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('${plan.freeMinutes} FREE minutes/month', style: const TextStyle(color: AppColors.orange, fontSize: 11, fontWeight: FontWeight.w600)),
                ),
              ],
              const SizedBox(height: 12),
              ...plan.features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(children: [
                  Icon(Icons.check_circle, color: color, size: 15),
                  const SizedBox(width: 8),
                  Text(f, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                ]),
              )),
            ]),
          ),
          if (isPopular)
            Positioned(top: 12, right: 28, child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(color: AppColors.orange, borderRadius: BorderRadius.circular(12)),
              child: const Text('POPULAR', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold, letterSpacing: 1)),
            )),
        ]);
      },
    );
  }
}
