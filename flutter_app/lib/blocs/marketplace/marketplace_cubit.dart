import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'marketplace_state.dart';

class MarketplaceCubit extends Cubit<MarketplaceState> {
  MarketplaceCubit() : super(const MarketplaceInitial());

  Future<void> load() async {
    final current = state;
    final String sortBy =
        current is MarketplaceLoaded ? current.sortBy : 'rating';
    final bool onlineOnly =
        current is MarketplaceLoaded ? current.onlineOnly : false;
    final String? spec =
        current is MarketplaceLoaded ? current.selectedSpecialization : null;

    emit(const MarketplaceLoading());
    try {
      final data = await ApiService.getAstrologers(
        specialization: spec,
        sort: sortBy,
        onlineOnly: onlineOnly,
      );
      emit(MarketplaceLoaded(
        astrologers: data,
        sortBy: sortBy,
        onlineOnly: onlineOnly,
        selectedSpecialization: spec,
      ));
    } catch (_) {
      emit(const MarketplaceError());
    }
  }

  Future<void> _reload() async {
    final current = state;
    if (current is! MarketplaceLoaded) return;
    emit(const MarketplaceLoading());
    try {
      final data = await ApiService.getAstrologers(
        specialization: current.selectedSpecialization,
        sort: current.sortBy,
        onlineOnly: current.onlineOnly,
      );
      emit(current.copyWith(astrologers: data));
    } catch (_) {
      emit(const MarketplaceError());
    }
  }

  Future<void> search(String q) async {
    final current = state;
    if (current is MarketplaceLoaded) {
      emit(current.copyWith(searchQuery: q));
    }
  }

  Future<void> filterSpecialization(String? spec) async {
    final current = state;
    if (current is MarketplaceLoaded) {
      emit(current.copyWith(selectedSpecialization: spec));
      await _reloadFromCurrent();
    }
  }

  Future<void> toggleOnline() async {
    final current = state;
    if (current is MarketplaceLoaded) {
      emit(current.copyWith(onlineOnly: !current.onlineOnly));
      await _reloadFromCurrent();
    }
  }

  Future<void> changeSortBy(String sort) async {
    final current = state;
    if (current is MarketplaceLoaded) {
      emit(current.copyWith(sortBy: sort));
      await _reloadFromCurrent();
    }
  }

  Future<void> _reloadFromCurrent() async {
    final current = state;
    if (current is! MarketplaceLoaded) return;
    // Keep the current loaded state visible while fetching; replace list when done
    try {
      final data = await ApiService.getAstrologers(
        specialization: current.selectedSpecialization,
        sort: current.sortBy,
        onlineOnly: current.onlineOnly,
      );
      if (state is MarketplaceLoaded) {
        emit((state as MarketplaceLoaded).copyWith(astrologers: data));
      }
    } catch (_) {
      // silently keep old list on error
    }
  }
}
