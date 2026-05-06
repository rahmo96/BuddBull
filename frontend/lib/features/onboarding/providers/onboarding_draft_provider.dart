import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds user choices across onboarding steps until submit on the final screen.
@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.sportSkillLevels = const {},
    this.pickedImagePath,
    this.avatarId,
  });

  /// Sport id → API skillLevel (`beginner`, `amateur`, …).
  final Map<String, String> sportSkillLevels;
  final String? pickedImagePath;
  final String? avatarId;

  bool get usesCustomPhoto =>
      pickedImagePath != null && pickedImagePath!.isNotEmpty;
}

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>((ref) {
  return OnboardingDraftNotifier();
});

class OnboardingDraftNotifier extends StateNotifier<OnboardingDraft> {
  OnboardingDraftNotifier() : super(const OnboardingDraft());

  static const String _defaultSkill = 'beginner';

  void toggleSport(String sportId) {
    final next = Map<String, String>.from(state.sportSkillLevels);
    if (next.containsKey(sportId)) {
      next.remove(sportId);
    } else {
      next[sportId] = _defaultSkill;
    }
    state = OnboardingDraft(
      sportSkillLevels: next,
      pickedImagePath: state.pickedImagePath,
      avatarId: state.avatarId,
    );
  }

  void setSportSkill(String sportId, String skillLevel) {
    if (!state.sportSkillLevels.containsKey(sportId)) return;
    final next = Map<String, String>.from(state.sportSkillLevels);
    next[sportId] = skillLevel;
    state = OnboardingDraft(
      sportSkillLevels: next,
      pickedImagePath: state.pickedImagePath,
      avatarId: state.avatarId,
    );
  }

  void setPickedImagePath(String? path) {
    state = OnboardingDraft(
      sportSkillLevels: state.sportSkillLevels,
      pickedImagePath: path,
      avatarId: path != null ? null : state.avatarId,
    );
  }

  void selectAvatar(String id) {
    state = OnboardingDraft(
      sportSkillLevels: state.sportSkillLevels,
      pickedImagePath: null,
      avatarId: id,
    );
  }

  void reset() => state = const OnboardingDraft();

  /// Payload for PATCH `sportsInterests` (sport names are lowercase ids).
  List<Map<String, dynamic>> sportsInterestsPayload() {
    final entries = state.sportSkillLevels.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries
        .map(
          (e) => <String, dynamic>{
            'sport': e.key,
            'skillLevel': e.value,
          },
        )
        .toList(growable: false);
  }
}
