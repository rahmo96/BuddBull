import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/presentation/screens/login_screen.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
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

  Future<void> pumpRegister(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final router = authTestRouter(initialLocation: Routes.register);
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

  Future<void> fillValidRegistrationForm(WidgetTester tester) async {
    final l10n = enL10n();
    await tester.enterText(
        textFieldBelowLabel(l10n.firstNameLabel), 'Alex');
    await tester.enterText(
        textFieldBelowLabel(l10n.lastNameLabel), 'Rivera');
    await tester.enterText(
        textFieldBelowLabel(l10n.usernameLabel), 'alexriver');
    await tester.enterText(
        textFieldBelowLabel(l10n.emailLabel), 'alex@example.com');
    await tester.enterText(
        textFieldBelowLabel(l10n.passwordLabel), 'password01');
    await tester.enterText(
        textFieldBelowLabel(l10n.confirmPasswordLabel), 'password01');
  }

  Finder createAccountBbButtonFinder() {
    final label = enL10n().registerButton;
    return find.byWidgetPredicate(
      (w) => w is BbButton && (w.label == label),
    );
  }

  group('RegisterScreen', () {
    testWidgets('should surface required field validators on empty submit',
        (tester) async {
      await pumpRegister(tester);

      await tester.ensureVisible(createAccountBbButtonFinder());
      await tester.tap(createAccountBbButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text(enL10n().fieldRequired), findsWidgets);
    });

    testWidgets(
        'should show snackbar when terms are not accepted despite valid inputs',
        (tester) async {
      await pumpRegister(tester);
      await fillValidRegistrationForm(tester);

      await tester.ensureVisible(createAccountBbButtonFinder());
      await tester.tap(createAccountBbButtonFinder());
      await tester.pumpAndSettle();

      expect(find.text(enL10n().acceptTerms), findsOneWidget);
    });

    testWidgets('should expose sign-in shortcut back to login', (tester) async {
      await pumpRegister(tester);
      final l10n = enL10n();

      await tester.ensureVisible(find.text(l10n.signInLink));
      await tester.tap(find.text(l10n.signInLink));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.text(l10n.loginButton), findsOneWidget);
    });
  });
}
