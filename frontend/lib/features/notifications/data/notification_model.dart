import 'package:equatable/equatable.dart';

/// Mirrors the backend `Notification` schema (`backend/src/models/Notification.model.js`).
///
/// Keep the field list in sync with the Mongoose document — but stay
/// tolerant of unknown `type` values so a new server-side category can
/// roll out without forcing a client release.
class NotificationModel extends Equatable {
  const NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.read,
    required this.createdAt,
    this.data = const <String, dynamic>{},
    this.readAt,
  });

  final String id;

  /// Server-side enum (`gameInvite`, `ratingPending`, `system`, …).
  /// Stored as a raw string so unknown values from a newer backend
  /// don't crash the client.
  final String type;
  final String title;
  final String body;
  final bool read;
  final DateTime createdAt;
  final DateTime? readAt;

  /// Free-form navigation payload — examples:
  ///   { 'gameId': '...' }, { 'chatId': '...' }, { 'userId': '...' }.
  final Map<String, dynamic> data;

  // ── Convenience ────────────────────────────────────────────────────────────
  bool get isUnread => !read;

  String? get gameId => data['gameId']?.toString();
  String? get chatId => data['chatId']?.toString();
  String? get userId => data['userId']?.toString();

  // ── Serialisation ──────────────────────────────────────────────────────────
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    return NotificationModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'system').toString(),
      title: (json['title'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      read: json['read'] == true,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ??
          DateTime.now(),
      readAt: json['readAt'] != null
          ? DateTime.tryParse(json['readAt'].toString())
          : null,
      data: rawData is Map
          ? Map<String, dynamic>.from(rawData)
          : const <String, dynamic>{},
    );
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'type': type,
        'title': title,
        'body': body,
        'read': read,
        'createdAt': createdAt.toIso8601String(),
        if (readAt != null) 'readAt': readAt!.toIso8601String(),
        'data': data,
      };

  NotificationModel copyWith({
    bool? read,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      body: body,
      read: read ?? this.read,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
      data: data,
    );
  }

  @override
  List<Object?> get props => [id, read, readAt];
}

/// Wraps the `/notifications` list response so the provider can drive
/// both the list view and the badge from a single network round-trip.
class NotificationPage extends Equatable {
  const NotificationPage({
    required this.notifications,
    required this.unreadCount,
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  final List<NotificationModel> notifications;
  final int unreadCount;
  final int total;
  final int page;
  final int limit;
  final int pages;

  factory NotificationPage.fromJson(Map<String, dynamic> json) {
    final list = (json['notifications'] as List? ?? [])
        .whereType<Map<String, dynamic>>()
        .map(NotificationModel.fromJson)
        .toList();

    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};

    return NotificationPage(
      notifications: list,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      total: (pagination['total'] as num?)?.toInt() ?? list.length,
      page: (pagination['page'] as num?)?.toInt() ?? 1,
      limit: (pagination['limit'] as num?)?.toInt() ?? list.length,
      pages: (pagination['pages'] as num?)?.toInt() ?? 1,
    );
  }

  static const empty = NotificationPage(
    notifications: <NotificationModel>[],
    unreadCount: 0,
    total: 0,
    page: 1,
    limit: 50,
    pages: 1,
  );

  @override
  List<Object?> get props => [notifications, unreadCount, total, page];
}
