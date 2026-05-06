import 'package:buddbull/features/onboarding/data/onboarding_mock_data.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds user choices across onboarding steps until submit on the final screen.
@immutable
class OnboardingDraft {
  const OnboardingDraft({
    this.selectedSportIds = const {},
    this.pickedImagePath,
    this.avatarId,
  });

  final Set<String> selectedSportIds;
  final String? pickedImagePath;
  final String? avatarId;

  /// Custom photo wins over preset avatar until cleared.
  bool get usesCustomPhoto =>
      pickedImagePath != null && pickedImagePath!.isNotEmpty;
}

final onboardingDraftProvider =
    StateNotifierProvider<OnboardingDraftNotifier, OnboardingDraft>((ref) {
  return OnboardingDraftNotifier();
});

class OnboardingDraftNotifier extends StateNotifier<OnboardingDraft> {
  OnboardingDraftNotifier() : super(const OnboardingDraft());

  void toggleSport(String id) {
    final next = Set<String>.from(state.selectedSportIds);
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    state = OnboardingDraft(selectedSportIds: next, pickedImagePath: state.pickedImagePath, avatarId: state.avatarId);
  }

  void setPickedImagePath(String? path) {
    state = OnboardingDraft(
      selectedSportIds: state.selectedSportIds,
      pickedImagePath: path,
      avatarId: path != null ? null : state.avatarId,
    );
  }

  void selectAvatar(String id) {
    state = OnboardingDraft(
      selectedSportIds: state.selectedSportIds,
      pickedImagePath: null,
      avatarId: id,
    );
  }

  void reset() => state = const OnboardingDraft();

  /// Labels for aggregated mock submit (sport ids resolved to display names).
  List<String> selectedSportLabels() {
    final byId = {for (final s in OnboardingMockData.sports) s.id: s.label};
    return state.selectedSportIds
        .map((id) => byId[id] ?? id)
        .toList(growable: false);
  }
}
