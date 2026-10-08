import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/onboarding/presentation/screens/onboarding_welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/l10n_app.dart';

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
          child: l10nMaterialApp(
            home: const OnboardingWelcomeScreen(),
          ),
        ),
      );

      expect(find.text(enL10n.onboardingWelcomeMessage), findsOneWidget);
      expect(find.text(enL10n.onboardingSportsSection), findsOneWidget);
      expect(find.text('Football'), findsOneWidget);
      expect(find.text('Basketball'), findsOneWidget);
      expect(find.text(enL10n.onboardingNext), findsOneWidget);
      expect(find.text(enL10n.onboardingSkip), findsOneWidget);
    });

    testWidgets('renders Hebrew copy and RTL when locale is he', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: l10nMaterialApp(
            locale: const Locale('he'),
            home: const OnboardingWelcomeScreen(),
          ),
        ),
      );

      expect(find.text(heL10n.onboardingWelcomeMessage), findsOneWidget);
      expect(find.text(heL10n.onboardingNext), findsOneWidget);
      expect(find.text(heL10n.onboardingStepOf(1, 3)), findsOneWidget);
      final ctx = tester.element(find.text(heL10n.onboardingNext));
      expect(Directionality.of(ctx), TextDirection.rtl);
    });

    testWidgets('selecting a sport reveals per-sport skill chips', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: l10nMaterialApp(
            home: const OnboardingWelcomeScreen(),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('onboarding_sport_football')));
      await tester.pump();

      expect(find.text(enL10n.onboardingSkillPerSport), findsOneWidget);
      expect(find.text(enL10n.skillBeginner), findsWidgets);
      expect(find.byKey(const ValueKey('onboarding_skill_football')), findsOneWidget);
    });

    testWidgets('tapping a sport chip toggles selection', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: l10nMaterialApp(
            home: const OnboardingWelcomeScreen(),
          ),
        ),
      );

      final footballChip = find.byKey(const ValueKey('onboarding_sport_football'));
      await tester.tap(footballChip);
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsWidgets);
      expect(find.text(enL10n.onboardingSkillPerSport), findsOneWidget);

      await tester.tap(footballChip);
      await tester.pump();
      expect(find.text(enL10n.onboardingSkillPerSport), findsNothing);
      expect(find.byKey(const ValueKey('onboarding_skill_football')), findsNothing);
    });
  });
}
