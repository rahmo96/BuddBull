import 'package:buddbull/core/error/app_exception.dart';
import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/features/reports/data/report_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final reportRepositoryProvider = Provider<ReportRepository>((ref) {
  return ReportRepository(ref.watch(apiClientProvider));
});

class SubmitReportState {
  const SubmitReportState({this.isLoading = false, this.error});
  final bool isLoading;
  final String? error;
}

class SubmitReportNotifier extends StateNotifier<SubmitReportState> {
  SubmitReportNotifier(this._repo) : super(const SubmitReportState());
  final ReportRepository _repo;

  Future<bool> submit({
    required ReportTargetType targetType,
    String? reportedUserId,
    String? reportedGameId,
    required String title,
    required String reason,
  }) async {
    state = const SubmitReportState(isLoading: true);
    try {
      await _repo.createReport(
        targetType: targetType,
        reportedUserId: reportedUserId,
        reportedGameId: reportedGameId,
        title: title,
        reason: reason,
      );
      state = const SubmitReportState();
      return true;
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      state = SubmitReportState(error: message);
      return false;
    }
  }
}

final submitReportProvider =
    StateNotifierProvider.autoDispose<SubmitReportNotifier, SubmitReportState>(
  (ref) => SubmitReportNotifier(ref.watch(reportRepositoryProvider)),
);
