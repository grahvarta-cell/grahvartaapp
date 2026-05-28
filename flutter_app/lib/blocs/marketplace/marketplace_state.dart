import 'package:equatable/equatable.dart';
import '../../models/astrologer.dart';

abstract class MarketplaceState extends Equatable {
  const MarketplaceState();
  @override
  List<Object?> get props => [];
}

class MarketplaceInitial extends MarketplaceState {
  const MarketplaceInitial();
}

class MarketplaceLoading extends MarketplaceState {
  const MarketplaceLoading();
}

class MarketplaceError extends MarketplaceState {
  const MarketplaceError();
}

class MarketplaceLoaded extends MarketplaceState {
  final List<Astrologer> astrologers;
  final String searchQuery;
  final String? selectedSpecialization;
  final bool onlineOnly;
  final String sortBy;

  const MarketplaceLoaded({
    this.astrologers = const [],
    this.searchQuery = '',
    this.selectedSpecialization,
    this.onlineOnly = false,
    this.sortBy = 'rating',
  });

  MarketplaceLoaded copyWith({
    List<Astrologer>? astrologers,
    String? searchQuery,
    Object? selectedSpecialization = _sentinel,
    bool? onlineOnly,
    String? sortBy,
  }) =>
      MarketplaceLoaded(
        astrologers: astrologers ?? this.astrologers,
        searchQuery: searchQuery ?? this.searchQuery,
        selectedSpecialization: selectedSpecialization == _sentinel
            ? this.selectedSpecialization
            : selectedSpecialization as String?,
        onlineOnly: onlineOnly ?? this.onlineOnly,
        sortBy: sortBy ?? this.sortBy,
      );

  @override
  List<Object?> get props =>
      [astrologers, searchQuery, selectedSpecialization, onlineOnly, sortBy];
}

// Sentinel to distinguish "not passed" from explicit null
const Object _sentinel = Object();
