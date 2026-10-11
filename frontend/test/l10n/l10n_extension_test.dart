import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('context.l10n resolves English and Hebrew strings', (tester) async {
    late String en;
    late String he;

    Future<void> pumpWith(Locale locale, void Function(String) sink) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) {
              sink(context.l10n.languageTitle);
              return const SizedBox();
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    await pumpWith(const Locale('en'), (s) => en = s);
    await pumpWith(const Locale('he'), (s) => he = s);

    expect(en, 'Language');
    expect(he, 'שפה');
  });
}
