import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(const HomeInitial());

  Future<void> load() async {
    emit(const HomeLoading());
    try {
      final results = await Future.wait([
        ApiService.getDashboard(),
        ApiService.getMyHoroscope(),
        ApiService.getAstrologers(onlineOnly: true),
      ]);
      emit(HomeLoaded(
        dashboardData: (results[0] as Map<String, dynamic>)['data'],
        horoscope: results[1] as dynamic,
        onlineAstrologers:
            ((results[2] as List).take(10).toList()).cast(),
      ));
    } catch (_) {
      emit(const HomeError());
    }
  }

  Future<void> refreshAstrologers() async {
    final current = state;
    if (current is HomeLoaded) {
      emit(current.copyWith(astrologersRefreshing: true));
      try {
        final data = await ApiService.getAstrologers(onlineOnly: true);
        emit(current.copyWith(
          onlineAstrologers: data.take(10).toList(),
          astrologersRefreshing: false,
        ));
      } catch (_) {
        emit(current.copyWith(astrologersRefreshing: false));
      }
    }
  }

  Future<void> refresh() => load();
}
