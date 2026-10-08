import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import '../../helpers/l10n_app.dart';

void main() {
  testWidgets('context-aware date formatting follows the active locale',
      (tester) async {
    String? out;
    Future<void> pump(Locale l) async {
      await tester.pumpWidget(
        l10nMaterialApp(
          locale: l,
          home: Builder(builder: (context) {
            out = DateFormat('EEE, d MMM y', context.l10n.localeName)
                .format(DateTime(2026, 10, 7));
            return const SizedBox();
          }),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pump(const Locale('en'));
    expect(out, 'Wed, 7 Oct 2026');
    await pump(const Locale('he'));
    expect(out, contains('אוק'));
  });

  test('games count reads correctly for 0/1/2/many in Hebrew', () {
    expect(heL10n.gamesCount(0), 'אין משחקים');
    expect(heL10n.gamesCount(1), 'משחק אחד');
    expect(heL10n.gamesCount(2), 'שני משחקים');
    expect(heL10n.gamesCount(7), '7 משחקים');
    expect(enL10n.gamesCount(1), '1 game');
    expect(enL10n.gamesCount(3), '3 games');
  });
}
