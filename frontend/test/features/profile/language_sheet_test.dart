import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/profile/presentation/widgets/language_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../helpers/l10n_app.dart';

void main() {
  testWidgets('choosing עברית persists Hebrew; Device default clears it', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: l10nMaterialApp(
          home: const Scaffold(body: LanguageTile()),
        ),
      ),
    );

    await tester.tap(find.text(enL10n.languageTitle));
    await tester.pumpAndSettle();
    expect(find.text(enL10n.languageDeviceDefault), findsNWidgets(2)); // tile subtitle + sheet option
    expect(find.text('English'), findsWidgets);

    await tester.tap(find.text('עברית'));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), const Locale('he'));
    expect(prefs.getString(kAppLocalePrefKey), 'he');

    await tester.tap(find.text(enL10n.languageTitle));
    await tester.pumpAndSettle();
    await tester.tap(find.text(enL10n.languageDeviceDefault));
    await tester.pumpAndSettle();
    expect(container.read(localeProvider), isNull);
    expect(prefs.containsKey(kAppLocalePrefKey), isFalse);
  });
}
