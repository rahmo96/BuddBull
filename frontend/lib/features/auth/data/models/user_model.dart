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
