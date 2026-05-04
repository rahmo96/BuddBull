import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/performance/data/models/performance_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final performanceRepositoryProvider =
    Provider<PerformanceRepository>((ref) {
  return PerformanceRepository(ref.watch(apiClientProvider));
});

// ── Repository ────────────────────────────────────────────────────────────────
class PerformanceRepository {
  const PerformanceRepository(this._api);
  final ApiClient _api;

  // ── Create log ────────────────────────────────────────────
  Future<PerformanceLogModel> createLog(
      Map<String, dynamic> payload) async {
    final body =
        await _api.post(ApiEndpoints.performanceLogs, data: payload);
    final data = body['data'] as Map<String, dynamic>;
    return PerformanceLogModel.fromJson(
        data['log'] as Map<String, dynamic>);
  }

  // ── Get logs (own or other user) ──────────────────────────
  Future<List<PerformanceLogModel>> getLogs({
    String? userId,
    String? sport,
    String? logType,
    int page = 1,
    int limit = 20,
  }) async {
    final endpoint = userId != null
        ? ApiEndpoints.userLogs(userId)
        : ApiEndpoints.performanceLogs;

    final body = await _api.get(endpoint, queryParams: {
      if (sport != null) 'sport': sport,
      if (logType != null) 'logType': logType,
      'page': page,
      'limit': limit,
    });
    final data = body['data'] as Map<String, dynamic>;
    final list = data['logs'] as List<dynamic>;
    return list
        .map((e) => PerformanceLogModel.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }

  // ── Get single log ────────────────────────────────────────
  Future<PerformanceLogModel> getLog(String id) async {
    final body =
        await _api.get(ApiEndpoints.performanceLog(id));
    final data = body['data'] as Map<String, dynamic>;
    return PerformanceLogModel.fromJson(
        data['log'] as Map<String, dynamic>);
  }

  // ── Update log ────────────────────────────────────────────
  Future<PerformanceLogModel> updateLog(
      String id, Map<String, dynamic> updates) async {
    final body = await _api.patch(
        ApiEndpoints.performanceLog(id),
        data: updates);
    final data = body['data'] as Map<String, dynamic>;
    return PerformanceLogModel.fromJson(
        data['log'] as Map<String, dynamic>);
  }

  // ── Delete log ────────────────────────────────────────────
  Future<void> deleteLog(String id) =>
      _api.delete(ApiEndpoints.performanceLog(id));

  // ── Aggregated stats ──────────────────────────────────────
  Future<UserPerformanceStats> getStats({String? sport}) async {
    final body = await _api.get(
      ApiEndpoints.performanceStats,
      queryParams: {
        if (sport != null) 'sport': sport,
      },
    );
    return UserPerformanceStats.fromJson(
        body['data'] as Map<String, dynamic>);
  }

  // ── Streak history ────────────────────────────────────────
  Future<List<HeatmapEntry>> getStreakHistory() async {
    final body =
        await _api.get(ApiEndpoints.performanceStreak);
    final data = body['data'] as Map<String, dynamic>;
    final list = data['history'] as List<dynamic>? ?? [];
    return list
        .map((e) => HeatmapEntry.fromJson(
            e as Map<String, dynamic>))
        .toList();
  }
}
