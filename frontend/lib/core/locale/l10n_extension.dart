import 'package:buddbull/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
