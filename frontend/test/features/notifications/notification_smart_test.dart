// Phase 4 — Smart notification tile behaviour.
//
// Two areas under test:
//
//   1. The `gameJoinRequest` quick action (`handleJoinRequest` on the
//      notifier): approve and reject paths optimistically remove the
//      row from the inbox, bump the unread badge down, and call the
//      correct GameRepository method. Network failures roll the state
//      back without dropping the badge count.
//
//   2. Constructor + provider wiring. We don't widget-test the screen
//      here — the rating-aware tap behaviour is encoded in the screen
//      file and exercised by manual QA + the existing live-stream
//      provider tests. Pinning the notifier-level contract is enough
//      to prevent regressions in the API surface the screen relies on.

import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/notifications/data/notification_model.dart';
import 'package:buddbull/features/notifications/data/notification_repository.dart';
import 'package:buddbull/features/notifications/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_bootstrap.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _InMemoryNotificationRepository implements NotificationRepository {
  _InMemoryNotificationRepository(this._items, {required int unreadCount})
      : _unreadCount = unreadCount;

  final List<NotificationModel> _items;
  int _unreadCount;

  @override
  Future<NotificationPage> getNotifications({int page = 1, int limit = 50}) async {
    return NotificationPage(
      notifications: List.unmodifiable(_items),
      unreadCount: _unreadCount,
      total: _items.length,
      page: page,
      limit: limit,
      pages: 1,
    );
  }

  @override
  Future<NotificationModel> markAsRead(String id) async {
    final idx = _items.indexWhere((n) => n.id == id);
    if (idx == -1) throw StateError('not found');
    final updated = _items[idx].copyWith(read: true, readAt: DateTime.now());
    _items[idx] = updated;
    if (_unreadCount > 0) _unreadCount -= 1;
    return updated;
  }

  @override
  Future<int> markAllAsRead() async {
    final touched = _unreadCount;
    _unreadCount = 0;
    return touched;
  }
}

/// Subclass that overrides only the method under test. Every other
/// GameRepository call would fall through to the real implementation
/// (which would then try to fire HTTP requests), but our notifier path
/// only ever invokes `handleJoinRequest` — so the parent `ApiClient`
/// stays untouched.
class _StubGameRepository extends GameRepository {
  _StubGameRepository(super.api);

  final List<({String gameId, String userId, String decision})> calls = [];
  bool throwNext = false;

  @override
  Future<GameModel> handleJoinRequest({
    required String gameId,
    required String userId,
    required String decision,
    String? reason,
  }) async {
    calls.add((gameId: gameId, userId: userId, decision: decision));
    if (throwNext) {
      throwNext = false;
      throw Exception('boom');
    }
    return _stubGame();
  }
}

NotificationModel _joinRequestRow(
  String id, {
  required String gameId,
  required String requesterId,
  bool read = false,
}) {
  return NotificationModel(
    id: id,
    type: 'gameJoinRequest',
    title: 'New Join Request',
    body: 'A player has requested to join your game.',
    read: read,
    createdAt: DateTime.parse('2026-05-13T12:00:00Z'),
    data: {'gameId': gameId, 'requesterId': requesterId},
  );
}

GameModel _stubGame() {
  // The notifier never reads any field on this — it just needs the
  // Future to resolve to *something* GameModel-shaped. We omit the
  // optional `organizer` map so the default fallback is used instead
  // of needing the full first/last-name fixture.
  return GameModel.fromJson({
    '_id': 'g-1',
    'title': 'Stub',
    'sport': 'football',
    'scheduledAt': DateTime.now().toUtc().toIso8601String(),
    'durationMinutes': 60,
    'location': {'city': 'London'},
    'maxPlayers': 10,
    'status': 'open',
  });
}

