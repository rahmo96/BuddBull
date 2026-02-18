import 'package:buddbull/screens/layout/main_layout.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MainLayout', () {
    testWidgets('renders bottom navigation with all tabs', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Find'), findsOneWidget);
      expect(find.text('Stats'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('shows Home screen by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(),
        ),
      );

      expect(find.text('BudBull'), findsOneWidget);
      expect(find.text('Home Feed (Coming Soon)'), findsOneWidget);
    });

    testWidgets('shows Profile when Profile tab is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(),
        ),
      );

      await tester.tap(find.text('Profile'));
      await tester.pumpAndSettle();

      expect(find.text('My Profile'), findsOneWidget);
      expect(find.text('User Profile'), findsOneWidget);
    });

    testWidgets('shows Find when Find tab is tapped', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(),
        ),
      );

      await tester.tap(find.text('Find'));
      await tester.pumpAndSettle();

      expect(find.text('Find'), findsWidgets);
    });

    testWidgets('has floating action button', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: MainLayout(),
        ),
      );

      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsWidgets);
    });
  });
}
