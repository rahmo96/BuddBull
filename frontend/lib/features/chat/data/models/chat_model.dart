import 'package:equatable/equatable.dart';

// ── ChatParticipant ───────────────────────────────────────────────────────────
class ChatParticipant extends Equatable {
  final String userId;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? profilePicture;
  final bool isAdmin;
  final bool isMuted;
  final DateTime? lastReadAt;

  const ChatParticipant({
    required this.userId,
    required this.username,
    this.firstName,
    this.lastName,
    this.profilePicture,
    this.isAdmin = false,
    this.isMuted = false,
    this.lastReadAt,
  });

  String get displayName {
    final full = [firstName, lastName].where((s) => s != null && s.isNotEmpty).join(' ');
    return full.isNotEmpty ? full : username;
  }

  factory ChatParticipant.fromJson(Map<String, dynamic> json) {
    final user = json['user'] is Map ? json['user'] as Map<String, dynamic> : json;
    return ChatParticipant(
      userId: (user['_id'] ?? user['id'] ?? '').toString(),
      username: (user['username'] ?? '').toString(),
      firstName: user['firstName']?.toString(),
      lastName: user['lastName']?.toString(),
      profilePicture: user['profilePicture']?.toString(),
      isAdmin: json['isAdmin'] == true,
      isMuted: json['isMuted'] == true,
      lastReadAt: json['lastReadAt'] != null ? DateTime.tryParse(json['lastReadAt'].toString()) : null,
    );
  }

  @override
  List<Object?> get props => [userId, username, isAdmin];
}

// ── LastMessage preview ───────────────────────────────────────────────────────
class LastMessagePreview extends Equatable {
  final String? senderId;
  final String content;
  final DateTime sentAt;

  const LastMessagePreview({this.senderId, required this.content, required this.sentAt});

  factory LastMessagePreview.fromJson(Map<String, dynamic> json) => LastMessagePreview(
        senderId: (json['sender'] is Map ? json['sender']['_id'] : json['sender'])?.toString(),
        content: (json['content'] ?? '').toString(),
        sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? '') ?? DateTime.now(),
      );

  @override
  List<Object?> get props => [senderId, content, sentAt];
}

// ── PinnedMessage (lightweight) ───────────────────────────────────────────────
class PinnedMessage extends Equatable {
  final String id;
  final String content;
  final String type;
  final Map<String, dynamic>? sender;
  final DateTime? createdAt;

  const PinnedMessage({
    required this.id,
    required this.content,
    required this.type,
    this.sender,
    this.createdAt,
  });

  factory PinnedMessage.fromJson(Map<String, dynamic> json) => PinnedMessage(
        id: (json['_id'] ?? json['id'] ?? '').toString(),
        content: (json['content'] ?? '').toString(),
        type: (json['type'] ?? 'text').toString(),
        sender: json['sender'] is Map ? json['sender'] as Map<String, dynamic> : null,
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? ''),
      );

  String get senderName {
    if (sender == null) return '';
    final full = [sender!['firstName'], sender!['lastName']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    return full.isNotEmpty ? full : (sender!['username'] ?? '').toString();
  }

  @override
  List<Object?> get props => [id];
}

// ── MessageModel ──────────────────────────────────────────────────────────────
class MessageModel extends Equatable {
  final String id;
  final String chatId;
  final Map<String, dynamic>? sender;
  final String type;
  final String content;
  final MessageModel? replyTo;
  final Map<String, int> reactions;
  final bool isPinned;
  final bool isDeleted;
  final DateTime sentAt;
  final bool isEdited;

  const MessageModel({
    required this.id,
    required this.chatId,
    this.sender,
    required this.type,
    required this.content,
    this.replyTo,
    this.reactions = const {},
    this.isPinned = false,
    this.isDeleted = false,
    required this.sentAt,
    this.isEdited = false,
  });

