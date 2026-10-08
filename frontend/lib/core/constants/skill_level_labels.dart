import 'package:buddbull/l10n/app_localizations.dart';

/// Maps API / DB skill values to localized display strings.
String skillLevelDisplayName(String apiValue, AppLocalizations l10n) {
  return switch (apiValue) {
    'beginner' => l10n.skillBeginner, // l10n-ignore: API value
    'amateur' => l10n.skillAmateur, // l10n-ignore: API value
    'intermediate' => l10n.skillIntermediate, // l10n-ignore: API value
    'advanced' => l10n.skillAdvanced, // l10n-ignore: API value
    'professional' => l10n.skillProfessional, // l10n-ignore: API value
    _ => apiValue,
  };
}
