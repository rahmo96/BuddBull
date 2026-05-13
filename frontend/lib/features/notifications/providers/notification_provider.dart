import 'dart:async';

import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/services/socket_service.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/notifications/data/notification_model.dart';
import 'package:buddbull/features/notifications/data/notification_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(apiClientProvider));
});

// ── Live stream (Phase 3) ────────────────────────────────────────────────────
/// Thin indirection over `SocketService.notificationStream` so tests can
/// override the live-update channel (with `null` for hermetic widget
/// tests, or a stubbed `StreamController` to drive realtime scenarios)
/// without having to instantiate `SocketService` — which touches
/// `FirebaseAuth` at construction time.
final notificationLiveStreamProvider =
    Provider<Stream<Map<String, dynamic>>?>((ref) {
  return ref.watch(socketServiceProvider).notificationStream;
});

// ── Inbox state ───────────────────────────────────────────────────────────────
/// Snapshot of the notification inbox for the current user.
///
/// We intentionally model this as an explicit value object (rather than
/// an `AsyncValue<List<NotificationModel>>`) because the UI needs three
/// things at once: the rendered list, the unread badge count, and a
/// per-action loading flag for "mark all read" / "refresh". A plain
/// `AsyncValue` would force callers to recompute the unread count on
/// every rebuild.
class NotificationsState {
  const NotificationsState({
    this.notifications = const <NotificationModel>[],
    this.unreadCount = 0,
    this.isLoading = false,
    this.isMutating = false,
    this.error,
    this.hasLoadedOnce = false,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;
  final bool isLoading;

  /// True while a mark-read / mark-all-read request is in flight. The UI
  /// uses this to disable the trailing action button without blanking
  /// the list (which would feel jarring).
  final bool isMutating;
  final String? error;

  /// `true` after the first successful fetch — lets the widget tree
  /// distinguish "never loaded" from "loaded and empty".
  final bool hasLoadedOnce;

  NotificationsState copyWith({
    List<NotificationModel>? notifications,
    int? unreadCount,
    bool? isLoading,
    bool? isMutating,
    Object? error = _unset,
    bool? hasLoadedOnce,
  }) {
    return NotificationsState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: identical(error, _unset) ? this.error : error as String?,
      hasLoadedOnce: hasLoadedOnce ?? this.hasLoadedOnce,
    );
  }
}

// Sentinel used to distinguish "omit" from "clear to null" in copyWith.
const Object _unset = Object();

// ── Notifier ──────────────────────────────────────────────────────────────────
class NotificationsNotifier extends StateNotifier<NotificationsState> {
  NotificationsNotifier(
    this._repo, {
    Stream<Map<String, dynamic>>? liveStream,
    GameRepository? gameRepository,
  })  : _gameRepo = gameRepository,
        super(const NotificationsState()) {
    // Fire-and-forget initial load so the badge is populated as soon as
    // the bell icon mounts. Errors land in `state.error` instead of
    // crashing the splash.
    refresh();

    // Subscribe to real-time `notification:new` pushes from Socket.io.
    // Made optional so tests (and any consumer that wants a hermetic
    // notifier) can construct a notifier without a live socket.
    if (liveStream != null) {
      _socketSub = liveStream.listen(
        _onLiveNotification,
        onError: (Object e, StackTrace st) {
          debugPrint('⚠️ NotificationsNotifier socket stream error: $e\n$st');
        },
      );
    }
  }

  final NotificationRepository _repo;
  final GameRepository? _gameRepo;
  StreamSubscription<Map<String, dynamic>>? _socketSub;

