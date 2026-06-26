import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds user choices across onboarding steps until submit on the final screen.
@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.sportSkillLevels = const {},
    this.city,
    this.neighborhood,
    this.radiusKm = 10,
    this.pickedImagePath,
    this.avatarId,
  });

  /// Sport id → API skillLevel (`beginner`, `amateur`, …).
  final Map<String, String> sportSkillLevels;
  final String? city;
  final String? neighborhood;
  final int radiusKm;
  final String? pickedImagePath;
  final String? avatarId;

  bool get usesCustomPhoto =>
      pickedImagePath != null && pickedImagePath!.isNotEmpty;

  bool get hasRequiredLocation =>
      city != null && city!.trim().isNotEmpty;
}

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>((ref) {
  return OnboardingDraftNotifier();
});

class OnboardingDraftNotifier extends StateNotifier<OnboardingDraft> {
  OnboardingDraftNotifier() : super(const OnboardingDraft());

  static const String _defaultSkill = 'beginner';

  OnboardingDraft _copy({
    Map<String, String>? sportSkillLevels,
    String? city,
    String? neighborhood,
    int? radiusKm,
    String? pickedImagePath,
    String? avatarId,
  }) {
    return OnboardingDraft(
      sportSkillLevels: sportSkillLevels ?? state.sportSkillLevels,
      city: city ?? state.city,
      neighborhood: neighborhood ?? state.neighborhood,
      radiusKm: radiusKm ?? state.radiusKm,
      pickedImagePath: pickedImagePath ?? state.pickedImagePath,
      avatarId: avatarId ?? state.avatarId,
    );
  }

  void toggleSport(String sportId) {
    final next = Map<String, String>.from(state.sportSkillLevels);
    if (next.containsKey(sportId)) {
      next.remove(sportId);
    } else {
      next[sportId] = _defaultSkill;
    }
    state = _copy(sportSkillLevels: next);
  }

  void setSportSkill(String sportId, String skillLevel) {
    if (!state.sportSkillLevels.containsKey(sportId)) return;
    final next = Map<String, String>.from(state.sportSkillLevels);
    next[sportId] = skillLevel;
    state = _copy(sportSkillLevels: next);
  }

  void setCity(String? city) {
    state = _copy(city: city, neighborhood: null);
  }

  void setNeighborhood(String? neighborhood) {
    state = _copy(neighborhood: neighborhood);
  }

  void setRadiusKm(int radiusKm) {
    state = _copy(radiusKm: radiusKm);
  }

  void setPickedImagePath(String? path) {
    state = _copy(
      pickedImagePath: path,
      avatarId: path != null ? null : state.avatarId,
    );
  }

  void selectAvatar(String id) {
    state = _copy(pickedImagePath: null, avatarId: id);
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

  /// Payload for PATCH `location`.
  Map<String, dynamic>? locationPayload() {
    if (!state.hasRequiredLocation) return null;
    return <String, dynamic>{
      'city': state.city,
      if (state.neighborhood != null && state.neighborhood!.trim().isNotEmpty)
        'neighborhood': state.neighborhood,
      'radiusKm': state.radiusKm,
    };
  }
}
