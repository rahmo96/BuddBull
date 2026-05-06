import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/onboarding/data/onboarding_prefs.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_draft_provider.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_redirect_listen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Clears persistence + in-memory onboarding draft after skip or successful finish.
Future<void> completePostSignupOnboarding(WidgetRef ref) async {
  await ref.read(sharedPreferencesProvider).setBool(OnboardingPrefs.pendingKey, false);
  ref.read(onboardingDraftProvider.notifier).reset();
  ref.read(onboardingRedirectListenProvider).refresh();
}

/// MOCK: replace with PATCH /profile (sports + avatar/url) via [ProfileService].
Future<void> mockSubmitOnboardingProfile(WidgetRef ref) async {
  final draft = ref.read(onboardingDraftProvider);
  final labels = ref.read(onboardingDraftProvider.notifier).selectedSportLabels();

  final photo = draft.usesCustomPhoto
      ? 'file:${draft.pickedImagePath}'
      : 'avatar:${draft.avatarId ?? 'none'}';

  if (kDebugMode) {
    debugPrint(
      '[Onboarding] submit (mock) sports=$labels photo=$photo',
    );
  }
}
