import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';

// --------------- State ---------------

class EarningsState {
  final bool loading;
  final Map<String, dynamic>? wallet;
  final List<dynamic> transactions;
  final List<dynamic> withdrawals;

  const EarningsState({
    this.loading = true,
    this.wallet,
    this.transactions = const [],
    this.withdrawals = const [],
  });

  EarningsState copyWith({
    bool? loading,
    Map<String, dynamic>? wallet,
    List<dynamic>? transactions,
    List<dynamic>? withdrawals,
  }) =>
      EarningsState(
        loading: loading ?? this.loading,
        wallet: wallet ?? this.wallet,
        transactions: transactions ?? this.transactions,
        withdrawals: withdrawals ?? this.withdrawals,
      );
}

// --------------- Cubit ---------------

class EarningsCubit extends Cubit<EarningsState> {
  EarningsCubit() : super(const EarningsState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    final walletFuture = ApiService.getAstrologerWallet().catchError((_) => <String, dynamic>{});
    final txFuture = ApiService.getAstrologerTransactions().catchError((_) => <dynamic>[]);
    final wdFuture = ApiService.getWithdrawals().catchError((_) => <dynamic>[]);
    final results = await Future.wait([walletFuture, txFuture, wdFuture]);
    final walletResp = results[0] as Map<String, dynamic>;
    emit(state.copyWith(
      loading: false,
      wallet: (walletResp['data'] as Map<String, dynamic>?) ?? walletResp,
      transactions: results[1] as List,
      withdrawals: results[2] as List,
    ));
  }

  Future<bool> requestWithdrawal(double amount, Map<String, String> bankDetails) async {
    try {
      await ApiService.requestWithdrawal(amount, bankDetails);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
