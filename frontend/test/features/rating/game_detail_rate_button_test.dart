// Widget tests for [GameDetailScreen]'s rating affordances.
//
// Three things matter and are each pinned by a test:
//
//  1. **Visibility** — an approved viewer on a completed game sees a
//     primary "Rate Participants" button. An in_progress game shows
//     "Leave Game" instead. A kicked / unapproved viewer sees neither.
//
//  2. **Status transition** — when the game's status flips from
//     `in_progress` to `completed` (e.g. the organiser hits "Complete"
//     while we're parked on the detail screen), the bottom bar's
//     primary action swaps from "Leave Game" to "Rate Participants"
//     within the same widget lifecycle.
//
//  3. **Auto-navigation** — once the pending-rating queue for this game
//     drains (the user submits or dismisses the last rating), the
//     screen pops back to the previous route after the 500ms grace
//     delay.
//
// We stand up isolated `ProviderScope`s with overrides instead of
// hitting real repositories. The `currentUserProvider` indirection in
// `auth_provider.dart` exists specifically so we can pin a `UserModel`
// here without booting the full `AuthNotifier` + FirebaseAuth listener.

import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/screens/game_detail_screen.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/rating/data/models/rating_model.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/test_bootstrap.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────────────

const _gameId = 'game-abc';
const _viewerId = 'viewer-1';
const _organizerId = 'org-1';
const _otherPlayerId = 'other-1';

UserModel _viewer({String role = 'player'}) => UserModel(
      id: _viewerId,
      firstName: 'Vivi',
      lastName: 'Viewer',
      username: 'vivi',
      email: 'vivi@example.com',
      role: role,
    );

GameModel _buildGame({
  required String status,
  String viewerStatus = 'approved',
}) {
  return GameModel(
    id: _gameId,
    title: 'Sunday Football',
    sport: 'football',
    organizer: const GameOrganizer(
      id: _organizerId,
      username: 'orgy',
      firstName: 'Or',
      lastName: 'Ganizer',
    ),
    scheduledAt: DateTime(2026, 5, 13, 18),
    durationMinutes: 90,
    location: const GameLocation(
      city: 'London',
      neighborhood: 'Notting Hill',
      formattedAddress: 'Notting Hill, London W11, UK',
    ),
    maxPlayers: 10,
    requiredSkillLevel: 'any',
    status: status,
    players: [
      const GamePlayer(
        userId: _organizerId,
        username: 'orgy',
        status: 'approved',
        firstName: 'Or',
        lastName: 'Ganizer',
      ),
      GamePlayer(
        userId: _viewerId,
        username: 'vivi',
        status: viewerStatus,
        firstName: 'Vivi',
        lastName: 'Viewer',
      ),
      const GamePlayer(
        userId: _otherPlayerId,
        username: 'other',
        status: 'approved',
        firstName: 'Ozzy',
        lastName: 'Other',
      ),
    ],
  );
}

PendingRatingItem _pendingItem() => const PendingRatingItem(
      gameId: _gameId,
      gameTitle: 'Sunday Football',
      gameSport: 'football',
      pendingPlayers: [
        {
          '_id': _organizerId,
          'firstName': 'Or',
          'lastName': 'Ganizer',
          'username': 'orgy',
        },
        {
          '_id': _otherPlayerId,
          'firstName': 'Ozzy',
          'lastName': 'Other',
          'username': 'other',
        },
      ],
    );

// ─────────────────────────────────────────────────────────────────────────────
// Pump helpers
// ─────────────────────────────────────────────────────────────────────────────

/// Convenience finder that ignores hit-testability / overflow concerns —
/// the bottom bar can be momentarily off-screen during async loads and
/// `find.text` matches both visible and hidden Text widgets.
Finder _bbButtonWithLabel(String label) =>
    find.widgetWithText(BbButton, label);

Finder _rateButton() => _bbButtonWithLabel(enL10n().buttonRateParticipants);
Finder _leaveButton() => _bbButtonWithLabel(enL10n().buttonLeaveGame);

Future<SharedPreferences> _prefs() async {
  SharedPreferences.setMockInitialValues({});
  return SharedPreferences.getInstance();
}

