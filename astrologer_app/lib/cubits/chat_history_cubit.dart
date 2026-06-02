import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';

// --------------- State ---------------

class ChatHistoryState {
  final bool loading;
  final List<dynamic> threads;
  final String? error;

  const ChatHistoryState({
    this.loading = true,
    this.threads = const [],
    this.error,
  });

  ChatHistoryState copyWith({
    bool? loading,
    List<dynamic>? threads,
    String? error,
  }) =>
      ChatHistoryState(
        loading: loading ?? this.loading,
        threads: threads ?? this.threads,
        error: error,
      );
}

// --------------- Cubit ---------------

class ChatHistoryCubit extends Cubit<ChatHistoryState> {
  ChatHistoryCubit() : super(const ChatHistoryState());

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final data = await ApiService.getAstrologerChatThreads();
      emit(state.copyWith(loading: false, threads: data));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }
}
