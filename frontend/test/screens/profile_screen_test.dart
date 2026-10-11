import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/profile/presentation/screens/profile_screen.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/l10n_app.dart';
import '../helpers/test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('ProfileScreen', () {
    testWidgets(
        'should show loading fallback while profile auth data is hydrating',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: l10nMaterialApp(home: const ProfileScreen()),
        ),
      );

      await tester.pump();
      expect(find.byType(BbLoadingIndicator), findsWidgets);
      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('loaded profile shows the Language tile in Hebrew and RTL',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      tester.view.physicalSize = const Size(400 * 3, 1200 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            authProvider.overrideWith((ref) => _FakeAuthNotifier()),
          ],
          child: l10nMaterialApp(
            locale: const Locale('he'),
            home: const ProfileScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text(heL10n.languageTitle), findsOneWidget);
      expect(
        Directionality.of(tester.element(find.text(heL10n.languageTitle))),
        TextDirection.rtl,
      );
    });
  });
}

/// Auth notifier pinned to an authenticated user; never touches Firebase.
class _FakeAuthNotifier extends StateNotifier<AuthState>
    implements AuthNotifier {
  _FakeAuthNotifier()
      : super(
          const AuthState(
            status: AuthStatus.authenticated,
            user: UserModel(
              id: 'u1',
              firstName: 'Dana',
              lastName: 'Levi',
              username: 'dana',
              email: 'dana@example.com',
              role: 'player',
            ),
          ),
        );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
