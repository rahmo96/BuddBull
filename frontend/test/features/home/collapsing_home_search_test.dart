import 'package:buddbull/features/home/presentation/widgets/collapsing_home_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  group('CollapsingHomeSearch', () {
    testWidgets('shows hint text when fully expanded', (tester) async {
      final l10n = enL10n();
      await tester.pumpWidget(
        wrapWithL10n(
          CollapsingHomeSearch(
            expandRatio: 1.0,
            onTap: (_) {},
          ),
        ),
      );

      expect(find.text(l10n.searchGamesPlayersHint), findsOneWidget);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('hides hint text when fully collapsed', (tester) async {
      await tester.pumpWidget(
        wrapWithL10n(
          CollapsingHomeSearch(
            expandRatio: 0.0,
            onTap: (_) {},
          ),
        ),
      );

      expect(find.text(enL10n().searchGamesPlayersHint), findsNothing);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
    });

    testWidgets('invokes onTap when pressed', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrapWithL10n(
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
