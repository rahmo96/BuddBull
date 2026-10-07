import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProviderContainer> _container(Map<String, Object> initial) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  addTearDown(container.dispose);
  return container;
}

void main() {
  group('resolveAppLocale', () {
    test('maps he and legacy iw to Hebrew', () {
      expect(resolveAppLocale(const Locale('he')), const Locale('he'));
      expect(resolveAppLocale(const Locale('he', 'IL')), const Locale('he'));
      expect(resolveAppLocale(const Locale('iw')), const Locale('he'));
    });

    test('maps everything else, including null, to English', () {
      expect(resolveAppLocale(const Locale('en')), const Locale('en'));
      expect(resolveAppLocale(const Locale('fr')), const Locale('en'));
      expect(resolveAppLocale(const Locale('ar')), const Locale('en'));
      expect(resolveAppLocale(null), const Locale('en'));
    });
  });

  group('localeProvider', () {
    test('defaults to null (follow device) when nothing is stored', () async {
      final c = await _container({});
      expect(c.read(localeProvider), isNull);
    });

    test('restores a stored language', () async {
      final c = await _container({kAppLocalePrefKey: 'he'});
      expect(c.read(localeProvider), const Locale('he'));
    });

    test('treats an unknown stored value as follow-device', () async {
      for (final bad in ['fr', '', 'HE ']) {
        final c = await _container({kAppLocalePrefKey: bad});
        expect(c.read(localeProvider), isNull, reason: 'stored "$bad"');
      }
    });

    test('setLocale persists and null clears', () async {
      final c = await _container({});
      final notifier = c.read(localeProvider.notifier);
      final prefs = c.read(sharedPreferencesProvider);

      await notifier.setLocale(const Locale('he'));
      expect(c.read(localeProvider), const Locale('he'));
      expect(prefs.getString(kAppLocalePrefKey), 'he');

      await notifier.setLocale(null);
      expect(c.read(localeProvider), isNull);
      expect(prefs.containsKey(kAppLocalePrefKey), isFalse);
    });
  });
}