ProviderContainer _container({
  required NotificationRepository repo,
  required GameRepository gameRepo,
}) {
  final c = ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
      notificationLiveStreamProvider.overrideWithValue(null),
      gameRepositoryProvider.overrideWithValue(gameRepo),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  // Firebase needs to be initialised before any code path that
  // touches `FirebaseAuth.instance` (the ApiClient auth interceptor
  // references it lazily). Even though our stub repository never
  // actually hits the network, the parent constructor goes through
  // ApiClient(), which registers the interceptor.
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('NotificationsNotifier.handleJoinRequest', () {
    test('approve: removes the row optimistically and calls the API',
        () async {
      final row = _joinRequestRow(
        'n-1',
        gameId: 'g-7',
        requesterId: 'u-42',
      );
      final repo = _InMemoryNotificationRepository([row], unreadCount: 1);
      final gameRepo = _StubGameRepository(ApiClient());
      final c = _container(repo: repo, gameRepo: gameRepo);
      await c.read(notificationsProvider.notifier).refresh();
      expect(c.read(unreadNotificationCountProvider), 1);

      final ok = await c
          .read(notificationsProvider.notifier)
          .handleJoinRequest('n-1', 'approve');

      expect(ok, true);
      expect(c.read(notificationsProvider).notifications, isEmpty);
      expect(c.read(unreadNotificationCountProvider), 0);
      expect(gameRepo.calls, [
        (gameId: 'g-7', userId: 'u-42', decision: 'approve'),
      ]);
    });

    test('reject: removes the row optimistically and calls the API',
        () async {
      final row = _joinRequestRow(
        'n-1',
        gameId: 'g-7',
        requesterId: 'u-42',
      );
      final repo = _InMemoryNotificationRepository([row], unreadCount: 1);
      final gameRepo = _StubGameRepository(ApiClient());
      final c = _container(repo: repo, gameRepo: gameRepo);
      await c.read(notificationsProvider.notifier).refresh();

      final ok = await c
          .read(notificationsProvider.notifier)
          .handleJoinRequest('n-1', 'reject');

      expect(ok, true);
      expect(c.read(notificationsProvider).notifications, isEmpty);
      expect(gameRepo.calls.single.decision, 'reject');
    });

    test('rolls back state when the network call fails', () async {
      final row = _joinRequestRow(
        'n-1',
        gameId: 'g-7',
        requesterId: 'u-42',
      );
      final repo = _InMemoryNotificationRepository([row], unreadCount: 1);
      final gameRepo = _StubGameRepository(ApiClient())..throwNext = true;
      final c = _container(repo: repo, gameRepo: gameRepo);
      await c.read(notificationsProvider.notifier).refresh();

      final ok = await c
          .read(notificationsProvider.notifier)
          .handleJoinRequest('n-1', 'approve');

      expect(ok, false);
      // Row is restored — the badge MUST NOT drift out of sync with the
      // server after a network failure.
      expect(c.read(notificationsProvider).notifications, hasLength(1));
      expect(c.read(unreadNotificationCountProvider), 1);
      expect(c.read(notificationsProvider).error, isNotNull);
    });

    test('refuses when the notification is not a gameJoinRequest', () async {
      final row = NotificationModel(
        id: 'n-1',
        type: 'gameCompleted',
        title: 'done',
        body: '',
        read: false,
        createdAt: DateTime.now(),
      );
      final repo = _InMemoryNotificationRepository([row], unreadCount: 1);
      final gameRepo = _StubGameRepository(ApiClient());
      final c = _container(repo: repo, gameRepo: gameRepo);
      await c.read(notificationsProvider.notifier).refresh();

      final ok = await c
          .read(notificationsProvider.notifier)
          .handleJoinRequest('n-1', 'approve');

      expect(ok, false);
      // The row stays — no optimistic removal because we never reached
      // the network.
      expect(c.read(notificationsProvider).notifications, hasLength(1));
      expect(gameRepo.calls, isEmpty);
    });

    test('refuses when the payload is missing gameId/requesterId',
        () async {
      final row = NotificationModel(
        id: 'n-1',
        type: 'gameJoinRequest',
        title: 'New Join Request',
        body: '',
        read: false,
        createdAt: DateTime.now(),
        data: const {'gameId': 'g-7'}, // requesterId missing
      );
      final repo = _InMemoryNotificationRepository([row], unreadCount: 1);
      final gameRepo = _StubGameRepository(ApiClient());
      final c = _container(repo: repo, gameRepo: gameRepo);
      await c.read(notificationsProvider.notifier).refresh();

      final ok = await c
          .read(notificationsProvider.notifier)
          .handleJoinRequest('n-1', 'approve');

      expect(ok, false);
      expect(c.read(notificationsProvider).notifications, hasLength(1));
      expect(gameRepo.calls, isEmpty);
      expect(c.read(notificationsProvider).error, contains('Invalid'));
    });
  });
}
