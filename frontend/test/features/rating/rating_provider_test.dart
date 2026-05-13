// Riverpod-level coverage for the post-game rating flow.
//
// We exercise three behaviours that are easy to regress on:
//
//   1. `pendingRatingsProvider` faithfully reflects whatever the
//      `RatingRepository` returns.
//   2. After [RatePlayerNotifier.rate] succeeds, the next read of
//      `pendingRatingsProvider` triggers a fresh repository fetch —
//      this is the mechanism that drains rated opponents from the
//      queue and lets `GameDetailScreen` auto-navigate.
//   3. `dismissGameRatingQueue` invokes the dismiss endpoint and
//      invalidates the queue providers so the host screens (Home,
//      Game Detail) repaint without manual pull-to-refresh.
//
// The tests use a stateful in-memory [_FakeRatingRepository] in place of
// real network calls. They do not touch the GameDetailScreen widget —
// that's covered by `game_detail_rate_button_test.dart`.

import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/rating/data/models/rating_model.dart';
import 'package:buddbull/features/rating/data/rating_repository.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_bootstrap.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Stateful fake repository
// ─────────────────────────────────────────────────────────────────────────────

/// In-memory stand-in for [RatingRepository] used by every test in this
/// file. Tracks call counts so we can assert provider invalidations
/// actually re-fetch from the network layer.
class _FakeRatingRepository implements RatingRepository {
  _FakeRatingRepository({List<PendingRatingItem> initial = const []})
      : _pending = List.of(initial);

  final List<PendingRatingItem> _pending;
  final List<String> dismissedGameIds = [];
  final List<Map<String, dynamic>> ratedCalls = [];

  int getPendingCount = 0;

  void setPending(List<PendingRatingItem> next) {
    _pending
      ..clear()
      ..addAll(next);
  }

  @override
  Future<List<PendingRatingItem>> getPendingRatings() async {
    getPendingCount += 1;
    return List.of(_pending);
  }

  @override
  Future<RatingModel> ratePlayer({
    required String rateeId,
    required String gameId,
    required int reliabilityScore,
    required int behaviorScore,
    String? comment,
    bool isAnonymous = false,
  }) async {
    ratedCalls.add({
      'rateeId': rateeId,
      'gameId': gameId,
      'reliabilityScore': reliabilityScore,
      'behaviorScore': behaviorScore,
      'comment': comment,
      'isAnonymous': isAnonymous,
    });

    final item = _pending.firstWhere(
      (e) => e.gameId == gameId,
      orElse: () => const PendingRatingItem(
        gameId: '',
        gameTitle: '',
        gameSport: '',
        pendingPlayers: [],
      ),
    );
    if (item.gameId.isNotEmpty) {
      final remaining = item.pendingPlayers
          .where((p) => (p['_id'] ?? p['id']).toString() != rateeId)
          .toList();

      final idx = _pending.indexOf(item);
      if (remaining.isEmpty) {
        _pending.removeAt(idx);
      } else {
        _pending[idx] = PendingRatingItem(
          gameId: item.gameId,
          gameTitle: item.gameTitle,
          gameSport: item.gameSport,
          pendingPlayers: remaining,
        );
      }
    }

    return RatingModel(
      id: 'r-${ratedCalls.length}',
      rateeId: rateeId,
      reliabilityScore: reliabilityScore,
      behaviorScore: behaviorScore,
      comment: comment,
      isAnonymous: isAnonymous,
      createdAt: DateTime(2026, 5, 13),
    );
  }

  @override
  Future<void> dismissGameRatings(String gameId) async {
    dismissedGameIds.add(gameId);
    _pending.removeWhere((e) => e.gameId == gameId);
  }

  // ── Unused surface — fail loudly if a test path stumbles into them ────────
  @override
  Future<RatingProfileSummary> getProfileSummary(String userId) =>
      throw UnimplementedError('Not exercised by these tests');

