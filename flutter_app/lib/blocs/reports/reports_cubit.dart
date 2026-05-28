import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/family_member.dart';
import '../../models/report.dart';
import '../../services/api_service.dart';
import 'reports_state.dart';

class ReportsCubit extends Cubit<ReportsState> {
  ReportsCubit() : super(const ReportsInitial());

  Future<void> load() async {
    emit(const ReportsLoading());
    try {
      final results = await Future.wait([
        ApiService.getReports(),
        ApiService.getFamilyMembers(),
        ApiService.getReportCredits(),
      ]);
      final credits = results[2] as Map<String, dynamic>;
      final allReports = results[0] as List<Report>;
      final seen = <String>{};
      final uniqueReports = allReports.where((r) => seen.add(r.id)).toList();
      emit(ReportsLoaded(
        reports: uniqueReports,
        familyMembers: results[1] as List<FamilyMember>,
        freeUsed: credits['free_used'] as bool? ?? false,
        planCredits: credits['plan_credits'] as int? ?? 0,
      ));
    } catch (_) {
      emit(const ReportsError());
    }
  }

  Future<void> refresh() => load();

  /// Called after a successful plan purchase or unlock so the screen can
  /// optimistically update credit counts without a full reload.
  void decrementPlanCredits() {
    final current = state;
    if (current is ReportsLoaded && current.planCredits > 0) {
      emit(current.copyWith(
        freeUsed: true,
        planCredits: current.planCredits - 1,
      ));
    }
  }

  void switchTab(int index) {
    final current = state;
    if (current is ReportsLoaded) {
      emit(current.copyWith(
        currentTab: index,
        myReportsVisited: current.myReportsVisited || index == 1,
      ));
    }
  }

  void markFreeUsed() {
    final current = state;
    if (current is ReportsLoaded) {
      emit(current.copyWith(freeUsed: true));
    }
  }

  void incrementPlanCredits() {
    final current = state;
    if (current is ReportsLoaded) {
      emit(current.copyWith(planCredits: current.planCredits + 1));
    }
  }
}
