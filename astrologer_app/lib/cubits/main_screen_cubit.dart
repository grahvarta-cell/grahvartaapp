import 'package:flutter_bloc/flutter_bloc.dart';

// --------------- State ---------------

class MainScreenState {
  final int currentIndex;
  final Map<String, dynamic>? incomingRequest;
  final Map<String, dynamic>? activeCall;

  const MainScreenState({
    this.currentIndex = 0,
    this.incomingRequest,
    this.activeCall,
  });

  MainScreenState copyWith({
    int? currentIndex,
    Map<String, dynamic>? Function()? incomingRequest,
    Map<String, dynamic>? Function()? activeCall,
  }) =>
      MainScreenState(
        currentIndex: currentIndex ?? this.currentIndex,
        incomingRequest: incomingRequest != null ? incomingRequest() : this.incomingRequest,
        activeCall: activeCall != null ? activeCall() : this.activeCall,
      );
}

// --------------- Cubit ---------------

class MainScreenCubit extends Cubit<MainScreenState> {
  MainScreenCubit() : super(const MainScreenState());

  void setIndex(int index) => emit(state.copyWith(currentIndex: index));

  void setIncomingRequest(Map<String, dynamic>? req) =>
      emit(state.copyWith(incomingRequest: () => req));

  void clearIncomingRequest() =>
      emit(state.copyWith(incomingRequest: () => null));

  void setActiveCall(Map<String, dynamic>? call) =>
      emit(state.copyWith(activeCall: () => call));

  void clearActiveCall() =>
      emit(state.copyWith(activeCall: () => null));
}
