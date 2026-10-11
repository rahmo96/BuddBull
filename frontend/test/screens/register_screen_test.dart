import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/presentation/screens/login_screen.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
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

  Future<void> pumpRegister(
    WidgetTester tester, {
    Locale locale = const Locale('en'),
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = authTestRouter(initialLocation: Routes.register);
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

  Future<void> fillValidRegistrationForm(WidgetTester tester) async {
    await tester.enterText(
        textFieldBelowLabel(enL10n.authFirstNameLabel), 'Alex');
    await tester.enterText(
        textFieldBelowLabel(enL10n.authLastNameLabel), 'Rivera');
    await tester.enterText(
        textFieldBelowLabel(enL10n.authUsernameLabel), 'alexriver');
    await tester.enterText(
        textFieldBelowLabel(enL10n.authEmailLabel), 'alex@example.com');
    await tester.enterText(
        textFieldBelowLabel(enL10n.authPasswordLabel), 'password01');
    await tester.enterText(
        textFieldBelowLabel(enL10n.authConfirmPasswordLabel), 'password01');
  }

  Finder createAccountBbButtonFinder() {
    return find.byWidgetPredicate(
      (w) =>
          w is BbButton && (w.label == enL10n.authRegisterButton),
    );
  }

  group('RegisterScreen', () {
    testWidgets('should surface required field validators on empty submit',
        (tester) async {
      await pumpRegister(tester);

      await tester.ensureVisible(createAccountBbButtonFinder());
      await tester.tap(createAccountBbButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text(enL10n.validationFieldRequired), findsWidgets);
    });

    testWidgets(
        'should show snackbar when terms are not accepted despite valid inputs',
        (tester) async {
      await pumpRegister(tester);
      await fillValidRegistrationForm(tester);

      await tester.ensureVisible(createAccountBbButtonFinder());
      await tester.tap(createAccountBbButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text(enL10n.validationAcceptTerms), findsOneWidget);
    });

    testWidgets('renders Hebrew copy and RTL when locale is he', (tester) async {
      await pumpRegister(tester, locale: const Locale('he'));

      expect(find.text(heL10n.authRegisterSubtitle), findsOneWidget);
      final ctx = tester.element(find.text(heL10n.authRegisterSubtitle));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });

    testWidgets('should expose sign-in shortcut back to login', (tester) async {
      await pumpRegister(tester);

      await tester.ensureVisible(find.text(enL10n.authSignInLink));
      await tester.tap(find.text(enL10n.authSignInLink));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(enL10n.authLoginButton), findsOneWidget);
    });
  });
}