  @override
  Future<List<RatingModel>> getReceivedRatings({int page = 1, int limit = 20}) =>
      throw UnimplementedError('Not exercised by these tests');
}

PendingRatingItem _item(String gameId, List<String> playerIds) =>
    PendingRatingItem(
      gameId: gameId,
      gameTitle: 'Game $gameId',
      gameSport: 'football',
      pendingPlayers: [
        for (final id in playerIds)
          {'_id': id, 'firstName': 'Player', 'lastName': id},
      ],
    );

/// Builds a `ProviderContainer` wired up with the fake repository plus
/// no-op overrides for the game providers that `dismissGameRatingQueue`
/// invalidates.
ProviderContainer _container(_FakeRatingRepository repo) {
  return ProviderContainer(
    overrides: [
      ratingRepositoryProvider.overrideWithValue(repo),
      gameDetailProvider.overrideWith((ref, id) async => _unreachableGame(id)),
      myGamesProvider.overrideWith((ref) async => <GameModel>[]),
      calendarGamesProvider.overrideWith((ref) async => <GameModel>[]),
    ],
  );
}

GameModel _unreachableGame(String id) {
  throw StateError(
    'gameDetailProvider($id) was unexpectedly read in a rating_provider_test',
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// pendingRatingsProvider
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('pendingRatingsProvider', () {
    test('reflects the repository\'s pending list verbatim', () async {
      final repo = _FakeRatingRepository(initial: [
        _item('g1', ['u2', 'u3']),
        _item('g2', ['u4']),
      ]);
      final c = _container(repo);
      addTearDown(c.dispose);

      final pending = await c.read(pendingRatingsProvider.future);

      expect(pending, hasLength(2));
      expect(pending.map((e) => e.gameId), ['g1', 'g2']);
      expect(pending[0].pendingPlayers, hasLength(2));
      expect(repo.getPendingCount, 1);
    });

    test('returns an empty list when no completed games await ratings', () async {
      final repo = _FakeRatingRepository();
      final c = _container(repo);
      addTearDown(c.dispose);

      final pending = await c.read(pendingRatingsProvider.future);
      expect(pending, isEmpty);
    });

    test('invalidation re-fetches from the repository (drains drained items)',
        () async {
      final repo = _FakeRatingRepository(initial: [
        _item('g1', ['u2']),
      ]);
      final c = _container(repo);
      addTearDown(c.dispose);

      final first = await c.read(pendingRatingsProvider.future);
      expect(first, hasLength(1));

      // External actor (rating sheet, dismiss button, push-notification
      // refresh, etc.) shifts the queue. Invalidating the provider must
      // cause the next read to hit the repo again, not return cached data.
      repo.setPending([]);
      c.invalidate(pendingRatingsProvider);

      final second = await c.read(pendingRatingsProvider.future);
      expect(second, isEmpty);
      expect(repo.getPendingCount, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // RatePlayerNotifier
  // ──────────────────────────────────────────────────────────────────────────

  group('ratePlayerProvider', () {
    test('successful rate forwards args to the repository and invalidates queue',
        () async {
      final repo = _FakeRatingRepository(initial: [
        _item('g1', ['u2', 'u3']),
      ]);
      final c = _container(repo);
      addTearDown(c.dispose);

      // Warm the provider so `invalidate` has something to drop.
      final before = await c.read(pendingRatingsProvider.future);
      expect(before.first.pendingPlayers, hasLength(2));

      final ok = await c.read(ratePlayerProvider.notifier).rate(
            rateeId: 'u2',
            gameId: 'g1',
            reliabilityScore: 4,
            behaviorScore: 5,
            comment: 'On time',
          );

      expect(ok, isTrue);
      expect(c.read(ratePlayerProvider).success, isTrue);
      expect(c.read(ratePlayerProvider).error, isNull);

      // Repository got exactly one call with the right shape.
      expect(repo.ratedCalls, hasLength(1));
      expect(repo.ratedCalls.single['rateeId'], 'u2');
      expect(repo.ratedCalls.single['gameId'], 'g1');
      expect(repo.ratedCalls.single['reliabilityScore'], 4);
      expect(repo.ratedCalls.single['behaviorScore'], 5);
      expect(repo.ratedCalls.single['comment'], 'On time');

      // Queue was invalidated → next read goes back to the repo and the
      // rated player no longer appears.
      final after = await c.read(pendingRatingsProvider.future);
      expect(repo.getPendingCount, 2);
      expect(after.single.pendingPlayers, hasLength(1));
      expect(
        after.single.pendingPlayers.single['_id'],
        'u3',
        reason: 'u2 was rated and should drop out of the queue',
      );
    });

    test('rating the last opponent leaves the queue empty', () async {
      final repo = _FakeRatingRepository(initial: [
        _item('g1', ['u2']),
      ]);
      final c = _container(repo);
      addTearDown(c.dispose);

      await c.read(pendingRatingsProvider.future);
      final ok = await c.read(ratePlayerProvider.notifier).rate(
            rateeId: 'u2',
            gameId: 'g1',
            reliabilityScore: 5,
            behaviorScore: 5,
          );
      expect(ok, isTrue);

      final after = await c.read(pendingRatingsProvider.future);
      expect(
        after,
        isEmpty,
        reason:
            'After the last opponent is rated the queue should drain — this is '
            'what triggers auto-navigation in GameDetailScreen.',
      );
    });

    test('repository errors surface as RatePlayerState.error', () async {
      final repo = _FailingRepo();
      final c = _container(repo);
      addTearDown(c.dispose);

      final ok = await c.read(ratePlayerProvider.notifier).rate(
            rateeId: 'u2',
            gameId: 'g1',
            reliabilityScore: 4,
            behaviorScore: 4,
          );

      expect(ok, isFalse);
      final state = c.read(ratePlayerProvider);
      expect(state.success, isFalse);
      expect(state.error, contains('boom'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // dismissGameRatingQueue
  // ──────────────────────────────────────────────────────────────────────────

  group('dismissGameRatingQueue', () {
    testWidgets('hits the dismiss endpoint and invalidates the pending queue',
        (tester) async {
      final repo = _FakeRatingRepository(initial: [
        _item('g1', ['u2', 'u3']),
        _item('g2', ['u4']),
      ]);

      late WidgetRef capturedRef;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ratingRepositoryProvider.overrideWithValue(repo),
            gameDetailProvider.overrideWith(
              (ref, id) async => _unreachableGame(id),
            ),
            myGamesProvider.overrideWith((ref) async => <GameModel>[]),
            calendarGamesProvider.overrideWith((ref) async => <GameModel>[]),
          ],
          child: MaterialApp(
            home: Consumer(builder: (ctx, ref, _) {
              capturedRef = ref;
              return const SizedBox.shrink();
            }),
          ),
        ),
      );
      await tester.pump();

      // Warm pendingRatingsProvider so invalidation has measurable effect.
      final initial = await capturedRef.read(pendingRatingsProvider.future);
      expect(initial.map((e) => e.gameId), ['g1', 'g2']);
      expect(repo.getPendingCount, 1);

      await dismissGameRatingQueue(capturedRef, 'g1');

      expect(repo.dismissedGameIds, ['g1']);

      // The provider was invalidated → the next read must hit the repo
      // again, and g1 is gone.
      final after = await capturedRef.read(pendingRatingsProvider.future);
      expect(repo.getPendingCount, 2);
      expect(after.map((e) => e.gameId), ['g2']);
    });
  });
}

class _FailingRepo extends _FakeRatingRepository {
  @override
  Future<RatingModel> ratePlayer({
    required String rateeId,
    required String gameId,
    required int reliabilityScore,
    required int behaviorScore,
    String? comment,
    bool isAnonymous = false,
  }) async {
    throw Exception('boom');
  }
}