  String get senderId => (sender?['_id'] ?? sender?['id'] ?? '').toString();
  String get senderName {
    if (sender == null) return '';
    final full = [sender!['firstName'], sender!['lastName']]
        .where((s) => s != null && s.toString().isNotEmpty)
        .join(' ');
    return full.isNotEmpty ? full : (sender!['username'] ?? '').toString();
  }
  String? get senderPicture => sender?['profilePicture']?.toString();
  String get displayContent => isDeleted ? 'Message deleted' : content;

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    final reactionsRaw = json['reactions'];
    final Map<String, int> reactions = {};
    if (reactionsRaw is Map) {
      reactionsRaw.forEach((k, v) => reactions[k.toString()] = (v as num).toInt());
    }
    return MessageModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      chatId: (json['chatId'] ?? json['chat'] ?? '').toString(),
      sender: json['sender'] is Map ? json['sender'] as Map<String, dynamic> : null,
      type: (json['type'] ?? 'text').toString(),
      content: (json['content'] ?? '').toString(),
      replyTo: json['replyTo'] is Map
          ? MessageModel.fromJson(json['replyTo'] as Map<String, dynamic>)
          : null,
      reactions: reactions,
      isPinned: json['isPinned'] == true,
      isDeleted: json['isDeleted'] == true,
      sentAt: DateTime.tryParse(json['sentAt']?.toString() ?? json['createdAt']?.toString() ?? '') ?? DateTime.now(),
      isEdited: json['isEdited'] == true,
    );
  }

  @override
  List<Object?> get props => [id, content, isPinned, isDeleted, reactions];
}

// ── ChatModel ─────────────────────────────────────────────────────────────────
class ChatModel extends Equatable {
  final String id;
  final String type; // group | dm
  final String? name;
  final String? description;
  final String? avatar;
  final String? gameId;
  final String? gameTitle;
  final List<ChatParticipant> participants;
  final LastMessagePreview? lastMessage;
  final List<PinnedMessage> pinnedMessages;
  final int messageCount;
  final int unreadCount;
  final bool isMuted;
  final bool isAdmin;
  final DateTime? lastReadAt;
  final DateTime? updatedAt;

  const ChatModel({
    required this.id,
    required this.type,
    this.name,
    this.description,
    this.avatar,
    this.gameId,
    this.gameTitle,
    this.participants = const [],
    this.lastMessage,
    this.pinnedMessages = const [],
    this.messageCount = 0,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isAdmin = false,
    this.lastReadAt,
    this.updatedAt,
  });

  /// For DMs, return the other participant's display name
  String chatTitle(String currentUserId) {
    if (type == 'dm') {
      final other = participants.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => participants.isNotEmpty ? participants.first : const ChatParticipant(userId: '', username: 'Unknown'),
      );
      return other.displayName;
    }
    return name ?? 'Group Chat';
  }

  String? chatAvatar(String currentUserId) {
    if (type == 'dm') {
      final other = participants.firstWhere(
        (p) => p.userId != currentUserId,
        orElse: () => participants.isNotEmpty ? participants.first : const ChatParticipant(userId: '', username: ''),
      );
      return other.profilePicture;
    }
    return avatar;
  }

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    final gameRaw = json['game'];
    String? gameId;
    String? gameTitle;
    if (gameRaw is Map) {
      gameId = (gameRaw['_id'] ?? gameRaw['id'])?.toString();
      gameTitle = gameRaw['title']?.toString();
    } else if (gameRaw is String) {
      gameId = gameRaw;
    }

    final pinnedRaw = json['pinnedMessages'] as List? ?? [];
    final pinnedMessages = pinnedRaw
        .whereType<Map<String, dynamic>>()
        .map(PinnedMessage.fromJson)
        .toList();

    final participantsRaw = json['participants'] as List? ?? [];
    final participants = participantsRaw
        .whereType<Map<String, dynamic>>()
        .map(ChatParticipant.fromJson)
        .toList();

    return ChatModel(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: (json['type'] ?? 'group').toString(),
      name: json['name']?.toString(),
      description: json['description']?.toString(),
      avatar: json['avatar']?.toString(),
      gameId: gameId,
      gameTitle: gameTitle,
      participants: participants,
      lastMessage: json['lastMessage'] is Map
          ? LastMessagePreview.fromJson(json['lastMessage'] as Map<String, dynamic>)
          : null,
      pinnedMessages: pinnedMessages,
      messageCount: (json['messageCount'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unreadCount'] as num?)?.toInt() ?? 0,
      isMuted: json['isMuted'] == true,
      isAdmin: json['isAdmin'] == true,
      lastReadAt: DateTime.tryParse(json['lastReadAt']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updatedAt']?.toString() ?? ''),
    );
  }

  @override
  List<Object?> get props => [id, lastMessage, unreadCount, pinnedMessages];
}
