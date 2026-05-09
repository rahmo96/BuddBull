import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/home/presentation/home_screen.dart';
import 'package:buddbull/features/performance/data/models/performance_model.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
          performanceStatsProvider.overrideWith((ref) async {
            return UserPerformanceStats.empty();
          }),
          performanceLogsProvider.overrideWith(
            (ref) async => <PerformanceLogModel>[],
          ),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
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
