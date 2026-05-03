import 'package:equatable/equatable.dart';

// ── Single rating ─────────────────────────────────────────────────────────────
class RatingModel extends Equatable {
  final String id;
  final Map<String, dynamic>? rater; // null when isAnonymous == true
  final String rateeId;
  final Map<String, dynamic>? game;
  final int reliabilityScore;
  final int behaviorScore;
  final String? comment;
  final bool isAnonymous;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    this.rater,
    required this.rateeId,
    this.game,
    required this.reliabilityScore,
    required this.behaviorScore,
    this.comment,
    this.isAnonymous = false,
    required this.createdAt,
  });

  double get averageScore => (reliabilityScore + behaviorScore) / 2;

  String get raterName {
    if (isAnonymous || rater == null) return 'Anonymous';
    final full = [rater!['firstName'], rater!['lastName']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    return full.isNotEmpty ? full : (rater!['username'] ?? 'Unknown').toString();
  }

  factory RatingModel.fromJson(Map<String, dynamic> json) => RatingModel(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        rater: json['rater'] is Map ? json['rater'] as Map<String, dynamic> : null,
        rateeId: (json['ratee'] is Map ? json['ratee']['_id'] : json['ratee'] ?? '').toString(),
        game: json['game'] is Map ? json['game'] as Map<String, dynamic> : null,
        reliabilityScore: (json['reliabilityScore'] as num?)?.toInt() ?? 1,
        behaviorScore: (json['behaviorScore'] as num?)?.toInt() ?? 1,
        comment: json['comment']?.toString(),
        isAnonymous: json['isAnonymous'] == true,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [id];
}

// ── Aggregated profile summary ────────────────────────────────────────────────
class RatingProfileSummary extends Equatable {
  final double avgReliability;
  final double avgBehavior;
  final double overall;
  final int totalRatings;
  final Map<int, int> reliabilityDistribution; // score → count
  final Map<int, int> behaviorDistribution;

  const RatingProfileSummary({
    this.avgReliability = 0,
    this.avgBehavior = 0,
    this.overall = 0,
    this.totalRatings = 0,
    this.reliabilityDistribution = const {},
    this.behaviorDistribution = const {},
  });

  factory RatingProfileSummary.fromJson(Map<String, dynamic> json) {
    Map<int, int> toDist(dynamic raw) {
      if (raw is! Map) return {};
      return raw.map((k, v) => MapEntry(int.tryParse(k.toString()) ?? 0, (v as num).toInt()));
    }

    return RatingProfileSummary(
      avgReliability: (json['avgReliability'] as num?)?.toDouble() ?? 0,
      avgBehavior: (json['avgBehavior'] as num?)?.toDouble() ?? 0,
      overall: (json['overall'] as num?)?.toDouble() ?? 0,
      totalRatings: (json['totalRatings'] as num?)?.toInt() ?? 0,
      reliabilityDistribution: toDist(json['reliabilityDistribution']),
      behaviorDistribution: toDist(json['behaviorDistribution']),
    );
  }

  @override
  List<Object?> get props => [overall, totalRatings];
}

// ── Pending rating item ───────────────────────────────────────────────────────
class PendingRatingItem extends Equatable {
  final String gameId;
  final String gameTitle;
  final String gameSport;
  final List<Map<String, dynamic>> pendingPlayers;

  const PendingRatingItem({
    required this.gameId,
    required this.gameTitle,
    required this.gameSport,
    required this.pendingPlayers,
  });

  factory PendingRatingItem.fromJson(Map<String, dynamic> json) {
    final game = json['game'] as Map<String, dynamic>? ?? {};
    final players = json['pendingPlayers'] as List? ?? [];
    return PendingRatingItem(
      gameId: (game['id'] ?? game['_id'] ?? '').toString(),
      gameTitle: (game['title'] ?? 'Untitled').toString(),
      gameSport: (game['sport'] ?? '').toString(),
      pendingPlayers: players.whereType<Map<String, dynamic>>().toList(),
    );
  }

  @override
  List<Object?> get props => [gameId];
}
