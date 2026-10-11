import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('Hebrew locale yields RTL and Hebrew dates; switching back updates both',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);

    TextDirection? dir;
    String? date;

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: Consumer(
          builder: (context, ref, _) {
            final locale = ref.watch(localeProvider) ?? const Locale('en');
            return MaterialApp(
              locale: locale,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              builder: (context, child) {
                Intl.defaultLocale = Localizations.localeOf(context).languageCode;
                return child!;
              },
              home: Builder(
                builder: (context) {
                  dir = Directionality.of(context);
                  // Call sites with a context pass the locale explicitly.
                  date = DateFormat('EEEE', context.l10n.localeName)
                      .format(DateTime(2026, 10, 7));
                  return const SizedBox();
                },
              ),
            );
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(dir, TextDirection.ltr);
    expect(date, 'Wednesday');

    await container.read(localeProvider.notifier).setLocale(const Locale('he'));
    await tester.pumpAndSettle();
    expect(dir, TextDirection.rtl);
    expect(date, 'יום רביעי');
    expect(Intl.defaultLocale, 'he');

    await container.read(localeProvider.notifier).setLocale(const Locale('en'));
    await tester.pumpAndSettle();
    expect(dir, TextDirection.ltr);
    expect(date, 'Wednesday');
  });
}
