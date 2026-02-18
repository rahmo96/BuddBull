import 'package:buddbull/screens/auth/register_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import '../setup.dart';

void main() {
  group('RegisterScreen', () {
    testWidgets('renders all main sections', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(authService: createMockAuthService()),
        ),
      );

      expect(find.text('Account Details'), findsOneWidget);
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Register & Create Profile'), findsOneWidget);
    });

    testWidgets('renders all form fields', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(authService: createMockAuthService()),
        ),
      );

      expect(find.text('Email'), findsWidgets);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('First Name'), findsOneWidget);
      expect(find.text('Last Name'), findsOneWidget);
      expect(find.text('Gender'), findsOneWidget);
    });

    testWidgets('shows validation errors when form is empty', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(authService: createMockAuthService()),
        ),
      );

      await tester.ensureVisible(find.text('Register & Create Profile'));
      await tester.tap(find.text('Register & Create Profile'));
      await tester.pumpAndSettle();

      // FormBuilderValidators show various required messages
      final hasValidationError = find.text('This field is required').evaluate().isNotEmpty ||
          find.text('First name is required').evaluate().isNotEmpty ||
          find.text('Last name is required').evaluate().isNotEmpty ||
          find.text('Gender is required').evaluate().isNotEmpty;
      expect(hasValidationError, isTrue);
    });

    testWidgets('gender dropdown has expected options', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: RegisterScreen(authService: createMockAuthService()),
        ),
      );

      await tester.ensureVisible(find.byType(FormBuilderDropdown<String>));
      await tester.tap(find.byType(FormBuilderDropdown<String>));
      await tester.pumpAndSettle();

      expect(find.text('Male'), findsOneWidget);
      expect(find.text('Female'), findsOneWidget);
      expect(find.text('Other'), findsOneWidget);
    });
  });
}
