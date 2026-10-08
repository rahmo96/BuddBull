import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/presentation/screens/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/auth_router.dart';
import '../helpers/l10n_app.dart';
import '../helpers/test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  group('LoginScreen', () {
    Future<void> pumpLogin(
      WidgetTester tester, {
      Locale locale = const Locale('en'),
    }) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final router = authTestRouter();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: l10nRouterApp(router, locale: locale),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets(
        'should display validation hints when submitting an empty form',
        (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text(enL10n.authLoginButton));
      await tester.pumpAndSettle();

      expect(find.text(enL10n.validationFieldRequired), findsWidgets);
    });

    testWidgets(
        'should display invalid email message when email format is wrong',
        (tester) async {
      await pumpLogin(tester);

      await tester.enterText(
          textFieldBelowLabel(enL10n.authEmailLabel), 'not-an-email');
      await tester.enterText(
          textFieldBelowLabel(enL10n.authPasswordLabel), 'password123');
      await tester.tap(find.text(enL10n.authLoginButton));
      await tester.pumpAndSettle();

      expect(find.text(enL10n.validationInvalidEmail), findsOneWidget);
    });

    testWidgets('should navigate to register when Sign up is tapped',
        (tester) async {
      await pumpLogin(tester);

      final signUpFinder = find.text(enL10n.authSignUpLink);
      await tester.ensureVisible(signUpFinder);
      await tester.pumpAndSettle();
      await tester.tap(signUpFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text(enL10n.authRegisterSubtitle), findsOneWidget);
    });

    testWidgets('renders Hebrew copy and RTL when locale is he', (tester) async {
      await pumpLogin(tester, locale: const Locale('he'));

      expect(find.text(heL10n.authLoginButton), findsOneWidget);
      expect(find.text(heL10n.authWelcomeBack), findsOneWidget);
      final ctx = tester.element(find.text(heL10n.authLoginButton));
      expect(Directionality.of(ctx), TextDirection.rtl);

      await tester.tap(find.text(heL10n.authLoginButton));
      await tester.pumpAndSettle();
      expect(find.text(heL10n.validationFieldRequired), findsWidgets);
    });

    testWidgets(
        'should navigate to forgot password route when link is tapped',
        (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text(enL10n.authForgotPassword));
      await tester.pumpAndSettle();

      expect(find.text(enL10n.authResetPasswordTitle), findsOneWidget);
      expect(find.text(enL10n.authForgotSubtitle), findsOneWidget);
    });
  });
}
