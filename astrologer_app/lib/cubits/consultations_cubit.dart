import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';

// --------------- State ---------------

class ConsultationsState {
  final bool loading;
  final List<Map<String, dynamic>> active;
  final List<Map<String, dynamic>> completed;
  final List<Map<String, dynamic>> all;

  const ConsultationsState({
    this.loading = true,
    this.active = const [],
    this.completed = const [],
    this.all = const [],
  });

  ConsultationsState copyWith({
    bool? loading,
    List<Map<String, dynamic>>? active,
    List<Map<String, dynamic>>? completed,
    List<Map<String, dynamic>>? all,
  }) =>
      ConsultationsState(
        loading: loading ?? this.loading,
        active: active ?? this.active,
        completed: completed ?? this.completed,
        all: all ?? this.all,
      );
}

// --------------- Cubit ---------------

class ConsultationsCubit extends Cubit<ConsultationsState> {
  ConsultationsCubit() : super(const ConsultationsState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final allData = await ApiService.getAstrologerConsultations();
      final items = allData.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      emit(state.copyWith(
        loading: false,
        all: items,
        active: items.where((c) => ['active', 'accepted'].contains(c['status'])).toList(),
        completed: items.where((c) => ['completed', 'cancelled', 'missed'].contains(c['status'])).toList(),
      ));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }
}
