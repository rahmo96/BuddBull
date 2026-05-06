import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/onboarding/data/onboarding_prefs.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_draft_provider.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_redirect_listen.dart';
import 'package:buddbull/features/profile/data/user_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

/// Clears persistence + in-memory onboarding draft after skip or successful finish.
Future<void> completePostSignupOnboarding(WidgetRef ref) async {
  await ref
      .read(sharedPreferencesProvider)
      .setBool(OnboardingPrefs.pendingKey, false);
  ref.read(onboardingDraftProvider.notifier).reset();
  ref.read(onboardingRedirectListenProvider).refresh();
}

/// Persists sports, optional device photo, or preset avatar via existing user APIs.
Future<void> submitOnboardingToBackend(
  WidgetRef ref, {
  required bool savePresetAvatar,
}) async {
  final repo = ref.read(userRepositoryProvider);
  final draft = ref.read(onboardingDraftProvider);
  final notifier = ref.read(onboardingDraftProvider.notifier);

  if (!kIsWeb && draft.usesCustomPhoto && draft.pickedImagePath != null) {
    final user = await repo.updateProfilePicture(
      XFile(draft.pickedImagePath!),
    );
    ref.read(authProvider.notifier).updateUser(user);
  }

  final interests = notifier.sportsInterestsPayload();
  final patch = <String, dynamic>{};
  if (interests.isNotEmpty) {
    patch['sportsInterests'] = interests;
  }
  if (savePresetAvatar &&
      !draft.usesCustomPhoto &&
      draft.avatarId != null &&
      draft.avatarId!.isNotEmpty) {
    patch['profilePicture'] = 'avatar:${draft.avatarId}';
  }

  if (patch.isNotEmpty) {
    final user = await repo.updateMe(patch);
    ref.read(authProvider.notifier).updateUser(user);
  }

  final fresh = await repo.getMe();
  ref.read(authProvider.notifier).updateUser(fresh);
}
