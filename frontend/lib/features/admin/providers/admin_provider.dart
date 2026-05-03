import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/features/admin/data/admin_repository.dart';

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

// ── Dashboard ─────────────────────────────────────────────────────────────────
final adminDashboardProvider = FutureProvider.family<AdminDashboardStats, String>((ref, period) {
  return ref.watch(adminRepositoryProvider).getDashboard(period: period);
});

// ── User list ─────────────────────────────────────────────────────────────────
final adminUsersProvider = FutureProvider<Map<String, dynamic>>((ref) {
  return ref.watch(adminRepositoryProvider).listUsers();
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