  /// Reloads the inbox from the server. Safe to call from pull-to-
  /// refresh, screen mount, or after a push notification taps in.
  Future<void> refresh() async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      final page = await _repo.getNotifications();
      state = state.copyWith(
        notifications: page.notifications,
        unreadCount: page.unreadCount,
        isLoading: false,
        hasLoadedOnce: true,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _humanise(e),
        hasLoadedOnce: true,
      );
    }
  }

  /// Optimistically marks one row read. Reverts on failure so the badge
  /// never drifts out of sync with the server.
  Future<void> markAsRead(String id) async {
    NotificationModel? target;
    for (final n in state.notifications) {
      if (n.id == id) {
        target = n;
        break;
      }
    }
    if (target == null || target.read) return;

    final patched = [
      for (final n in state.notifications)
        if (n.id == id) n.copyWith(read: true, readAt: DateTime.now()) else n,
    ];
    final prevUnread = state.unreadCount;
    state = state.copyWith(
      notifications: patched,
      unreadCount: (prevUnread - 1).clamp(0, prevUnread),
      isMutating: true,
    );

    try {
      await _repo.markAsRead(id);
      state = state.copyWith(isMutating: false);
    } catch (e) {
      state = state.copyWith(
        notifications: state.notifications
            .map((n) => n.id == id ? n.copyWith(read: false, readAt: null) : n)
            .toList(),
        unreadCount: prevUnread,
        isMutating: false,
        error: _humanise(e),
      );
    }
  }

  /// Optimistically clears the badge and flips every visible row to read,
  /// then asks the server to do the same. On failure we re-fetch so the
  /// list is always consistent with the database.
  Future<void> markAllAsRead() async {
    if (state.unreadCount == 0) return;
    final previous = state.notifications;
    final prevUnread = state.unreadCount;
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.read ? n : n.copyWith(read: true, readAt: DateTime.now()))
          .toList(),
      unreadCount: 0,
      isMutating: true,
    );

    try {
      await _repo.markAllAsRead();
      state = state.copyWith(isMutating: false);
    } catch (e) {
      state = state.copyWith(
        notifications: previous,
        unreadCount: prevUnread,
        isMutating: false,
        error: _humanise(e),
      );
    }
  }

  /// Approve / reject the join request carried by a `gameJoinRequest`
  /// notification, directly from the inbox tile.
  ///
  /// Optimistically removes the row from the visible list (and clears
  /// it from the badge if unread) so the UI stays snappy. On failure
  /// we roll back to the previous state and surface a humanised error
  /// for the caller to display.
  ///
  /// Returns `true` on success, `false` on failure — the screen uses
  /// this to decide between success-toast and error-snackbar.
  Future<bool> handleJoinRequest(String notificationId, String decision) async {
    assert(decision == 'approve' || decision == 'reject');
    if (_gameRepo == null) {
      // A handler-free notifier (used in some lightweight tests) can't
      // hit the network — surface a soft failure rather than throwing.
      state = state.copyWith(error: 'Game repository unavailable.');
      return false;
    }

    final idx = state.notifications.indexWhere((n) => n.id == notificationId);
    if (idx < 0) return false;
    final target = state.notifications[idx];
    if (target.type != 'gameJoinRequest') return false;

    final gameId = target.gameId;
    final requesterId = target.data['requesterId']?.toString();
    if (gameId == null || gameId.isEmpty || requesterId == null || requesterId.isEmpty) {
      state = state.copyWith(error: 'Invalid join-request payload.');
      return false;
    }

    // Snapshot for rollback.
    final prevList = state.notifications;
    final prevUnread = state.unreadCount;

    final without = [...state.notifications]..removeAt(idx);
    state = state.copyWith(
      notifications: without,
      unreadCount:
          target.isUnread ? (prevUnread - 1).clamp(0, prevUnread) : prevUnread,
      isMutating: true,
    );

    try {
      await _gameRepo.handleJoinRequest(
        gameId: gameId,
        userId: requesterId,
        decision: decision,
      );
      // Server has already persisted the action; also flip the row to
      // read on the server so a refresh from another device stays
      // consistent.
      if (target.isUnread) {
        unawaited(_repo.markAsRead(target.id).catchError((Object _) {
          // Non-fatal — the UI is already in the post-action state.
          return target;
        }));
      }
      state = state.copyWith(isMutating: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        notifications: prevList,
        unreadCount: prevUnread,
        isMutating: false,
        error: _humanise(e),
      );
      return false;
    }
  }

  /// Handles a `notification:new` payload pushed from the server.
  ///
  /// Behaviour:
  ///   - Parse the raw map through the same `fromJson` that
  ///     `GET /notifications` uses, so socket-pushed and HTTP-fetched
  ///     rows are byte-identical inside the state.
  ///   - Deduplicate by id — a `refresh()` that races with a socket
  ///     push must not yield two visible copies of the same row.
  ///   - Prepend (newest-first) and bump the unread badge so the bell
  ///     icon updates instantly even if the user has the inbox screen
  ///     closed.
  void _onLiveNotification(Map<String, dynamic> raw) {
    final NotificationModel incoming;
    try {
      incoming = NotificationModel.fromJson(raw);
    } catch (e, st) {
      debugPrint('⚠️ NotificationsNotifier failed to parse live row: $e\n$st');
      return;
    }
    if (incoming.id.isEmpty) return;

    final existingIdx =
        state.notifications.indexWhere((n) => n.id == incoming.id);

    if (existingIdx >= 0) {
      // Duplicate (likely a server replay / refresh race) — keep state
      // stable and don't double-count the badge.
      final existing = state.notifications[existingIdx];
      if (existing.read == incoming.read) return;
      final patched = [...state.notifications];
      patched[existingIdx] = incoming;
      state = state.copyWith(notifications: patched);
      return;
    }

    state = state.copyWith(
      notifications: [incoming, ...state.notifications],
      unreadCount:
          incoming.read ? state.unreadCount : state.unreadCount + 1,
      hasLoadedOnce: true,
    );
  }

  @override
  void dispose() {
    _socketSub?.cancel();
    _socketSub = null;
    super.dispose();
  }

  /// Strips Dio's "Exception: …" framing for nicer error banners.
  String _humanise(Object e) {
    final raw = e.toString();
    final match = RegExp(r'\): (.+)$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }
}

// ── Public providers ──────────────────────────────────────────────────────────

/// Authoritative inbox state — drives the screen, the bell badge, and any
/// future deep-link tap handlers.
///
/// Bound to `socketServiceProvider.notificationStream` so the badge and
/// list update the instant a `notification:new` payload arrives, with
/// no need for the user to pull-to-refresh.
final notificationsProvider =
    StateNotifierProvider<NotificationsNotifier, NotificationsState>((ref) {
  final repo = ref.watch(notificationRepositoryProvider);
  final liveStream = ref.watch(notificationLiveStreamProvider);
  final gameRepo = ref.watch(gameRepositoryProvider);
  return NotificationsNotifier(
    repo,
    liveStream: liveStream,
    gameRepository: gameRepo,
  );
});

/// Convenience selector for the bell badge so widgets don't rebuild on
/// unrelated inbox changes (e.g. a single item's `readAt` updating).
final unreadNotificationCountProvider = Provider<int>((ref) {
  return ref.watch(notificationsProvider.select((s) => s.unreadCount));
});
