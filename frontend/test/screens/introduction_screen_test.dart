import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Post-signup onboarding (welcome)', () {
    testWidgets('renders headline, sports chips, and actions', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: OnboardingWelcomeScreen(),
          ),
        ),
      );

      expect(find.text(AppStrings.onboardingWelcomeMessage), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Basketball'), findsOneWidget);
      expect(find.text(AppStrings.onboardingNext), findsOneWidget);
      expect(find.text(AppStrings.onboardingSkip), findsOneWidget);
    });

    testWidgets('tapping a sport chip toggles selection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const MaterialApp(
            home: OnboardingWelcomeScreen(),
          ),
        ),
      );

      final footballChip = find.byKey(const ValueKey('onboarding_sport_football'));
      await tester.tap(footballChip);
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsWidgets);

      await tester.tap(footballChip);
      await tester.pump();
    });
  });
}
