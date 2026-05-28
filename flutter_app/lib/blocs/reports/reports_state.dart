import 'package:equatable/equatable.dart';
import '../../models/family_member.dart';
import '../../models/report.dart';

abstract class ReportsState extends Equatable {
  const ReportsState();
  @override
  List<Object?> get props => [];
}

class ReportsInitial extends ReportsState {
  const ReportsInitial();
}

class ReportsLoading extends ReportsState {
  const ReportsLoading();
}

class ReportsError extends ReportsState {
  const ReportsError();
}

class ReportsLoaded extends ReportsState {
  final List<Report> reports;
  final List<FamilyMember> familyMembers;
  final bool freeUsed;
  final int planCredits;

  const ReportsLoaded({
    this.reports = const [],
    this.familyMembers = const [],
    this.freeUsed = false,
    this.planCredits = 0,
  });

  ReportsLoaded copyWith({
    List<Report>? reports,
    List<FamilyMember>? familyMembers,
    bool? freeUsed,
    int? planCredits,
  }) =>
      ReportsLoaded(
        reports: reports ?? this.reports,
        familyMembers: familyMembers ?? this.familyMembers,
        freeUsed: freeUsed ?? this.freeUsed,
        planCredits: planCredits ?? this.planCredits,
      );

  @override
  List<Object?> get props => [reports, familyMembers, freeUsed, planCredits];
}
