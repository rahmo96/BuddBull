import 'package:buddbull/screens/main/home.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('HomeScreen smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(home: HomeScreen()));

    expect(find.text('BudBull'), findsOneWidget);
    expect(find.text('Home Feed (Coming Soon)'), findsOneWidget);
  });
}
