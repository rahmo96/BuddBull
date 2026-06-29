import 'package:buddbull/core/locale/locale_prefs.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider =
    NotifierProvider<LocaleNotifier, Locale>(LocaleNotifier.new);

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    final code =
        ref.watch(sharedPreferencesProvider).getString(LocalePrefs.key);
    return Locale(code == 'he' ? 'he' : 'en');
  }

  Future<void> setLocale(Locale locale) async {
    final prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(LocalePrefs.key, locale.languageCode);
    state = locale;
  }

  bool get isHebrew => state.languageCode == 'he';

  Future<void> toggleHebrew(bool useHebrew) =>
      setLocale(Locale(useHebrew ? 'he' : 'en'));
}
