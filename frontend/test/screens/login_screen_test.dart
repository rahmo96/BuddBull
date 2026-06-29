import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/auth_router.dart';
import '../helpers/l10n_test_helpers.dart';
import '../helpers/test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('LoginScreen', () {
    Future<void> pumpLogin(WidgetTester tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = authTestRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: authTestApp(router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets(
        'should display validation hints when submitting an empty form',
        (tester) async {
      await pumpLogin(tester);
      final l10n = enL10n();

      await tester.tap(find.text(l10n.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.fieldRequired), findsWidgets);
    });

    testWidgets(
        'should display invalid email message when email format is wrong',
        (tester) async {
      await pumpLogin(tester);
      final l10n = enL10n();

      await tester.enterText(
          textFieldBelowLabel(l10n.emailLabel), 'not-an-email');
      await tester.enterText(
          textFieldBelowLabel(l10n.passwordLabel), 'password123');
      await tester.tap(find.text(l10n.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(l10n.invalidEmail), findsOneWidget);
    });

    testWidgets('should navigate to register when Sign up is tapped',
        (tester) async {
      await pumpLogin(tester);
      final l10n = enL10n();

      final signUpFinder = find.text(l10n.signUpLink);
      await tester.ensureVisible(signUpFinder);
      await tester.pumpAndSettle();
      await tester.tap(signUpFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text(l10n.registerSubtitle), findsOneWidget);
    });

    testWidgets(
        'should navigate to forgot password route when link is tapped',
        (tester) async {
      await pumpLogin(tester);
      final l10n = enL10n();

      await tester.tap(find.text(l10n.forgotPassword));
      await tester.pumpAndSettle();

      expect(find.text(l10n.resetPassword), findsOneWidget);
      expect(find.text(l10n.forgotSubtitle), findsOneWidget);
    });
  });
}
