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

  /// Returns `null` on success, or a user-facing error message on failure.
  Future<String?> submit({
    required ReportTargetType targetType,
    String? reportedUserId,
    String? reportedGameId,
    required String title,
    required String reason,
  }) async {
    if (mounted) state = const SubmitReportState(isLoading: true);
    try {
      await _repo.createReport(
        targetType: targetType,
        reportedUserId: reportedUserId,
        reportedGameId: reportedGameId,
        title: title,
        reason: reason,
      );
      if (mounted) state = const SubmitReportState();
      return null;
    } catch (e) {
      final message = e is AppException ? e.message : e.toString();
      if (mounted) state = SubmitReportState(error: message);
      return message;
    }
  }
}

final submitReportProvider =
    StateNotifierProvider<SubmitReportNotifier, SubmitReportState>(
  (ref) => SubmitReportNotifier(ref.watch(reportRepositoryProvider)),
);
