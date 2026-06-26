import 'package:buddbull/features/home/presentation/widgets/collapsing_home_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 400,
          height: 220,
          child: child,
        ),
      ),
    );
  }

  group('CollapsingHomeSearch', () {
    testWidgets('shows hint text when fully expanded', (tester) async {
      await tester.pumpWidget(
        wrap(
          CollapsingHomeSearch(
            expandRatio: 1.0,
            onTap: (_) {},
          ),
        ),
      );

      expect(find.text('Search games, players…'), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('hides hint text when fully collapsed', (tester) async {
      await tester.pumpWidget(
        wrap(
          CollapsingHomeSearch(
            expandRatio: 0.0,
            onTap: (_) {},
          ),
        ),
      );

      expect(find.text('Search games, players…'), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('invokes onTap when pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          CollapsingHomeSearch(
            expandRatio: 1.0,
            onTap: (_) => tapped = true,
          ),
        ),
      );

      await tester.tap(find.byIcon(Icons.search_rounded));
      await tester.pump();
      expect(tapped, isTrue);
    });
  });
}
