import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/rating/data/models/rating_model.dart';

class RatingRepository {
  final ApiClient _client;
  const RatingRepository(this._client);

  Future<RatingModel> ratePlayer({
    required String rateeId,
    required String gameId,
    required int reliabilityScore,
    required int behaviorScore,
    String? comment,
    bool isAnonymous = false,
  }) async {
    final res = await _client.post(
      ApiEndpoints.ratings,
      data: {
        'rateeId': rateeId,
        'gameId': gameId,
        'reliabilityScore': reliabilityScore,
        'behaviorScore': behaviorScore,
        if (comment != null && comment.isNotEmpty) 'comment': comment,
        'isAnonymous': isAnonymous,
      },
    );
    return RatingModel.fromJson(res['data']['rating'] as Map<String, dynamic>);
  }

  Future<RatingProfileSummary> getProfileSummary(String userId) async {
    final res = await _client.get(ApiEndpoints.ratingSummary(userId));
    final raw = res['data']['summary'];
    if (raw == null) return const RatingProfileSummary();
    return RatingProfileSummary.fromJson(raw as Map<String, dynamic>);
  }

  Future<List<RatingModel>> getReceivedRatings({int page = 1, int limit = 20}) async {
    final res = await _client.get(
      ApiEndpoints.receivedRatings,
      queryParams: {'page': page, 'limit': limit},
    );
    final raw = res['data']['ratings'] as List;
    return raw.whereType<Map<String, dynamic>>().map(RatingModel.fromJson).toList();
  }

  Future<List<PendingRatingItem>> getPendingRatings() async {
    final res = await _client.get(ApiEndpoints.pendingRatings);
    final raw = res['data']['pending'] as List;
    return raw.whereType<Map<String, dynamic>>().map(PendingRatingItem.fromJson).toList();
  }
}
