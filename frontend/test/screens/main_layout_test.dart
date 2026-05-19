import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/shell_test_overrides.dart';
import '../helpers/test_bootstrap.dart';

class _ProbePage extends StatelessWidget {
  const _ProbePage({required this.marker});

  final String marker;

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Center(child: Text(marker)));
  }
}

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('HomeShell (bottom navigation)', () {
    Future<void> pumpShell(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = GoRouter(
        initialLocation: Routes.home,
        routes: [
          ShellRoute(
            builder: (_, __, child) => HomeScaffold(child: child),
            routes: [
              GoRoute(
                path: Routes.home,
                builder: (_, __) => const _ProbePage(marker: 'PROBE_HOME'),
              ),
              GoRoute(
                path: Routes.games,
                builder: (_, __) => const _ProbePage(marker: 'PROBE_GAMES'),
              ),
              GoRoute(
                path: Routes.chats,
                builder: (_, __) => const _ProbePage(marker: 'PROBE_MESSAGES'),
              ),
              GoRoute(
                path: Routes.performance,
                builder: (_, __) => const _ProbePage(marker: 'PROBE_PERFORMANCE'),
              ),
              GoRoute(
                path: Routes.profile,
                builder: (_, __) => const _ProbePage(marker: 'PROBE_PROFILE'),
              ),
            ],
          ),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            ...shellTestOverrides(),
          ],
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('starts on home tab probe', (tester) async {
      await pumpShell(tester);
      expect(find.text('PROBE_HOME'), findsOneWidget);
      expect(find.text(AppStrings.navHome), findsWidgets);
      expect(find.text(AppStrings.navProfile), findsWidgets);
    });

    testWidgets('selecting Profile swaps to profile probe widget', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text(AppStrings.navProfile));
      await tester.pumpAndSettle();

      expect(find.text('PROBE_PROFILE'), findsOneWidget);
    });

    testWidgets('selecting Games swaps to games probe widget', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text(AppStrings.navGames));
      await tester.pumpAndSettle();

      expect(find.text('PROBE_GAMES'), findsOneWidget);
    });
  });
}
