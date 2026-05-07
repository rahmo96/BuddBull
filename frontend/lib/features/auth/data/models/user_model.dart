/// Lightweight user model used across the app.
/// Matches the shape returned by `/auth/login` and `/users/me`.
class UserModel {
  const UserModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.email,
    required this.role,
    this.bio,
    this.profilePicture,
    this.isEmailVerified = false,
    this.isActive = true,
    this.stats,
    this.location,
    this.sportsInterests = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.createdAt,
    this.performanceSummary,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String username;
  final String email;
  final String role;
  final String? bio;
  final String? profilePicture;
  final bool isEmailVerified;
  final bool isActive;
  final UserStats? stats;
  final UserLocation? location;
  final List<SportInterest> sportsInterests;
  final int followersCount;
  final int followingCount;
  final DateTime? createdAt;
  final UserPerformanceSummary? performanceSummary;

  String get fullName => '$firstName $lastName';
  bool get isOrganizer => role == 'organizer';
  bool get isAdmin => role == 'admin';

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      username: json['username'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'player',
      bio: json['bio'] as String?,
      profilePicture: json['profilePicture'] as String?,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      isActive: json['isActive'] as bool? ?? true,
      stats: json['stats'] != null
          ? UserStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      sportsInterests: (json['sportsInterests'] as List<dynamic>?)
              ?.map((e) =>
                  SportInterest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      followersCount: json['followersCount'] as int? ?? 0,
      followingCount: json['followingCount'] as int? ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      performanceSummary: json['performanceSummary'] != null
          ? UserPerformanceSummary.fromJson(
              json['performanceSummary'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'firstName': firstName,
        'lastName': lastName,
        'username': username,
        'email': email,
        'role': role,
        if (bio != null) 'bio': bio,
        if (location != null) 'location': location!.toJson(),
        'sportsInterests': sportsInterests.map((s) => s.toJson()).toList(),
      };

  UserModel copyWith({
    String? firstName,
    String? lastName,
    String? username,
    String? bio,
    String? profilePicture,
    UserLocation? location,
    List<SportInterest>? sportsInterests,
    UserStats? stats,
    int? followersCount,
    int? followingCount,
    UserPerformanceSummary? performanceSummary,
  }) {
    return UserModel(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      username: username ?? this.username,
      email: email,
      role: role,
      bio: bio ?? this.bio,
      profilePicture: profilePicture ?? this.profilePicture,
      isEmailVerified: isEmailVerified,
      isActive: isActive,
      stats: stats ?? this.stats,
      location: location ?? this.location,
      sportsInterests: sportsInterests ?? this.sportsInterests,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt,
      performanceSummary: performanceSummary ?? this.performanceSummary,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is UserModel && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

// ── Nested models ─────────────────────────────────────────────────────────────
class UserStats {
  const UserStats({
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.averageRating = 0.0,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  final int gamesPlayed;
  final int gamesWon;
  final double averageRating;
  final int currentStreak;
  final int longestStreak;

  factory UserStats.fromJson(Map<String, dynamic> json) => UserStats(
        gamesPlayed: json['gamesPlayed'] as int? ?? 0,
        gamesWon: json['gamesWon'] as int? ?? 0,
        averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
        currentStreak: json['currentStreak'] as int? ?? 0,
        longestStreak: json['longestStreak'] as int? ?? 0,
      );
}

class UserLocation {
  const UserLocation({
    this.city,
    this.neighborhood,
    this.radiusKm = 10,
  });

  final String? city;
  final String? neighborhood;
  final int radiusKm;

  factory UserLocation.fromJson(Map<String, dynamic> json) => UserLocation(
        city: json['city'] as String?,
        neighborhood: json['neighborhood'] as String?,
        radiusKm: json['radiusKm'] as int? ?? 10,
      );

  Map<String, dynamic> toJson() => {
        if (city != null) 'city': city,
        if (neighborhood != null) 'neighborhood': neighborhood,
        'radiusKm': radiusKm,
      };
}

class SportInterest {
  const SportInterest({
    required this.sport,
    required this.skillLevel,
  });

  final String sport;
  final String skillLevel;

  factory SportInterest.fromJson(Map<String, dynamic> json) => SportInterest(
        sport: json['sport'] as String,
        skillLevel: json['skillLevel'] as String,
      );

  Map<String, dynamic> toJson() => {
        'sport': sport,
        'skillLevel': skillLevel,
      };

  SportInterest copyWith({String? sport, String? skillLevel}) => SportInterest(
        sport: sport ?? this.sport,
        skillLevel: skillLevel ?? this.skillLevel,
      );
}

class UserPerformanceSummary {
  const UserPerformanceSummary({
    this.ratings = const UserRatingSummary(),
    this.recentActivity = const [],
    this.upcomingGames = const [],
  });

  final UserRatingSummary ratings;
  final List<UserActivityItem> recentActivity;
  final List<UserUpcomingGame> upcomingGames;

  factory UserPerformanceSummary.fromJson(Map<String, dynamic> json) {
    return UserPerformanceSummary(
      ratings: json['ratings'] != null
          ? UserRatingSummary.fromJson(json['ratings'] as Map<String, dynamic>)
          : const UserRatingSummary(),
      recentActivity: (json['recentActivity'] as List<dynamic>?)
              ?.map((e) => UserActivityItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      upcomingGames: (json['upcomingGames'] as List<dynamic>?)
              ?.map((e) => UserUpcomingGame.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
    );
  }
}

class UserRatingSummary {
  const UserRatingSummary({
    this.totalRatings = 0,
    this.avgReliability = 0,
    this.avgBehavior = 0,
    this.avgComposite = 0,
  });

  final int totalRatings;
  final num avgReliability;
  final num avgBehavior;
  final num avgComposite;

  factory UserRatingSummary.fromJson(Map<String, dynamic> json) {
    return UserRatingSummary(
      totalRatings: json['totalRatings'] as int? ?? 0,
      avgReliability: (json['avgReliability'] as num?) ?? 0,
      avgBehavior: (json['avgBehavior'] as num?) ?? 0,
      avgComposite: (json['avgComposite'] as num?) ?? 0,
    );
  }
}

class UserActivityItem {
  const UserActivityItem({
    required this.id,
    required this.sport,
    required this.type,
    this.loggedAt,
    this.matchOutcome,
    this.durationMinutes,
  });

  final String id;
  final String sport;
  final String type;
  final DateTime? loggedAt;
  final String? matchOutcome;
  final int? durationMinutes;

  factory UserActivityItem.fromJson(Map<String, dynamic> json) {
    return UserActivityItem(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      sport: json['sport'] as String? ?? '',
      type: json['type'] as String? ?? '',
      loggedAt: json['loggedAt'] != null
          ? DateTime.tryParse(json['loggedAt'] as String)
          : null,
      matchOutcome: json['matchOutcome'] as String?,
      durationMinutes: json['durationMinutes'] as int?,
    );
  }
}

class UserUpcomingGame {
  const UserUpcomingGame({
    required this.id,
    required this.title,
    required this.sport,
    this.scheduledAt,
    this.status,
  });

  final String id;
  final String title;
  final String sport;
  final DateTime? scheduledAt;
  final String? status;

  factory UserUpcomingGame.fromJson(Map<String, dynamic> json) {
    return UserUpcomingGame(
      id: (json['_id'] ?? json['id'])?.toString() ?? '',
      title: json['title'] as String? ?? '',
      sport: json['sport'] as String? ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.tryParse(json['scheduledAt'] as String)
          : null,
      status: json['status'] as String?,
    );
  }
}
