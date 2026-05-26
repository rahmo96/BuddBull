import 'dart:async';

import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/services/socket_service.dart';
import 'package:buddbull/features/chat/data/chat_repository.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

/// Chat room currently open on [ChatScreen]. [PushNotificationService] uses this
/// to ignore foreground FCM payloads for the active room (socket already delivers).
final activeChatRoomProvider = StateProvider<String?>((ref) => null);

// ── Chat list ─────────────────────────────────────────────────────────────────
final chatListProvider = FutureProvider<List<ChatModel>>((ref) async {
  return ref.watch(chatRepositoryProvider).getChats();
});

// ── Unread counters ───────────────────────────────────────────────────────────
//
// Per-chat unread counts + a derived total used by the bottom-nav badge.
// Hydrated from `/chats` (which now ships `unreadCount` per row) and kept
// live via the `chat:unread_update` socket event. `markChatRead` drops a
// given chat's count to zero immediately when the user opens that chat.
class ChatUnreadNotifier extends StateNotifier<Map<String, int>> {
  ChatUnreadNotifier(this._ref) : super(const {}) {
    _socketSub = _ref
        .read(socketServiceProvider)
        .chatUnreadStream
        .listen(_onUnreadEvent);
    _bootstrap();
  }

  final Ref _ref;
  StreamSubscription<ChatUnreadUpdateEvent>? _socketSub;

  /// Sum across every chat — drives the BottomNavigationBar badge.
  int get totalUnread =>
      state.values.fold<int>(0, (sum, n) => sum + (n > 0 ? n : 0));

  Future<void> _bootstrap() async {
    try {
      final chats = await _ref.read(chatRepositoryProvider).getChats();
      state = {
        for (final c in chats) c.id: c.unreadCount,
      };
    } catch (_) {
      // Soft-fail: socket events still keep us live until the next pull.
    }
  }

  void _onUnreadEvent(ChatUnreadUpdateEvent e) {
    state = {
      ...state,
      e.chatId: (state[e.chatId] ?? 0) + 1,
    };
  }

  /// Drop the badge for `chatId` to zero — called when the user opens
  /// the room. The server-side `getChatById` already stamps `lastReadAt`.
  void markChatRead(String chatId) {
    if ((state[chatId] ?? 0) == 0) return;
    state = {...state, chatId: 0};
  }

  /// Force a re-fetch (e.g. after the user pulls to refresh the chat list).
  Future<void> refresh() => _bootstrap();

  @override
  void dispose() {
    _socketSub?.cancel();
    super.dispose();
  }
}

final chatUnreadProvider =
    StateNotifierProvider<ChatUnreadNotifier, Map<String, int>>((ref) {
  return ChatUnreadNotifier(ref);
});

/// Total badge count for the bottom-nav chat icon.
final totalUnreadChatCountProvider = Provider<int>((ref) {
  final counts = ref.watch(chatUnreadProvider);
  return counts.values.fold<int>(0, (sum, n) => sum + (n > 0 ? n : 0));
});

// ── Single chat detail ────────────────────────────────────────────────────────
final chatDetailProvider = FutureProvider.family<ChatModel, String>((ref, chatId) async {
  return ref.watch(chatRepositoryProvider).getChatById(chatId);
});

// ── Messages state for a chat ─────────────────────────────────────────────────
class MessagesState {
  final List<MessageModel> messages;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? error;

  const MessagesState({
    this.messages = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.error,
  });

  MessagesState copyWith({
    List<MessageModel>? messages,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? error,
  }) =>
      MessagesState(
        messages: messages ?? this.messages,
        isLoading: isLoading ?? this.isLoading,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        hasMore: hasMore ?? this.hasMore,
        error: error,
      );
}

class MessagesNotifier extends StateNotifier<MessagesState> {
  static final _log = Logger();

  final ChatRepository _repo;
  final SocketService _socket;
  final String chatId;

  StreamSubscription<dynamic>? _msgSub;
  StreamSubscription<MessageDeletedEvent>? _delSub;
  StreamSubscription<MessagePinnedEvent>? _pinSub;
  StreamSubscription<ChatAccessRevokedEvent>? _accessSub;

  /// After server revokes chat access, ignore further socket payloads for this room.
  bool _accessRevoked = false;
  final Set<String> _seenMessageIds = <String>{};

  int _page = 1;
  static const int _limit = 30;

  MessagesNotifier(this._repo, this._socket, this.chatId) : super(const MessagesState()) {
    _init();
  }

