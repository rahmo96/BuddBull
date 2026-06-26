import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/features/admin/data/admin_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

// ── Dashboard ─────────────────────────────────────────────────────────────────
final adminDashboardProvider = FutureProvider.family<AdminDashboardStats, String>((ref, period) {
  return ref.watch(adminRepositoryProvider).getDashboard(period: period);
});

// ── User list ─────────────────────────────────────────────────────────────────
final adminUsersProvider =
    FutureProvider.family<Map<String, dynamic>, String>((ref, search) {
  return ref.watch(adminRepositoryProvider).listUsers(
        search: search.isEmpty ? null : search,
        limit: 50,
      );
});

// ── Games list ────────────────────────────────────────────────────────────────
final adminGamesProvider =
    FutureProvider.family<Map<String, dynamic>, String?>((ref, status) {
  return ref.watch(adminRepositoryProvider).listGames(
        status: status,
        limit: 50,
      );
});

// ── Sports list ───────────────────────────────────────────────────────────────
final adminSportsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(adminRepositoryProvider).listSports();
});

// ── Reports list ──────────────────────────────────────────────────────────────
class AdminReportsParams {
  const AdminReportsParams({
    this.status,
    this.targetType,
    this.sort = '-createdAt',
  });

  final String? status;
  final String? targetType;
  final String sort;

  @override
  bool operator ==(Object other) =>
      other is AdminReportsParams &&
      other.status == status &&
      other.targetType == targetType &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(status, targetType, sort);
}

final adminReportsProvider =
    FutureProvider.family<Map<String, dynamic>, AdminReportsParams>((ref, params) {
  return ref.watch(adminRepositoryProvider).listReports(
        status: params.status,
        targetType: params.targetType,
        sort: params.sort,
        limit: 50,
      );
});

// ── Ban user notifier ─────────────────────────────────────────────────────────
class BanUserState {
  final bool isLoading;
  final bool success;
  final String? error;
  const BanUserState({this.isLoading = false, this.success = false, this.error});
}

class BanUserNotifier extends StateNotifier<BanUserState> {
  final AdminRepository _repo;
  BanUserNotifier(this._repo) : super(const BanUserState());

  Future<bool> banUser(String userId, {required bool isBanned, String? reason}) async {
    state = const BanUserState(isLoading: true);
    try {
      await _repo.banUser(userId, isBanned: isBanned, reason: reason);
      state = const BanUserState(success: true);
      return true;
    } catch (e) {
      state = BanUserState(error: e.toString());
      return false;
    }
  }
}

final banUserProvider = StateNotifierProvider.autoDispose<BanUserNotifier, BanUserState>(
  (ref) => BanUserNotifier(ref.watch(adminRepositoryProvider)),
);

// ── Restrict user notifier ────────────────────────────────────────────────────
class RestrictUserState {
  final bool isLoading;
  final bool success;
  final String? error;
  const RestrictUserState({this.isLoading = false, this.success = false, this.error});
}

class RestrictUserNotifier extends StateNotifier<RestrictUserState> {
  final AdminRepository _repo;
  RestrictUserNotifier(this._repo) : super(const RestrictUserState());

  Future<bool> restrictUser(
    String userId, {
    required bool isRestricted,
    String? reason,
  }) async {
    state = const RestrictUserState(isLoading: true);
    try {
      await _repo.restrictUser(userId, isRestricted: isRestricted, reason: reason);
      state = const RestrictUserState(success: true);
      return true;
    } catch (e) {
      state = RestrictUserState(error: e.toString());
      return false;
    }
  }
}

final restrictUserProvider =
    StateNotifierProvider.autoDispose<RestrictUserNotifier, RestrictUserState>(
  (ref) => RestrictUserNotifier(ref.watch(adminRepositoryProvider)),
);

// ── Broadcast notifier ────────────────────────────────────────────────────────
class BroadcastState {
  final bool isLoading;
  final bool success;
  final String? error;
  const BroadcastState({this.isLoading = false, this.success = false, this.error});
}

class BroadcastNotifier extends StateNotifier<BroadcastState> {
  final AdminRepository _repo;
  BroadcastNotifier(this._repo) : super(const BroadcastState());

  Future<bool> send({required String title, required String body, String channel = 'socket'}) async {
    state = const BroadcastState(isLoading: true);
    try {
      await _repo.broadcast(title: title, body: body, channel: channel);
      state = const BroadcastState(success: true);
      return true;
    } catch (e) {
      state = BroadcastState(error: e.toString());
      return false;
    }
  }
}

final broadcastProvider = StateNotifierProvider.autoDispose<BroadcastNotifier, BroadcastState>(
  (ref) => BroadcastNotifier(ref.watch(adminRepositoryProvider)),
);
