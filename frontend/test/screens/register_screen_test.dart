import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/presentation/screens/login_screen.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/auth_router.dart';
import '../helpers/test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await initTestFirebaseAndBinding();
  });

  Future<void> pumpRegister(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = authTestRouter(initialLocation: Routes.register);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
  }

  Future<void> fillValidRegistrationForm(WidgetTester tester) async {
    await tester.enterText(
        textFieldBelowLabel(AppStrings.firstNameLabel), 'Alex');
    await tester.enterText(
        textFieldBelowLabel(AppStrings.lastNameLabel), 'Rivera');
    await tester.enterText(
        textFieldBelowLabel(AppStrings.usernameLabel), 'alexriver');
    await tester.enterText(
        textFieldBelowLabel(AppStrings.emailLabel), 'alex@example.com');
    await tester.enterText(
        textFieldBelowLabel(AppStrings.passwordLabel), 'password01');
    await tester.enterText(
        textFieldBelowLabel(AppStrings.confirmPasswordLabel), 'password01');
  }

  Finder createAccountBbButtonFinder() {
    return find.byWidgetPredicate(
      (w) =>
          w is BbButton && (w.label == AppStrings.registerButton),
    );
  }

  group('RegisterScreen', () {
    testWidgets('should surface required field validators on empty submit',
        (tester) async {
      await pumpRegister(tester);

      await tester.ensureVisible(createAccountBbButtonFinder());
      await tester.tap(createAccountBbButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.fieldRequired), findsWidgets);
    });

    testWidgets(
        'should show snackbar when terms are not accepted despite valid inputs',
        (tester) async {
      await pumpRegister(tester);
      await fillValidRegistrationForm(tester);

      await tester.ensureVisible(createAccountBbButtonFinder());
      await tester.tap(createAccountBbButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.acceptTerms), findsOneWidget);
    });

    testWidgets('should expose sign-in shortcut back to login', (tester) async {
      await pumpRegister(tester);

      await tester.ensureVisible(find.text(AppStrings.signInLink));
      await tester.tap(find.text(AppStrings.signInLink));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(AppStrings.loginButton), findsOneWidget);
    });
  });
}