  Future<void> _init() async {
    // Join the socket room and load initial messages
    _socket.joinChat(chatId);

    // Subscribe to real-time events
    _msgSub = _socket.messageStream.listen(_onSocketMessagePayload);

    _delSub = _socket.deletedStream.listen((event) {
      _replaceMessage(event.messageId, (m) => MessageModel(
            id: m.id,
            chatId: m.chatId,
            sender: m.sender,
            type: m.type,
            content: 'Message deleted',
            reactions: m.reactions,
            isPinned: m.isPinned,
            isDeleted: true,
            sentAt: m.sentAt,
          ));
    });

    _pinSub = _socket.pinnedStream.listen((event) {
      _replaceMessage(event.messageId, (m) => MessageModel(
            id: m.id,
            chatId: m.chatId,
            sender: m.sender,
            type: m.type,
            content: m.content,
            reactions: m.reactions,
            isPinned: event.isPinned,
            isDeleted: m.isDeleted,
            sentAt: m.sentAt,
          ));
    });

    _accessSub = _socket.chatAccessRevokedStream.listen((event) {
      if (event.chatId != chatId) return;
      _accessRevoked = true;
      _socket.leaveChat(chatId);
      _seenMessageIds.clear();
      state = const MessagesState(
        messages: [],
        isLoading: false,
        isLoadingMore: false,
        hasMore: false,
        error: null,
      );
    });

    await loadMessages();
    if (state.messages.isNotEmpty) {
      _socket.markAsRead(chatId, state.messages.last.id);
    }
  }

  Future<void> loadMessages() async {
    if (_accessRevoked) return;
    state = state.copyWith(isLoading: true, error: null);
    try {
      _page = 1;
      final msgs = await _repo.getMessages(chatId, page: _page, limit: _limit);
      if (_accessRevoked) return;
      _seenMessageIds
        ..clear()
        ..addAll(msgs.map((m) => m.id));
      state = state.copyWith(
        messages: msgs,
        isLoading: false,
        hasMore: msgs.length == _limit,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || _accessRevoked) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      _page++;
      final firstMsgTime = state.messages.isNotEmpty ? state.messages.first.sentAt.toIso8601String() : null;
      final older = await _repo.getMessages(chatId, page: _page, limit: _limit, before: firstMsgTime);
      _seenMessageIds.addAll(older.map((m) => m.id));
      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoadingMore: false,
        hasMore: older.length == _limit,
      );
    } catch (_) {
      _page--;
      state = state.copyWith(isLoadingMore: false);
    }
  }

  /// Connected: socket only (server persists + echoes). Offline: HTTP POST fallback.
  Future<void> sendMessage(String content, {String? replyToId}) async {
    if (_accessRevoked) return;

    if (_socket.status == SocketStatus.connected) {
      _socket.sendMessage(chatId, content, replyToId: replyToId);
      return;
    }

    try {
      final msg = await _repo.sendMessage(chatId, content, replyToId: replyToId);
      _handleIncoming(msg);
    } catch (_) {}
  }

  void startTyping() => _socket.startTyping(chatId);
  void stopTyping() => _socket.stopTyping(chatId);

  /// Cheap chat filter + defer JSON parsing so socket bursts don't block frames.
  void _onSocketMessagePayload(dynamic data) {
    if (_accessRevoked) return;
    if (data == null || data is! Map) return;
    final Map<String, dynamic> d;
    try {
      d = Map<String, dynamic>.from(data);
    } catch (e, st) {
      _log.w('SOCKET message payload map cast failed', error: e, stackTrace: st);
      return;
    }
    final raw = (d['message'] is Map)
        ? Map<String, dynamic>.from(d['message'] as Map)
        : d;
    final incomingChatId = (raw['chat'] ?? raw['chatId'])?.toString();
    if (incomingChatId != chatId) return;

    Future.microtask(() {
      try {
        final msg = MessageModel.fromJson(raw);
        _handleIncoming(msg);
      } catch (e, st) {
        _log.w('SOCKET message fromJson failed', error: e, stackTrace: st);
      }
    });
  }

  void _replaceMessage(String messageId, MessageModel Function(MessageModel m) builder) {
    final list = state.messages;
    final idx = list.indexWhere((m) => m.id == messageId);
    if (idx < 0) return;
    final next = [...list];
    next[idx] = builder(list[idx]);
    state = state.copyWith(messages: next);
  }

  static const Duration _dedupeWindow = Duration(seconds: 2);

  /// Same sender + body within [_dedupeWindow] (HTTP vs socket race, missing ids).
  bool _isRecentContentDuplicate(MessageModel msg) {
    if (msg.content.isEmpty) return false;
    final senderId = msg.senderId;
    if (senderId.isEmpty) return false;

    final now = DateTime.now();
    final windowStart = now.subtract(_dedupeWindow);

    for (final m in state.messages) {
      if (m.content != msg.content || m.senderId != senderId) continue;

      if (!m.sentAt.isBefore(windowStart)) return true;

      if (m.sentAt.difference(msg.sentAt).abs() <= _dedupeWindow) return true;
    }
    return false;
  }

  String _messageDedupeKey(MessageModel msg) {
    if (msg.id.isNotEmpty) return msg.id;
    final bucket = msg.sentAt.millisecondsSinceEpoch ~/ 1000;
    return 'content:${msg.senderId}:${msg.content}:$bucket';
  }

  void _handleIncoming(MessageModel msg) {
    if (_isRecentContentDuplicate(msg)) return;

    final dedupeKey = _messageDedupeKey(msg);
    if (_seenMessageIds.contains(dedupeKey)) return;

    final messageId = msg.id;
    if (messageId.isNotEmpty && state.messages.any((m) => m.id == messageId)) {
      _seenMessageIds.add(dedupeKey);
      return;
    }

    _seenMessageIds.add(dedupeKey);

    state = state.copyWith(messages: [...state.messages, msg]);

    _log.d(
      'Chat message appended '
      'chatId=$chatId '
      'messageId=${messageId.isEmpty ? dedupeKey : messageId} '
      'senderId=${msg.senderId}',
    );

    if (messageId.isNotEmpty) {
      _socket.markAsRead(chatId, messageId);
    }
  }

  @override
  void dispose() {
    _socket.leaveChat(chatId);
    _msgSub?.cancel();
    _delSub?.cancel();
    _pinSub?.cancel();
    _accessSub?.cancel();
    super.dispose();
  }
}

