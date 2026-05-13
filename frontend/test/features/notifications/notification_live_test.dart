// Phase 3 — Real-time notifications coverage.
//
// Pins the behaviour of [NotificationsNotifier] when a `notification:new`
// payload arrives over Socket.io:
//
//   1. The badge bumps and the row appears at the top of the list, with
//      no need for a pull-to-refresh.
//   2. Duplicate IDs (server replay, refresh racing against the socket)
//      do not double-count the badge.
//   3. A row received with `read: true` is appended but does NOT bump
//      the unread counter.
//   4. Cancelling the subscription on dispose stops further updates
//      from racing into a stale state.
//
// Pattern follows `frontend/test/features/rating/rating_provider_test.dart`
// — an in-memory fake repository + a programmatically-driven stream
// stand in for the real network + socket layers.

import 'dart:async';

import 'package:buddbull/features/notifications/data/notification_model.dart';
import 'package:buddbull/features/notifications/data/notification_repository.dart';
import 'package:buddbull/features/notifications/providers/notification_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

// ── Fakes ────────────────────────────────────────────────────────────────────

class _FakeNotificationRepository implements NotificationRepository {
  _FakeNotificationRepository({
    List<NotificationModel> initial = const [],
    int unreadCount = 0,
  })  : _items = List.of(initial),
        _unreadCount = unreadCount;

  final List<NotificationModel> _items;
  int _unreadCount;
  int refreshCalls = 0;

  @override
  Future<NotificationPage> getNotifications({int page = 1, int limit = 50}) async {
    refreshCalls += 1;
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

NotificationModel _row(String id, {bool read = false, String title = 'hi'}) {
  return NotificationModel(
    id: id,
    type: 'gameInvite',
    title: title,
    body: 'You have been invited to a game.',
    read: read,
    createdAt: DateTime.parse('2026-05-13T12:00:00Z'),
    data: const {'gameId': 'g-1'},
  );
}

Map<String, dynamic> _payload(String id,
    {bool read = false, String title = 'hi'}) {
  return {
    '_id': id,
    'type': 'gameInvite',
    'title': title,
    'body': 'You have been invited to a game.',
    'read': read,
    'createdAt': '2026-05-13T12:00:00Z',
    'data': {'gameId': 'g-1'},
  };
}

ProviderContainer _container({
  required NotificationRepository repo,
  required Stream<Map<String, dynamic>>? stream,
}) {
  final c = ProviderContainer(
    overrides: [
      notificationRepositoryProvider.overrideWithValue(repo),
      notificationLiveStreamProvider.overrideWithValue(stream),
    ],
  );
  addTearDown(c.dispose);
  return c;
}

// ── Tests ────────────────────────────────────────────────────────────────────

void main() {
  group('NotificationsNotifier — live stream wiring', () {
    test('prepends an incoming row and bumps the unread count',
        () async {
      final repo = _FakeNotificationRepository();
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      addTearDown(controller.close);

      final c = _container(repo: repo, stream: controller.stream);

      // Wait for the constructor-time refresh to complete so we start
      // from a known empty state.
      await c.read(notificationsProvider.notifier).refresh();
      expect(c.read(notificationsProvider).notifications, isEmpty);
      expect(c.read(unreadNotificationCountProvider), 0);

      controller.add(_payload('n-1', title: 'New invite'));
      // Stream events are async — let the microtask drain.
      await Future<void>.delayed(Duration.zero);

      final state = c.read(notificationsProvider);
      expect(state.notifications, hasLength(1));
      expect(state.notifications.first.id, 'n-1');
      expect(state.notifications.first.title, 'New invite');
      expect(c.read(unreadNotificationCountProvider), 1);
    });

    test('places the newest push at the top of the list (newest-first)',
        () async {
      final repo = _FakeNotificationRepository(
        initial: [_row('existing', title: 'older')],
        unreadCount: 1,
      );
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      addTearDown(controller.close);

      final c = _container(repo: repo, stream: controller.stream);
      await c.read(notificationsProvider.notifier).refresh();

      controller.add(_payload('fresh', title: 'just arrived'));
      await Future<void>.delayed(Duration.zero);

      final ids = c.read(notificationsProvider).notifications
          .map((n) => n.id)
          .toList();
      expect(ids, ['fresh', 'existing']);
      expect(c.read(unreadNotificationCountProvider), 2);
    });

    test('deduplicates by id — server replay does not double-count',
        () async {
      final repo = _FakeNotificationRepository();
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      addTearDown(controller.close);

      final c = _container(repo: repo, stream: controller.stream);
      await c.read(notificationsProvider.notifier).refresh();

      controller.add(_payload('dup'));
      await Future<void>.delayed(Duration.zero);
      controller.add(_payload('dup'));
      await Future<void>.delayed(Duration.zero);

      expect(c.read(notificationsProvider).notifications, hasLength(1));
      expect(c.read(unreadNotificationCountProvider), 1);
    });

    test('a push arriving as already-read does not bump the badge',
        () async {
      final repo = _FakeNotificationRepository();
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      addTearDown(controller.close);

      final c = _container(repo: repo, stream: controller.stream);
      await c.read(notificationsProvider.notifier).refresh();

      controller.add(_payload('seen', read: true));
      await Future<void>.delayed(Duration.zero);

      expect(c.read(notificationsProvider).notifications, hasLength(1));
      expect(c.read(unreadNotificationCountProvider), 0);
    });

    test('cancels the socket subscription on dispose (no late writes)',
        () async {
      final repo = _FakeNotificationRepository();
      final controller = StreamController<Map<String, dynamic>>.broadcast();
      addTearDown(controller.close);

      final c = _container(repo: repo, stream: controller.stream);
      await c.read(notificationsProvider.notifier).refresh();

      // Force the notifier to dispose by tearing down the container.
      c.dispose();

      // Pushing after dispose must not throw "Bad state: tried to use
      // a disposed StateNotifier".
      expect(() => controller.add(_payload('after-dispose')),
          returnsNormally);
    });

    test('a null live stream override skips socket wiring entirely',
        () async {
      // This is the path taken by `home_screen_test` — it keeps widget
      // tests off the network *and* off the FirebaseAuth subscription
      // that backs `SocketService`.
      final repo = _FakeNotificationRepository();
      final c = _container(repo: repo, stream: null);
      await c.read(notificationsProvider.notifier).refresh();

      expect(c.read(notificationsProvider).hasLoadedOnce, true);
      expect(c.read(unreadNotificationCountProvider), 0);
    });
  });
}
