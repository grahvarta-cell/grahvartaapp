import 'package:equatable/equatable.dart';
import '../../models/astrologer.dart';
import '../../models/user.dart';

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeError extends HomeState {
  const HomeError();
}

class HomeLoaded extends HomeState {
  final Map<String, dynamic>? dashboardData;
  final Horoscope? horoscope;
  final List<Astrologer> onlineAstrologers;
  final bool astrologersRefreshing;

  const HomeLoaded({
    this.dashboardData,
    this.horoscope,
    this.onlineAstrologers = const [],
    this.astrologersRefreshing = false,
  });

  HomeLoaded copyWith({
    Map<String, dynamic>? dashboardData,
    Horoscope? horoscope,
    List<Astrologer>? onlineAstrologers,
    bool? astrologersRefreshing,
  }) =>
      HomeLoaded(
        dashboardData: dashboardData ?? this.dashboardData,
        horoscope: horoscope ?? this.horoscope,
        onlineAstrologers: onlineAstrologers ?? this.onlineAstrologers,
        astrologersRefreshing:
            astrologersRefreshing ?? this.astrologersRefreshing,
      );

  @override
  List<Object?> get props =>
      [dashboardData, horoscope, onlineAstrologers, astrologersRefreshing];
}
