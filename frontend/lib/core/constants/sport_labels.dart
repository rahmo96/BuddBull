import 'package:buddbull/l10n/app_localizations.dart';

/// Maps a sport name as stored by the API to its localized display name.
/// Unknown sports are shown as received.
String sportDisplayName(String sport, AppLocalizations l10n) {
  return switch (sport.trim().toLowerCase()) {
    'football' || 'soccer' => l10n.sportFootball, // l10n-ignore: API value
    'basketball' => l10n.sportBasketball, // l10n-ignore: API value
    'tennis' => l10n.sportTennis, // l10n-ignore: API value
    'volleyball' => l10n.sportVolleyball, // l10n-ignore: API value
    'running' => l10n.sportRunning, // l10n-ignore: API value
    'swimming' => l10n.sportSwimming, // l10n-ignore: API value
    'cycling' => l10n.sportCycling, // l10n-ignore: API value
    'cricket' => l10n.sportCricket, // l10n-ignore: API value
    _ => sport,
  };
}
