import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/api_service.dart';

// --------------- State ---------------

class DashboardState {
  final bool loading;
  final bool toggling;
  final Map<String, dynamic>? data;

  const DashboardState({
    this.loading = true,
    this.toggling = false,
    this.data,
  });

  DashboardState copyWith({
    bool? loading,
    bool? toggling,
    Map<String, dynamic>? data,
  }) =>
      DashboardState(
        loading: loading ?? this.loading,
        toggling: toggling ?? this.toggling,
        data: data ?? this.data,
      );
}

// --------------- Cubit ---------------

class DashboardCubit extends Cubit<DashboardState> {
  DashboardCubit() : super(const DashboardState());

  Future<void> load() async {
    emit(state.copyWith(loading: true));
    try {
      final data = await ApiService.getAstrologerDashboard();
      emit(state.copyWith(loading: false, data: data['data'] as Map<String, dynamic>?));
    } catch (_) {
      emit(state.copyWith(loading: false));
    }
  }

  Future<bool> toggleAvailability(bool currentAvailability) async {
    emit(state.copyWith(toggling: true));
    try {
      await ApiService.updateAvailability(!currentAvailability);
      emit(state.copyWith(toggling: false));
      return true;
    } catch (_) {
      emit(state.copyWith(toggling: false));
      return false;
    }
  }
}