final messagesProvider = StateNotifierProvider.family<MessagesNotifier, MessagesState, String>(
  (ref, chatId) => MessagesNotifier(
    ref.watch(chatRepositoryProvider),
    ref.watch(socketServiceProvider),
    chatId,
  ),
);

// ── Typing indicator state ────────────────────────────────────────────────────
class TypingState {
  final Set<String> typingUsernames;
  const TypingState({this.typingUsernames = const {}});
}

class TypingNotifier extends StateNotifier<TypingState> {
  final SocketService _socket;
  final String chatId;
  StreamSubscription<TypingEvent>? _sub;
  StreamSubscription<ChatAccessRevokedEvent>? _accessSub;

  TypingNotifier(this._socket, this.chatId) : super(const TypingState()) {
    _sub = _socket.typingStream.where((e) => e.chatId == chatId).listen((event) {
      if (event.isTyping) {
        state = TypingState(typingUsernames: {...state.typingUsernames, event.username});
      } else {
        final updated = {...state.typingUsernames}..remove(event.username);
        state = TypingState(typingUsernames: updated);
      }
    });

    _accessSub = _socket.chatAccessRevokedStream.listen((event) {
      if (event.chatId != chatId) return;
      state = const TypingState();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _accessSub?.cancel();
    super.dispose();
  }
}

final typingProvider = StateNotifierProvider.family<TypingNotifier, TypingState, String>(
  (ref, chatId) => TypingNotifier(ref.watch(socketServiceProvider), chatId),
);

// ── DM creation ───────────────────────────────────────────────────────────────
class CreateDmState {
  final bool isLoading;
  final ChatModel? chat;
  final String? error;
  const CreateDmState({this.isLoading = false, this.chat, this.error});
}

class CreateDmNotifier extends StateNotifier<CreateDmState> {
  final ChatRepository _repo;
  CreateDmNotifier(this._repo) : super(const CreateDmState());

  Future<ChatModel?> createDM(String recipientId) async {
    state = const CreateDmState(isLoading: true);
    try {
      final chat = await _repo.createOrGetDM(recipientId);
      state = CreateDmState(chat: chat);
      return chat;
    } catch (e) {
      state = CreateDmState(error: e.toString());
      return null;
    }
  }
}

final createDmProvider = StateNotifierProvider.autoDispose<CreateDmNotifier, CreateDmState>(
  (ref) => CreateDmNotifier(ref.watch(chatRepositoryProvider)),
);
