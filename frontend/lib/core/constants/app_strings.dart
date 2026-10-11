/// Non-localized constants: the brand name and exception fallback messages
/// (errors surfaced from the data layer stay in English by design).
abstract class AppStrings {
  // ── App ────────────────────────────────────────────────────────
  static const String appName = 'BuddBull';

  // ── Errors ─────────────────────────────────────────────────────
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'No internet connection. Check your network.';
  static const String serverError = 'Server error. Please try again later.';
  static const String sessionExpired = 'Your session has expired. Please sign in again.';
  static const String unauthorised = 'You are not authorised to do that.';

  AppStrings._();
}
