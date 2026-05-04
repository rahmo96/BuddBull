import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';

// ── Dashboard stats model ─────────────────────────────────────────────────────
class AdminDashboardStats {
  final String period;
  final AdminUserStats users;
  final AdminGameStats games;
  final int totalLogs;
  final List<SportCount> sportBreakdown;
  final List<DailyCount> dailyRegistrations;

  const AdminDashboardStats({
    required this.period,
    required this.users,
    required this.games,
    required this.totalLogs,
    required this.sportBreakdown,
    required this.dailyRegistrations,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) =>
      AdminDashboardStats(
        period: json['period']?.toString() ?? '30d',
        users: AdminUserStats.fromJson(
            json['users'] as Map<String, dynamic>? ?? {}),
        games: AdminGameStats.fromJson(
            json['games'] as Map<String, dynamic>? ?? {}),
        totalLogs: (json['performance']?['totalLogs'] as num?)?.toInt() ?? 0,
        sportBreakdown: (json['sportBreakdown'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(SportCount.fromJson)
            .toList(),
        dailyRegistrations: (json['dailyRegistrations'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DailyCount.fromJson)
            .toList(),
      );
}

class AdminUserStats {
  final int total, active, newUsers, banned, churned;
  final String churnRate;

  const AdminUserStats({
    this.total = 0,
    this.active = 0,
    this.newUsers = 0,
    this.banned = 0,
    this.churned = 0,
    this.churnRate = '0%',
  });

  factory AdminUserStats.fromJson(Map<String, dynamic> json) => AdminUserStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        active: (json['active'] as num?)?.toInt() ?? 0,
        newUsers: (json['new'] as num?)?.toInt() ?? 0,
        banned: (json['banned'] as num?)?.toInt() ?? 0,
        churned: (json['churned'] as num?)?.toInt() ?? 0,
        churnRate: json['churnRate']?.toString() ?? '0%',
      );
}

class AdminGameStats {
  final int total, active, completed, cancelled;

  const AdminGameStats(
      {this.total = 0,
      this.active = 0,
      this.completed = 0,
      this.cancelled = 0});

  factory AdminGameStats.fromJson(Map<String, dynamic> json) => AdminGameStats(
        total: (json['total'] as num?)?.toInt() ?? 0,
        active: (json['active'] as num?)?.toInt() ?? 0,
        completed: (json['completed'] as num?)?.toInt() ?? 0,
        cancelled: (json['cancelled'] as num?)?.toInt() ?? 0,
      );
}

class SportCount {
  final String sport;
  final int count;

  const SportCount({required this.sport, required this.count});

  factory SportCount.fromJson(Map<String, dynamic> json) => SportCount(
        sport: json['sport']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

class DailyCount {
  final String date;
  final int count;

  const DailyCount({required this.date, required this.count});

  factory DailyCount.fromJson(Map<String, dynamic> json) => DailyCount(
        date: json['date']?.toString() ?? '',
        count: (json['count'] as num?)?.toInt() ?? 0,
      );
}

// ── Repository ────────────────────────────────────────────────────────────────
class AdminRepository {
  final ApiClient _client;
  const AdminRepository(this._client);

  Future<AdminDashboardStats> getDashboard({String period = '30d'}) async {
    final res = await _client.get(
      ApiEndpoints.adminDashboard,
      queryParams: {'period': period},
    );
    return AdminDashboardStats.fromJson(res['data'] as Map<String, dynamic>);
  }

  Future<Map<String, dynamic>> listUsers(
      {int page = 1, int limit = 20, String? search}) async {
    final res = await _client.get(
      ApiEndpoints.adminUsers,
      queryParams: {
        'page': page,
        'limit': limit,
        if (search != null) 'search': search,
      },
    );
    return res['data'] as Map<String, dynamic>;
  }

  Future<void> banUser(String userId,
      {required bool isBanned, String? reason}) async {
    await _client.patch(
      ApiEndpoints.adminBanUser(userId),
      data: {'isBanned': isBanned, if (reason != null) 'reason': reason},
    );
  }

  Future<void> deleteUser(String userId) async {
    await _client.delete(ApiEndpoints.adminDeleteUser(userId));
  }

  Future<void> broadcast(
      {required String title,
      required String body,
      String channel = 'socket'}) async {
    await _client.post(
      ApiEndpoints.adminBroadcast,
      data: {'title': title, 'body': body, 'channel': channel},
    );
  }
}
