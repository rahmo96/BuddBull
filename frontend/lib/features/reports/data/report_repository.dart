import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';

enum ReportTargetType { user, game }

class ReportModel {
  const ReportModel({
    required this.id,
    required this.targetType,
    required this.title,
    required this.reason,
    required this.status,
    required this.createdAt,
    this.reporterUsername,
    this.reportedUsername,
    this.reportedGameTitle,
    this.adminNotes,
  });

  final String id;
  final String targetType;
  final String title;
  final String reason;
  final String status;
  final DateTime createdAt;
  final String? reporterUsername;
  final String? reportedUsername;
  final String? reportedGameTitle;
  final String? adminNotes;

  factory ReportModel.fromJson(Map<String, dynamic> json) {
    final reporter = json['reporter'] as Map<String, dynamic>?;
    final reportedUser = json['reportedUser'] as Map<String, dynamic>?;
    final reportedGame = json['reportedGame'] as Map<String, dynamic>?;

    return ReportModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      targetType: json['targetType']?.toString() ?? 'user',
      title: json['title']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
      status: json['status']?.toString() ?? 'open',
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      reporterUsername: reporter?['username']?.toString(),
      reportedUsername: reportedUser?['username']?.toString(),
      reportedGameTitle: reportedGame?['title']?.toString(),
      adminNotes: json['adminNotes']?.toString(),
    );
  }
}

class ReportRepository {
  const ReportRepository(this._client);
  final ApiClient _client;

  Future<ReportModel> createReport({
    required ReportTargetType targetType,
    String? reportedUserId,
    String? reportedGameId,
    required String title,
    required String reason,
  }) async {
    final res = await _client.post(
      ApiEndpoints.reports,
      data: {
        'targetType': targetType.name,
        if (reportedUserId != null) 'reportedUserId': reportedUserId,
        if (reportedGameId != null) 'reportedGameId': reportedGameId,
        'title': title,
        'reason': reason,
      },
    );
    final reportJson =
        (res['data'] as Map<String, dynamic>? ?? {})['report'] as Map<String, dynamic>? ??
            res['data'] as Map<String, dynamic>? ??
            {};
    return ReportModel.fromJson(reportJson);
  }

  Future<List<ReportModel>> listMyReports() async {
    final res = await _client.get(ApiEndpoints.myReports);
    final data = res['data'] as Map<String, dynamic>? ?? {};
    return (data['reports'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(ReportModel.fromJson)
        .toList();
  }
}
