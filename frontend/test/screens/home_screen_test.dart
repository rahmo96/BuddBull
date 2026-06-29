import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/home/presentation/home_screen.dart';
import 'package:buddbull/features/notifications/data/notification_model.dart';
import 'package:buddbull/features/notifications/data/notification_repository.dart';
import 'package:buddbull/features/notifications/providers/notification_provider.dart';
import 'package:buddbull/features/performance/data/models/performance_model.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/features/rating/data/models/rating_model.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/l10n_test_helpers.dart';
import '../helpers/test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  Future<void> pumpHome(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          calendarGamesProvider.overrideWith((ref) async => <GameModel>[]),
          myGamesProvider.overrideWith((ref) async => <GameModel>[]),
          exploreGamesProvider.overrideWith((ref) async => <GameModel>[]),
          pendingRatingsProvider
              .overrideWith((ref) async => <PendingRatingItem>[]),
          performanceStatsProvider.overrideWith((ref) async {
            return UserPerformanceStats.empty();
          }),
          performanceLogsProvider.overrideWith(
            (ref) async => <PerformanceLogModel>[],
          ),
          // Keep widget tests hermetic — the notifications notifier
          // refreshes on construction, so without this override it would
          // hit the real `ApiClient` over the network during pump.
          notificationRepositoryProvider
              .overrideWithValue(const _EmptyNotificationRepository()),
          // Don't pull in `SocketService` (and its FirebaseAuth.idTokenChanges
          // subscription) just to satisfy the notifier — feed it a null
          // live stream so it operates exclusively in HTTP mode.
          notificationLiveStreamProvider.overrideWithValue(null),
        ],
        child: wrapWithL10n(const HomeScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();
  }

  group('HomeScreen', () {
    testWidgets('should render pull-to-refresh scaffold without throwing',
        (tester) async {
      await pumpHome(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(RefreshIndicator), findsWidgets);
      expect(find.byType(CustomScrollView), findsOneWidget);
    });
  });
}

/// Stub repository that returns an empty inbox synchronously — keeps the
/// HomeScreen widget test off the network.
class _EmptyNotificationRepository implements NotificationRepository {
  const _EmptyNotificationRepository();

  @override
  Future<NotificationPage> getNotifications({int page = 1, int limit = 50}) async {
    return NotificationPage.empty;
  }

  @override
  Future<NotificationModel> markAsRead(String id) =>
      throw UnimplementedError();

  @override
  Future<int> markAllAsRead() async => 0;
}
