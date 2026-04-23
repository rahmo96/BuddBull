import 'package:intl/intl.dart';

/// Full game/match model mirroring the backend Game schema.
class GameModel {
  const GameModel({
    required this.id,
    required this.title,
    required this.sport,
    required this.organizer,
    required this.scheduledAt,
    required this.durationMinutes,
    required this.location,
    required this.maxPlayers,
    required this.players,
    required this.requiredSkillLevel,
    required this.status,
    this.description,
    this.groupChatId,
    this.tags = const [],
    this.result,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? description;
  final String sport;
  final GameOrganizer organizer;
  final DateTime scheduledAt;
  final int durationMinutes;
  final GameLocation location;
  final int maxPlayers;
  final List<GamePlayer> players;
  final String requiredSkillLevel;
  final String status;
  final String? groupChatId;
  final List<String> tags;
  final GameResult? result;
  final DateTime? createdAt;

  // ── Computed ──────────────────────────────────────────────
  int get approvedCount =>
      players.where((p) => p.status == 'approved').length;
  int get pendingCount =>
      players.where((p) => p.status == 'pending').length;
  int get availableSlots => maxPlayers - approvedCount;
  bool get isFull => availableSlots <= 0;
  bool get isOpen => status == 'open';
  bool get isUpcoming => status == 'open' || status == 'full';
  bool get isInProgress => status == 'in_progress';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  DateTime get endTime =>
      scheduledAt.add(Duration(minutes: durationMinutes));

  String get formattedDate =>
      DateFormat('EEE, d MMM y').format(scheduledAt);
  String get formattedTime => DateFormat('HH:mm').format(scheduledAt);
  String get formattedDuration {
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    if (h == 0) return '${m}min';
    if (m == 0) return '${h}h';
    return '${h}h ${m}min';
  }

  bool hasPlayer(String userId) =>
      players.any((p) => p.userId == userId);

  GamePlayer? getPlayer(String userId) {
    final matches = players.where((p) => p.userId == userId).toList();
    return matches.isEmpty ? null : matches.first;
  }

  // ── Serialisation ─────────────────────────────────────────
  static String? _parseGroupChatId(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      final id = value['_id'] ?? value['id'];
      return id is String ? id : id?.toString();
    }
    return null;
  }

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['_id'] as String? ?? json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      sport: json['sport'] as String,
      organizer: GameOrganizer.fromJson(
          json['organizer'] as Map<String, dynamic>),
      scheduledAt:
          DateTime.parse(json['scheduledAt'] as String),
      durationMinutes: json['durationMinutes'] as int? ?? 60,
      location: GameLocation.fromJson(
          json['location'] as Map<String, dynamic>),
      maxPlayers: json['maxPlayers'] as int,
      players: (json['players'] as List<dynamic>?)
              ?.map((e) =>
                  GamePlayer.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      requiredSkillLevel:
          json['requiredSkillLevel'] as String? ?? 'any',
      status: json['status'] as String? ?? 'open',
      groupChatId: _parseGroupChatId(json['groupChat']),
      tags: (json['tags'] as List<dynamic>?)
              ?.cast<String>() ??
          [],
      result: json['result'] != null
          ? GameResult.fromJson(
              json['result'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'sport': sport,
        if (description != null) 'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'location': location.toJson(),
        'maxPlayers': maxPlayers,
        'requiredSkillLevel': requiredSkillLevel,
        if (tags.isNotEmpty) 'tags': tags,
      };

  GameModel copyWith({
    String? title,
    String? description,
    String? sport,
    DateTime? scheduledAt,
    int? durationMinutes,
    GameLocation? location,
    int? maxPlayers,
    List<GamePlayer>? players,
    String? requiredSkillLevel,
    String? status,
  }) {
    return GameModel(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      sport: sport ?? this.sport,
      organizer: organizer,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      location: location ?? this.location,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      players: players ?? this.players,
      requiredSkillLevel:
          requiredSkillLevel ?? this.requiredSkillLevel,
      status: status ?? this.status,
      groupChatId: groupChatId,
      tags: tags,
      result: result,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is GameModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Sub-models ────────────────────────────────────────────────────────────────
class GameOrganizer {
  const GameOrganizer({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    this.profilePicture,
  });

  final String id;
  final String username;
  final String firstName;
  final String lastName;
  final String? profilePicture;

  String get fullName => '$firstName $lastName';

  factory GameOrganizer.fromJson(Map<String, dynamic> json) =>
      GameOrganizer(
        id: json['_id'] as String? ?? json['id'] as String,
        username: json['username'] as String,
        firstName: json['firstName'] as String,
        lastName: json['lastName'] as String,
        profilePicture: json['profilePicture'] as String?,
      );
}

class GameLocation {
  const GameLocation({
    required this.city,
    this.neighborhood,
    this.venueName,
  });

  final String city;
  final String? neighborhood;
  final String? venueName;

  String get displayName {
    final parts = <String>[];
    if (venueName != null) parts.add(venueName!);
    if (neighborhood != null) parts.add(neighborhood!);
    parts.add(city);
    return parts.join(', ');
  }

  factory GameLocation.fromJson(Map<String, dynamic> json) =>
      GameLocation(
        city: json['city'] as String,
        neighborhood: json['neighborhood'] as String?,
        venueName: json['venueName'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'city': city,
        if (neighborhood != null) 'neighborhood': neighborhood,
        if (venueName != null) 'venueName': venueName,
      };
}

class GamePlayer {
  const GamePlayer({
    required this.userId,
    required this.username,
    required this.status,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.joinedAt,
  });

  final String userId;
  final String username;
  final String status; // approved | pending | invited | kicked | left
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final DateTime? joinedAt;

  bool get isApproved => status == 'approved';
  bool get isPending => status == 'pending';

  String get displayName =>
      (firstName != null && lastName != null)
          ? '$firstName $lastName'
          : username;

  factory GamePlayer.fromJson(Map<String, dynamic> json) {
    final userRaw = json['user'];
    final Map<String, dynamic>? user = userRaw is Map<String, dynamic>
        ? userRaw
        : null;
    // Backend may send user as String (e.g. id reference) or as populated map
    final String userId = user != null
        ? (user['_id'] as String? ?? user['id'] as String? ?? '')
        : (userRaw is String
            ? userRaw
            : (json['userId'] as String? ?? ''));
    final String username =
        user?['username'] as String? ?? json['username'] as String? ?? '';

    return GamePlayer(
      userId: userId,
      username: username,
      status: json['status'] as String,
      firstName: user?['firstName'] as String?,
      lastName: user?['lastName'] as String?,
      profilePicture: user?['profilePicture'] as String?,
      joinedAt: json['joinedAt'] != null
          ? DateTime.tryParse(json['joinedAt'] as String)
          : null,
    );
  }
}

class GameResult {
  const GameResult({
    this.winner,
    this.score,
    this.notes,
    this.completedAt,
  });

  final String? winner;
  final String? score;
  final String? notes;
  final DateTime? completedAt;

  factory GameResult.fromJson(Map<String, dynamic> json) =>
      GameResult(
        winner: json['winner'] as String?,
        score: json['score'] as String?,
        notes: json['notes'] as String?,
        completedAt: json['completedAt'] != null
            ? DateTime.tryParse(json['completedAt'] as String)
            : null,
      );
}

// ── Search parameters ─────────────────────────────────────────────────────────
class GameSearchParams {
  const GameSearchParams({
    this.sport,
    this.city,
    this.skillLevel,
    this.status = 'open',
    this.page = 1,
    this.limit = 20,
    this.sortBy = 'scheduledAt',
  });

  final String? sport;
  final String? city;
  final String? skillLevel;
  final String status;
  final int page;
  final int limit;
  final String sortBy;

  Map<String, dynamic> toQueryParams() => {
        if (sport != null) 'sport': sport,
        if (city != null) 'city': city,
        if (skillLevel != null) 'skillLevel': skillLevel,
        'status': status,
        'page': page,
        'limit': limit,
        'sortBy': sortBy,
      };

  GameSearchParams copyWith({
    String? sport,
    String? city,
    String? skillLevel,
    String? status,
    int? page,
  }) {
    return GameSearchParams(
      sport: sport ?? this.sport,
      city: city ?? this.city,
      skillLevel: skillLevel ?? this.skillLevel,
      status: status ?? this.status,
      page: page ?? this.page,
      limit: limit,
      sortBy: sortBy,
    );
  }

  GameSearchParams clearSport() => GameSearchParams(
        city: city,
        skillLevel: skillLevel,
        status: status,
      );

  @override
  bool operator ==(Object other) =>
      other is GameSearchParams &&
      other.sport == sport &&
      other.city == city &&
      other.skillLevel == skillLevel &&
      other.status == status &&
      other.page == page;

  @override
  int get hashCode =>
      Object.hash(sport, city, skillLevel, status, page);
}