/// Pumps the GameDetailScreen directly. Useful for the simple visibility
/// scenarios that never exercise navigation.
Future<void> _pumpDetail(
  WidgetTester tester, {
  required GameModel game,
  required List<PendingRatingItem> pending,
  UserModel? viewer,
}) async {
  final prefs = await _prefs();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(viewer ?? _viewer()),
        gameDetailProvider.overrideWith((ref, _) async => game),
        pendingRatingsProvider.overrideWith((ref) async => pending),
      ],
      child: wrapWithL10n(const GameDetailScreen(gameId: _gameId)),
    ),
  );
  // Two pumps: first resolves the FutureProvider, second runs the
  // post-frame callback that may invalidate pendingRatingsProvider.
  await tester.pump();
  await tester.pump();
}

/// Builds a minimal GoRouter with two routes: a sentinel host page and
/// the GameDetailScreen we're testing. The screen pops via go_router's
/// `context.pop()` / `context.canPop()`, so we MUST mount a real GoRouter
/// for those extensions to resolve — a plain `Navigator.push` would
/// throw "No GoRouter found in context".
GoRouter _testRouter() => GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Center(child: Text('host-sentinel')),
          ),
        ),
        GoRoute(
          path: '/games/:id',
          builder: (_, state) =>
              GameDetailScreen(gameId: state.pathParameters['id']!),
        ),
      ],
    );

