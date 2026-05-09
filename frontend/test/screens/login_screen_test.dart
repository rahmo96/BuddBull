import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/presentation/screens/register_screen.dart';
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
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }

    testWidgets(
        'should display validation hints when submitting an empty form',
        (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.fieldRequired), findsWidgets);
    });

    testWidgets(
        'should display invalid email message when email format is wrong',
        (tester) async {
      await pumpLogin(tester);

      await tester.enterText(
          textFieldBelowLabel(AppStrings.emailLabel), 'not-an-email');
      await tester.enterText(
          textFieldBelowLabel(AppStrings.passwordLabel), 'password123');
      await tester.tap(find.text(AppStrings.loginButton));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.invalidEmail), findsOneWidget);
    });

    testWidgets('should navigate to register when Sign up is tapped',
        (tester) async {
      await pumpLogin(tester);

      final signUpFinder = find.text(AppStrings.signUpLink);
      await tester.ensureVisible(signUpFinder);
      await tester.pumpAndSettle();
      await tester.tap(signUpFinder);
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
      expect(find.text(AppStrings.registerSubtitle), findsOneWidget);
    });

    testWidgets(
        'should navigate to forgot password route when link is tapped',
        (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text(AppStrings.forgotPassword));
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.resetPassword), findsOneWidget);
      expect(find.text(AppStrings.forgotSubtitle), findsOneWidget);
    });
  });
}
