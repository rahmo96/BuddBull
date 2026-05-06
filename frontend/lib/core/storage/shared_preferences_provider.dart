import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Injected in [main] via [ProviderScope.overrides]. Must be hydrated before
/// the first frame so GoRouter redirect can read onboarding flags synchronously.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw StateError(
    'sharedPreferencesProvider is not initialized — await '
    'SharedPreferences.getInstance() in main() and override this provider.',
  );
});
