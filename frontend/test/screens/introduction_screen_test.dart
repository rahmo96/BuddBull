import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/l10n_test_helpers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Post-signup onboarding (welcome)', () {
    testWidgets('renders headline, sports chips, and actions', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final l10n = enL10n();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: wrapWithL10n(const OnboardingWelcomeScreen()),
        ),
      );

      expect(find.text(l10n.onboardingWelcomeMessage), findsOneWidget);
      expect(find.text(l10n.onboardingSportsSection), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Basketball'), findsOneWidget);
      expect(find.text(l10n.onboardingNext), findsOneWidget);
      expect(find.text(l10n.onboardingSkip), findsOneWidget);
    });

    testWidgets('selecting a sport reveals per-sport skill chips', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final l10n = enL10n();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: wrapWithL10n(const OnboardingWelcomeScreen()),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('onboarding_sport_football')));
      await tester.pump();

      expect(find.text(l10n.onboardingSkillPerSport), findsOneWidget);
      expect(find.text(l10n.beginner), findsWidgets);
      expect(find.byKey(const ValueKey('onboarding_skill_football')), findsOneWidget);
    });

    testWidgets('tapping a sport chip toggles selection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final l10n = enL10n();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: wrapWithL10n(const OnboardingWelcomeScreen()),
        ),
      );

      final footballChip = find.byKey(const ValueKey('onboarding_sport_football'));
      await tester.tap(footballChip);
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      expect(find.text(l10n.onboardingSkillPerSport), findsOneWidget);

      await tester.tap(footballChip);
      await tester.pump();
      expect(find.text(l10n.onboardingSkillPerSport), findsNothing);
      expect(find.byKey(const ValueKey('onboarding_skill_football')), findsNothing);
    });
  });
}
