import 'package:buddbull/core/localization/locale_provider.dart';
import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

final AppLocalizations enL10n = lookupAppLocalizations(const Locale('en'));
final AppLocalizations heL10n = lookupAppLocalizations(const Locale('he'));

Widget l10nMaterialApp({Locale locale = const Locale('en'), Widget? home}) {
  return MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: (device, _) => resolveAppLocale(device),
    builder: (context, child) {
      Intl.defaultLocale = Localizations.localeOf(context).languageCode;
      return child ?? const SizedBox.shrink();
    },
    home: home,
  );
}

Widget l10nRouterApp(
  RouterConfig<Object> router, {
  Locale locale = const Locale('en'),
}) {
  return MaterialApp.router(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    localeResolutionCallback: (device, _) => resolveAppLocale(device),
    routerConfig: router,
    builder: (context, child) {
      Intl.defaultLocale = Localizations.localeOf(context).languageCode;
      return child ?? const SizedBox.shrink();
    },
  );
}
