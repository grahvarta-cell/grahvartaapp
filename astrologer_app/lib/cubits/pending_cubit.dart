import 'package:flutter_bloc/flutter_bloc.dart';

// --------------- State ---------------

class PendingState {
  final bool refreshing;

  const PendingState({this.refreshing = false});

  PendingState copyWith({bool? refreshing}) =>
      PendingState(refreshing: refreshing ?? this.refreshing);
}

// --------------- Cubit ---------------

class PendingCubit extends Cubit<PendingState> {
  PendingCubit() : super(const PendingState());

  void setRefreshing(bool value) => emit(state.copyWith(refreshing: value));
}
