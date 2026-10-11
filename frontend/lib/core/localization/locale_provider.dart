import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kAppLocalePrefKey = 'app_locale';

const Locale _en = Locale('en');
const Locale _he = Locale('he');

/// Maps any requested/device locale to a supported one.
/// Hebrew (`he`, or the legacy Android code `iw`) → Hebrew; everything else → English.
Locale resolveAppLocale(Locale? requested) {
  final code = requested?.languageCode;
  return (code == 'he' || code == 'iw') ? _he : _en;
}

/// `null` state means "follow the device language".
class LocaleNotifier extends StateNotifier<Locale?> {
  LocaleNotifier(this._prefs) : super(_read(_prefs));

  final SharedPreferences _prefs;

  static Locale? _read(SharedPreferences prefs) {
    switch (prefs.getString(kAppLocalePrefKey)) {
      case 'en':
        return _en;
      case 'he':
        return _he;
      default:
        return null;
    }
  }

  Future<void> setLocale(Locale? locale) async {
    state = locale;
    if (locale == null) {
      await _prefs.remove(kAppLocalePrefKey);
    } else {
      await _prefs.setString(kAppLocalePrefKey, locale.languageCode);
    }
  }
}

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale?>((ref) {
  return LocaleNotifier(ref.watch(sharedPreferencesProvider));
});
