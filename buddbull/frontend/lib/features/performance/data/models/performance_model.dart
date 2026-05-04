import 'package:intl/intl.dart';

/// A single performance log entry.
class PerformanceLogModel {
  const PerformanceLogModel({
    required this.id,
    required this.userId,
    required this.logType,
    required this.sport,
    required this.loggedAt,
    this.gameId,
    this.outcome,
    this.durationMinutes,
    this.stats = const {},
    this.selfRating,
    this.mood,
    this.notes,
    this.isPublic = false,
    this.newPersonalBests = const [],
    this.streakAtLog = 0,
    this.mediaUrls = const [],
  });

  final String id;
  final String userId;
  final String? gameId;
  final String logType; // match | training | fitness
  final String sport;
  final DateTime loggedAt;
  final String? outcome; // win | loss | draw
  final int? durationMinutes;
  final Map<String, dynamic> stats;
  final int? selfRating;
  final String? mood;
  final String? notes;
  final bool isPublic;
  final List<PersonalBest> newPersonalBests;
  final int streakAtLog;
  final List<String> mediaUrls;

  String get formattedDate =>
      DateFormat('EEE, d MMM y').format(loggedAt);

  factory PerformanceLogModel.fromJson(Map<String, dynamic> json) {
    return PerformanceLogModel(
      id: json['_id'] as String? ?? json['id'] as String,
      userId: json['user'] is Map
          ? (json['user']['_id'] as String? ??
              json['user']['id'] as String)
          : json['user'] as String,
      gameId: json['game'] is Map
          ? (json['game']['_id'] as String?)
          : json['game'] as String?,
      logType: json['logType'] as String? ?? 'training',
      sport: json['sport'] as String,
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      outcome: json['matchOutcome'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
      stats: (json['stats'] as List<dynamic>?)?.fold(
            <String, dynamic>{},
            (map, item) {
              final s = item as Map<String, dynamic>;
              (map as Map<String, dynamic>)[s['metric'] as String] =
                  s['value'];
              return map;
            },
          ) ??
          {},
      selfRating: json['selfRating'] as int?,
      mood: json['mood'] as String?,
      notes: json['notes'] as String?,
      isPublic: json['isPublic'] as bool? ?? false,
      newPersonalBests:
          (json['newPersonalBests'] as List<dynamic>?)
                  ?.map((e) => PersonalBest.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
      streakAtLog: json['streakAtLog'] as int? ?? 0,
      mediaUrls: (json['mediaUrls'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
    );
  }

  Map<String, dynamic> toCreatePayload() => {
        'type': logType,
        'sport': sport,
        'loggedAt': loggedAt.toIso8601String(),
        if (outcome != null) 'matchOutcome': outcome,
        if (durationMinutes != null)
          'durationMinutes': durationMinutes,
        if (stats.isNotEmpty)
          'stats': stats.entries
              .map((e) => {'key': e.key, 'value': e.value})
              .toList(),
        if (selfRating != null) 'selfRating': selfRating,
        if (mood != null) 'mood': mood,
        if (notes != null) 'notes': notes,
        'isPublic': isPublic,
      };
}

class PersonalBest {
  const PersonalBest({
    required this.metric,
    required this.value,
    required this.sport,
  });

  final String metric;
  final dynamic value;
  final String sport;

  factory PersonalBest.fromJson(Map<String, dynamic> json) =>
      PersonalBest(
        metric: json['metric'] as String,
        value: json['value'],
        sport: json['sport'] as String? ?? '',
      );
}

// ── Aggregate stats ───────────────────────────────────────────────────────────
class UserPerformanceStats {
  const UserPerformanceStats({
    this.totalSessions = 0,
    this.totalMinutes = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.personalBests = const [],
    this.recentSessions = const [],
    this.activityHeatmap = const [],
    this.sportBreakdown = const {},
  });

  final int totalSessions;
  final int totalMinutes;
  final int currentStreak;
  final int longestStreak;
  final List<PersonalBest> personalBests;
  final List<WeeklySession> recentSessions;
  final List<HeatmapEntry> activityHeatmap;
  final Map<String, int> sportBreakdown;

  factory UserPerformanceStats.fromJson(
      Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? json;
    return UserPerformanceStats(
      totalSessions: data['totalSessions'] as int? ?? 0,
      totalMinutes: data['totalMinutes'] as int? ?? 0,
      currentStreak: data['currentStreak'] as int? ?? 0,
      longestStreak: data['longestStreak'] as int? ?? 0,
      personalBests:
          (data['personalBests'] as List<dynamic>?)
                  ?.map((e) => PersonalBest.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
      recentSessions:
          (data['recentSessions'] as List<dynamic>?)
                  ?.map((e) => WeeklySession.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
      activityHeatmap:
          (data['activityHeatmap'] as List<dynamic>?)
                  ?.map((e) => HeatmapEntry.fromJson(
                      e as Map<String, dynamic>))
                  .toList() ??
              [],
      sportBreakdown: (data['sportBreakdown'] as Map?)
              ?.map((k, v) =>
                  MapEntry(k as String, (v as num).toInt())) ??
          {},
    );
  }

  static UserPerformanceStats empty() =>
      const UserPerformanceStats();
}

class WeeklySession {
  const WeeklySession({
    required this.weekLabel,
    required this.sessionCount,
    required this.totalMinutes,
    required this.wins,
  });

  final String weekLabel;
  final int sessionCount;
  final int totalMinutes;
  final int wins;

  factory WeeklySession.fromJson(Map<String, dynamic> json) =>
      WeeklySession(
        weekLabel: json['weekLabel'] as String? ?? '',
        sessionCount: json['sessionCount'] as int? ?? 0,
        totalMinutes: json['totalMinutes'] as int? ?? 0,
        wins: json['wins'] as int? ?? 0,
      );
}

class HeatmapEntry {
  const HeatmapEntry({required this.date, required this.count});

  final DateTime date;
  final int count;

  factory HeatmapEntry.fromJson(Map<String, dynamic> json) =>
      HeatmapEntry(
        date: DateTime.parse(json['date'] as String),
        count: json['count'] as int? ?? 0,
      );
}
