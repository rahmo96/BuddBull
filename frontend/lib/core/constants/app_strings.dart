/// All user-facing strings, centralised for future i18n.
abstract class AppStrings {
  // ── App ────────────────────────────────────────────────────────
  static const String appName = 'BuddBull';

  // ── Auth — Register ────────────────────────────────────────────
  static const String firstNameLabel = 'First name';
  static const String lastNameLabel = 'Last name';

  // ── Profile ────────────────────────────────────────────────────
  static const String editProfile = 'Edit Profile';
  static const String bioLabel = 'Bio';
  static const String bioHint = 'Tell us a bit about yourself…';
  static const String cityLabel = 'City';
  static const String neighborhoodLabel = 'Neighbourhood';
  static const String radiusLabel = 'Search radius (km)';
  static const String sportsInterests = 'Sports & Skill Levels';
  static const String addSport = '+ Add sport';
  static const String saveChanges = 'Save Changes';
  static const String friends = 'Friends';
  static const String gamesPlayed = 'Games';
  static const String rating = 'Rating';
  static const String streakDays = 'Streak';

  // ── Validation ─────────────────────────────────────────────────
  static const String fieldRequired = 'This field is required.';

  // ── Errors ─────────────────────────────────────────────────────
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection. Check your network.';
  static const String serverError = 'Server error. Please try again later.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
  static const String unauthorised = 'You are not authorised to do that.';

  // ── Navigation labels ──────────────────────────────────────────
  static const String navPerformance = 'Performance';

  AppStrings._();
}