/// Pumps GameDetailScreen *as a pushed route* over a sentinel host page
/// so `context.canPop()` returns true and the auto-pop assertion can
/// observe the screen leaving the stack.
Future<GoRouter> _pumpDetailOverRoute(
  WidgetTester tester, {
  required ProviderContainer container,
}) async {
  final router = _testRouter();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    ),
  );
  await tester.pumpAndSettle();
  // Push (not go) preserves the host route on the stack so canPop() is
  // true once the GameDetailScreen mounts.
  router.push('/games/$_gameId');
  await tester.pump();
  await tester.pump();
  return router;
}

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('GameDetailScreen — bottom action button visibility', () {
    testWidgets('approved viewer on a completed game shows "Rate Participants"',
        (tester) async {
      await _pumpDetail(
        tester,
        game: _buildGame(status: 'completed'),
        pending: [_pendingItem()],
      );

      expect(_rateButton(), findsOneWidget);
      expect(_leaveButton(), findsNothing);
    });

    testWidgets('approved viewer on an in_progress game shows "Leave Game"',
        (tester) async {
      await _pumpDetail(
        tester,
        game: _buildGame(status: 'in_progress'),
        pending: const [],
      );

      // While the game is still in progress there's nothing to rate.
      expect(_leaveButton(), findsOneWidget);
      expect(_rateButton(), findsNothing);
    });

    testWidgets(
        'completed game with empty pending queue still shows "Rate Participants" '
        '— the picker handles the empty edge case',
        (tester) async {
      // This guards against a regression where the screen relied solely on
      // `pendingRatingsProvider` having items to render the rate CTA.
      // Reality: the queue can be empty momentarily (cached pre-completion)
      // and we still want the button visible.
      await _pumpDetail(
        tester,
        game: _buildGame(status: 'completed'),
        pending: const [],
      );

      expect(_rateButton(), findsOneWidget);
    });

    testWidgets('a kicked viewer sees no rate / leave affordance',
        (tester) async {
      await _pumpDetail(
        tester,
        game: _buildGame(status: 'completed', viewerStatus: 'kicked'),
        pending: const [],
      );

      expect(_rateButton(), findsNothing);
      expect(_leaveButton(), findsNothing);
    });
  });

  group('GameDetailScreen — bottom button transitions on status change', () {
    testWidgets(
        'flipping the game status from in_progress to completed swaps '
        '"Leave Game" for "Rate Participants"',
        (tester) async {
      // A driving StateProvider lets us mutate the game mid-test; the
      // overridden gameDetailProvider watches it, so any change rebuilds
      // the screen end-to-end.
      final gameDriver = StateProvider<GameModel>(
        (ref) => _buildGame(status: 'in_progress'),
      );

      final prefs = await _prefs();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            currentUserProvider.overrideWithValue(_viewer()),
            gameDetailProvider.overrideWith(
              (ref, _) async => ref.watch(gameDriver),
            ),
            pendingRatingsProvider.overrideWith((ref) async => const []),
          ],
          child: wrapWithL10n(const GameDetailScreen(gameId: _gameId)),
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        _leaveButton(),
        findsOneWidget,
        reason: 'In-progress games must offer leave button',
      );
      expect(_rateButton(), findsNothing);

      // Organiser hits "Complete" — push the new state through the driver.
      final element = tester.element(find.byType(GameDetailScreen));
      final container = ProviderScope.containerOf(element);
      container.read(gameDriver.notifier).state =
          _buildGame(status: 'completed');

      // First pump processes the gameDetailProvider re-fetch + initial
      // post-frame callback. Second pump processes the listener-driven
      // ref.invalidate(pendingRatingsProvider) and the resulting rebuild.
      await tester.pump();
      await tester.pump();

      expect(
        _rateButton(),
        findsOneWidget,
        reason:
            'Once the game completes, every approved player must see rate '
            'participants — including non-organisers — regardless of the '
            'pending-rating provider state.',
      );
      expect(_leaveButton(), findsNothing);
    });
  });

  group('GameDetailScreen — auto-navigation on empty pending queue', () {
    testWidgets(
        'completed game whose pending queue drains pops the detail screen '
        'back to the host route',
        (tester) async {
      // A driving StateProvider toggles the pending queue from "has work"
      // to "drained". The override watches it, so flipping it rebuilds
      // the FutureProvider and the screen's ref.listen observes the
      // empty state — which (after the 500ms grace delay) triggers pop.
      final hasPending = StateProvider<bool>((ref) => true);

      final prefs = await _prefs();
      final overrides = <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(_viewer()),
        gameDetailProvider.overrideWith(
          (ref, _) async => _buildGame(status: 'completed'),
        ),
        pendingRatingsProvider.overrideWith((ref) async {
          return ref.watch(hasPending) ? [_pendingItem()] : const [];
        }),
      ];
      final container = ProviderContainer(overrides: overrides);
      addTearDown(container.dispose);

      await _pumpDetailOverRoute(tester, container: container);

      // Sanity check: we landed on the detail screen with the rate CTA,
      // and the host route is hidden behind it.
      expect(find.byType(GameDetailScreen), findsOneWidget);
      expect(_rateButton(), findsOneWidget);

      // Drain the queue. The override now resolves to `[]`; the
      // FutureProvider re-runs; the listener inside GameDetailScreen
      // fires with AsyncData([]) — but only AFTER it has previously seen
      // a populated queue, which it did on initial load.
      container.read(hasPending.notifier).state = false;

      // First pump processes the provider rebuild + listener call. The
      // listener schedules `Future.delayed(500ms, pop)` — advance time
      // past it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(
        find.byType(GameDetailScreen),
        findsNothing,
        reason:
            'After the pending queue drains on a completed game, the screen '
            'must pop back to the host route automatically.',
      );
      expect(find.text('host-sentinel'), findsOneWidget);
    });

    testWidgets(
        'landing on a completed game with an already-empty queue does NOT '
        'auto-pop',
        (tester) async {
      // Guards against the regression where _hadPendingRatings == false on
      // arrival was treated as "drained" and the user got bounced
      // immediately. The screen must only auto-pop when a non-empty queue
      // we previously observed becomes empty.
      final prefs = await _prefs();
      final container = ProviderContainer(overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        currentUserProvider.overrideWithValue(_viewer()),
        gameDetailProvider.overrideWith(
          (ref, _) async => _buildGame(status: 'completed'),
        ),
        pendingRatingsProvider.overrideWith((ref) async => const []),
      ]);
      addTearDown(container.dispose);

      await _pumpDetailOverRoute(tester, container: container);

      // Advance well past the 500ms grace window.
      await tester.pump(const Duration(seconds: 1));
      await tester.pumpAndSettle();

      expect(
        find.byType(GameDetailScreen),
        findsOneWidget,
        reason:
            'Arriving on a completed game that was already fully rated must '
            'not bounce the user — only an observed drain should pop.',
      );
    });
  });
}
