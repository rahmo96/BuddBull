import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/features/rating/data/rating_repository.dart';
import 'package:buddbull/features/rating/data/models/rating_model.dart';

// ── Repository ────────────────────────────────────────────────────────────────
final ratingRepositoryProvider = Provider<RatingRepository>((ref) {
  return RatingRepository(ref.watch(apiClientProvider));
});

// ── Profile summary for any user ─────────────────────────────────────────────
final ratingProfileProvider = FutureProvider.family<RatingProfileSummary, String>((ref, userId) {
  return ref.watch(ratingRepositoryProvider).getProfileSummary(userId);
});

// ── My received ratings ───────────────────────────────────────────────────────
final myReceivedRatingsProvider = FutureProvider<List<RatingModel>>((ref) {
  return ref.watch(ratingRepositoryProvider).getReceivedRatings();
});

// ── Games waiting for ratings from me ────────────────────────────────────────
final pendingRatingsProvider = FutureProvider<List<PendingRatingItem>>((ref) {
  return ref.watch(ratingRepositoryProvider).getPendingRatings();
});

// ── Rate player notifier ──────────────────────────────────────────────────────
class RatePlayerState {
  final bool isLoading;
  final bool success;
  final String? error;
  const RatePlayerState({this.isLoading = false, this.success = false, this.error});
}

class RatePlayerNotifier extends StateNotifier<RatePlayerState> {
  final RatingRepository _repo;
  RatePlayerNotifier(this._repo) : super(const RatePlayerState());

  Future<bool> rate({
    required String rateeId,
    required String gameId,
    required int reliabilityScore,
    required int behaviorScore,
    String? comment,
    bool isAnonymous = false,
  }) async {
    state = const RatePlayerState(isLoading: true);
    try {
      await _repo.ratePlayer(
        rateeId: rateeId,
        gameId: gameId,
        reliabilityScore: reliabilityScore,
        behaviorScore: behaviorScore,
        comment: comment,
        isAnonymous: isAnonymous,
      );
      state = const RatePlayerState(success: true);
      return true;
    } catch (e) {
      state = RatePlayerState(error: e.toString());
      return false;
    }
  }
}

final ratePlayerProvider = StateNotifierProvider.autoDispose<RatePlayerNotifier, RatePlayerState>(
  (ref) => RatePlayerNotifier(ref.watch(ratingRepositoryProvider)),
);
