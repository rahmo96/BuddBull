import 'package:buddbull/l10n/app_localizations.dart';

/// Localized label for a performance-log type as stored by the API.
String logTypeDisplayName(String type, AppLocalizations l10n) {
  return switch (type) {
    'match' => l10n.logTypeMatch, // l10n-ignore: API value
    'training' => l10n.logTypeTraining, // l10n-ignore: API value
    'fitness' => l10n.logTypeFitness, // l10n-ignore: API value
    _ => type,
  };
}

/// Localized label for a match outcome as stored by the API.
String outcomeDisplayName(String outcome, AppLocalizations l10n) {
  return switch (outcome) {
    'win' => l10n.outcomeWin, // l10n-ignore: API value
    'loss' => l10n.outcomeLoss, // l10n-ignore: API value
    'draw' => l10n.outcomeDraw, // l10n-ignore: API value
    _ => outcome,
  };
}

/// Localized label for a mood. Accepts both the form values and the API values.
String moodDisplayName(String mood, AppLocalizations l10n) {
  return switch (mood) {
    'great' || 'excellent' => l10n.moodGreat, // l10n-ignore: API value
    'good' => l10n.moodGood, // l10n-ignore: API value
    'ok' || 'neutral' => l10n.moodOk, // l10n-ignore: API value
    'tired' || 'bad' => l10n.moodTired, // l10n-ignore: API value
    'injured' || 'terrible' => l10n.moodInjured, // l10n-ignore: API value
    _ => mood,
  };
}
