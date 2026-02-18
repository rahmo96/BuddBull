import 'package:buddbull/screens/auth/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../setup.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('renders all main UI elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: createMockAuthService()),
        ),
      );

      expect(find.text('Login'), findsOneWidget);
      expect(find.text('New user? Register here'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.byType(FormBuilderTextField), findsNWidgets(2));
    });

    testWidgets('shows validation errors when form is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: createMockAuthService()),
        ),
      );

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Required'), findsWidgets);
    });

    testWidgets('shows invalid email error for bad email format', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: createMockAuthService()),
        ),
      );

      await tester.enterText(
        find.byType(FormBuilderTextField).first,
        'notanemail',
      );
      await tester.enterText(
        find.byType(FormBuilderTextField).last,
        'password123',
      );
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email'), findsOneWidget);
    });

    testWidgets('navigates to register when Register here is tapped',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: createMockAuthService()),
        ),
      );

      await tester.tap(find.text('New user? Register here'));
      await tester.pumpAndSettle();

      expect(find.text('Register & Create Profile'), findsOneWidget);
    });

    testWidgets('opens forgot password dialog when Forgot Password is tapped',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: LoginScreen(authService: createMockAuthService()),
        ),
      );

      await tester.tap(find.text('Forgot Password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Enter your email to receive a reset link:'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Send'), findsOneWidget);
    });
  });
}
