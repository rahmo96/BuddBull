import 'package:buddbull/screens/main/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('HomeScreen', () {
    testWidgets('renders app bar with BudBull title', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('BudBull'), findsOneWidget);
    });

    testWidgets('shows Home Feed placeholder', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.text('Home Feed (Coming Soon)'), findsOneWidget);
    });

    testWidgets('has centered content', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomeScreen(),
        ),
      );

      expect(find.byType(Center), findsWidgets);
    });
  });
}
