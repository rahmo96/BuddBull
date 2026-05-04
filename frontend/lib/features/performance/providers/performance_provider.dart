import 'package:buddbull/features/performance/data/models/performance_model.dart';
import 'package:buddbull/features/performance/data/performance_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Simple fetch providers ────────────────────────────────────────────────────
final performanceStatsProvider =
    FutureProvider.autoDispose<UserPerformanceStats>((ref) {
  return ref.watch(performanceRepositoryProvider).getStats();
});

final performanceLogsProvider =
    FutureProvider.autoDispose<List<PerformanceLogModel>>((ref) {
  return ref
      .watch(performanceRepositoryProvider)
      .getLogs();
});

final streakHistoryProvider =
    FutureProvider.autoDispose<List<HeatmapEntry>>((ref) {
  return ref
      .watch(performanceRepositoryProvider)
      .getStreakHistory();
});

// ── Create log state ──────────────────────────────────────────────────────────
class CreateLogState {
  const CreateLogState({
    this.isSubmitting = false,
    this.error,
    this.createdLog,
    this.hasPersonalBests = false,
  });

  final bool isSubmitting;
  final String? error;
  final PerformanceLogModel? createdLog;
  final bool hasPersonalBests;

  CreateLogState copyWith({
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    PerformanceLogModel? createdLog,
    bool? hasPersonalBests,
  }) {
    return CreateLogState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : error ?? this.error,
      createdLog: createdLog ?? this.createdLog,
      hasPersonalBests:
          hasPersonalBests ?? this.hasPersonalBests,
    );
  }
}

final createLogProvider = StateNotifierProvider.autoDispose<
    CreateLogNotifier, CreateLogState>(
  (ref) => CreateLogNotifier(
      ref.watch(performanceRepositoryProvider), ref),
);

class CreateLogNotifier extends StateNotifier<CreateLogState> {
  CreateLogNotifier(this._repo, this._ref)
      : super(const CreateLogState());

  final PerformanceRepository _repo;
  final Ref _ref;

  Future<bool> createLog(Map<String, dynamic> payload) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      final log = await _repo.createLog(payload);
      state = state.copyWith(
        isSubmitting: false,
        createdLog: log,
        hasPersonalBests: log.newPersonalBests.isNotEmpty,
      );
      _ref.invalidate(performanceStatsProvider);
      _ref.invalidate(performanceLogsProvider);
      return true;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: _msg(e));
      return false;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);

  String _msg(Object e) {
    final raw = e.toString();
    final m = RegExp(r'\): (.+)$').firstMatch(raw);
    return m?.group(1) ?? raw;
  }
}

// ── Delete log notifier ───────────────────────────────────────────────────────
class DeleteLogState {
  const DeleteLogState(
      {this.deletingId, this.error});
  final String? deletingId;
  final String? error;
}

final deleteLogProvider = StateNotifierProvider.autoDispose<
    DeleteLogNotifier, DeleteLogState>(
  (ref) => DeleteLogNotifier(
      ref.watch(performanceRepositoryProvider), ref),
);

class DeleteLogNotifier extends StateNotifier<DeleteLogState> {
  DeleteLogNotifier(this._repo, this._ref)
      : super(const DeleteLogState());

  final PerformanceRepository _repo;
  final Ref _ref;

  Future<void> delete(String id) async {
    state = DeleteLogState(deletingId: id);
    try {
      await _repo.deleteLog(id);
      state = const DeleteLogState();
      _ref.invalidate(performanceStatsProvider);
      _ref.invalidate(performanceLogsProvider);
    } catch (e) {
      final raw = e.toString();
      final m = RegExp(r'\): (.+)$').firstMatch(raw);
      state = DeleteLogState(error: m?.group(1) ?? raw);
    }
  }
}
