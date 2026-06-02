import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/astrologer.dart';
import '../services/api_service.dart';

// --------------- State ---------------

class LiveState {
  final bool loading;
  final List<LiveSession> sessions;

  const LiveState({
    this.loading = true,
    this.sessions = const [],
  });

  LiveState copyWith({
    bool? loading,
    List<LiveSession>? sessions,
  }) =>
      LiveState(
        loading: loading ?? this.loading,
        sessions: sessions ?? this.sessions,
      );
}

// --------------- Cubit ---------------

class LiveCubit extends Cubit<LiveState> {
  LiveCubit() : super(const LiveState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final sessions = await ApiService.getLiveSessions();
      emit(state.copyWith(loading: false, sessions: sessions));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<bool> createSession(Map<String, dynamic> data) async {
    try {
      await ApiService.createLiveSession(data);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> startSession(String id) async {
    try {
      await ApiService.startLiveSession(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<bool> endSession(String id) async {
    try {
      await ApiService.endLiveSession(id);
      await load();
      return true;
    } catch (_) {
      return false;
    }
  }
}
