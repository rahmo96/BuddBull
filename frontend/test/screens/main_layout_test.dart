import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/l10n_test_helpers.dart';
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

Widget _shellTestApp(GoRouter router) {
  return MaterialApp.router(
    localizationsDelegates: const [
      AppLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    routerConfig: router,
  );
}

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('HomeShell (dynamic island navigation)', () {
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
          child: _shellTestApp(router),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('starts on home tab probe', (tester) async {
      await pumpShell(tester);
      final l10n = enL10n();
      expect(find.text('PROBE_HOME'), findsOneWidget);
      expect(find.text(l10n.navHome), findsWidgets);
      expect(find.text(l10n.navProfile), findsWidgets);
    });

    testWidgets('selecting Profile swaps to profile probe widget', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text(enL10n().navProfile));
      await tester.pumpAndSettle();

      expect(find.text('PROBE_PROFILE'), findsOneWidget);
    });

    testWidgets('selecting Games swaps to games probe widget', (tester) async {
      await pumpShell(tester);

      await tester.tap(find.text(enL10n().navGames));
      await tester.pumpAndSettle();

      expect(find.text('PROBE_GAMES'), findsOneWidget);
    });
  });
}
