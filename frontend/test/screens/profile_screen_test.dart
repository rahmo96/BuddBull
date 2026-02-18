import 'package:buddbull/screens/main/profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../setup.dart';

void main() {
  group('ProfileScreen', () {
    testWidgets('renders profile header', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(authService: createMockAuthService()),
        ),
      );

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('User Profile'), findsOneWidget);
    });

    testWidgets('has settings menu button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(authService: createMockAuthService()),
        ),
      );

      expect(find.byIcon(Icons.menu_rounded), findsOneWidget);
    });

    testWidgets('opens settings bottom sheet when menu is tapped', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(authService: createMockAuthService()),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Settings & Activity'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog when Log Out is tapped',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(authService: createMockAuthService()),
        ),
      );

      await tester.tap(find.byIcon(Icons.menu_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Log Out'), findsWidgets);
      expect(find.text('Are you sure you want to log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('has avatar placeholder', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ProfileScreen(authService: createMockAuthService()),
        ),
      );

      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });
}
