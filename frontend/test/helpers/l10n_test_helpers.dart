import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps [child] in a [MaterialApp] with BuddBull localization delegates.
Widget wrapWithL10n(
  Widget child, {
  Locale locale = const Locale('en'),
  List<Override>? overrides,
}) {
  return ProviderScope(
    overrides: overrides ?? const [],
    child: MaterialApp(
      locale: locale,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: child,
    ),
  );
}

/// English strings from generated l10n (for find.text in tests).
AppLocalizations enL10n() =>
    lookupAppLocalizations(const Locale('en'));

/// Hebrew strings from generated l10n (for find.text in tests).
AppLocalizations heL10n() =>
    lookupAppLocalizations(const Locale('he'));
