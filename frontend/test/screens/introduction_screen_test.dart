import 'package:buddbull/screens/onboarding/introduction_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const initialPersonalInfo = {
    'firstName': 'John',
    'lastName': 'Doe',
    'email': 'john@example.com',
    'gender': 'male',
  };

  group('IntroductionScreen', () {
    testWidgets('renders profile completion form', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IntroductionScreen(
            initialEmail: 'john@example.com',
            initialUid: 'test-uid-123',
            initialPersonalInfo: initialPersonalInfo,
          ),
        ),
      );

      expect(find.text('Tell Us About Yourself'), findsOneWidget);
      expect(find.text('Complete Your Profile'), findsOneWidget);
      expect(find.text('Help us get to know you better'), findsOneWidget);
      expect(find.text('Birthday'), findsOneWidget);
      expect(find.text('Sports Interests'), findsOneWidget);
      expect(find.text('About Yourself'), findsOneWidget);
      expect(find.text('Complete Profile'), findsOneWidget);
    });

    testWidgets('shows validation error when form is empty', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IntroductionScreen(
            initialEmail: 'john@example.com',
            initialUid: 'test-uid-123',
            initialPersonalInfo: initialPersonalInfo,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Complete Profile'));
      await tester.tap(find.text('Complete Profile'));
      await tester.pumpAndSettle();

      final hasValidationError = find.text('Birthday is required').evaluate().isNotEmpty ||
          find.text('Select at least one sport').evaluate().isNotEmpty ||
          find.text('Required').evaluate().isNotEmpty ||
          find.text('At least 10 characters').evaluate().isNotEmpty;
      expect(hasValidationError, isTrue);
    });

    testWidgets('has date picker for birthday', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IntroductionScreen(
            initialEmail: 'john@example.com',
            initialUid: 'test-uid-123',
            initialPersonalInfo: initialPersonalInfo,
          ),
        ),
      );

      expect(find.text('Tap to select date'), findsWidgets);
    });

    testWidgets('has sports checkbox group', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: IntroductionScreen(
            initialEmail: 'john@example.com',
            initialUid: 'test-uid-123',
            initialPersonalInfo: initialPersonalInfo,
          ),
        ),
      );

      await tester.ensureVisible(find.text('Sports Interests'));
      expect(find.text('Sports Interests'), findsOneWidget);

      await tester.ensureVisible(find.text('Football'));
      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Basketball'), findsOneWidget);
    });
  });
}
