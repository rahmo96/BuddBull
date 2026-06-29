import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/l10n_test_helpers.dart';

void main() {
  testWidgets('Onboarding welcome smoke (no Firebase)', (tester) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: wrapWithL10n(const OnboardingWelcomeScreen()),
      ),
    );

    expect(find.byType(OnboardingWelcomeScreen), findsOneWidget);
  });
}
