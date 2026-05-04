import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/services/socket_service.dart';
import 'package:buddbull/features/chat/data/chat_repository.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';

// ── Repository provider ───────────────────────────────────────────────────────
final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  return ChatRepository(ref.watch(apiClientProvider));
});

// ── Chat list ─────────────────────────────────────────────────────────────────
final chatListProvider = FutureProvider<List<ChatModel>>((ref) async {
  return ref.watch(chatRepositoryProvider).getChats();
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
  final ChatRepository _repo;
  final SocketService _socket;
  final String chatId;

  StreamSubscription<MessageModel>? _msgSub;
  StreamSubscription<MessageDeletedEvent>? _delSub;
  StreamSubscription<MessagePinnedEvent>? _pinSub;

  int _page = 1;
  static const int _limit = 30;

  MessagesNotifier(this._repo, this._socket, this.chatId) : super(const MessagesState()) {
    _init();
  }

  Future<void> _init() async {
    // Join the socket room and load initial messages
    _socket.joinChat(chatId);

    // Subscribe to real-time events
    _msgSub = _socket.messageStream
        .where((m) => m.chatId == chatId)
        .listen(_handleIncoming);

    _delSub = _socket.deletedStream.listen((event) {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id != event.messageId) return m;
          return MessageModel(
            id: m.id,
            chatId: m.chatId,
            sender: m.sender,
            type: m.type,
            content: 'Message deleted',
            reactions: m.reactions,
            isPinned: m.isPinned,
            isDeleted: true,
            sentAt: m.sentAt,
          );
        }).toList(),
      );
    });

    _pinSub = _socket.pinnedStream.listen((event) {
      state = state.copyWith(
        messages: state.messages.map((m) {
          if (m.id != event.messageId) return m;
          return MessageModel(
            id: m.id,
            chatId: m.chatId,
            sender: m.sender,
            type: m.type,
            content: m.content,
            reactions: m.reactions,
            isPinned: event.isPinned,
            isDeleted: m.isDeleted,
            sentAt: m.sentAt,
          );
        }).toList(),
      );
    });

    await loadMessages();
  }

  Future<void> loadMessages() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      _page = 1;
      final msgs = await _repo.getMessages(chatId, page: _page, limit: _limit);
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
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    try {
      _page++;
      final firstMsgTime = state.messages.isNotEmpty ? state.messages.first.sentAt.toIso8601String() : null;
      final older = await _repo.getMessages(chatId, page: _page, limit: _limit, before: firstMsgTime);
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

  /// Send via socket (real-time); falls back to HTTP if disconnected
  Future<void> sendMessage(String content, {String? replyToId}) async {
    if (_socket.status == SocketStatus.connected) {
      _socket.sendMessage(chatId, content, replyToId: replyToId);
    } else {
      try {
        final msg = await _repo.sendMessage(chatId, content, replyToId: replyToId);
        _handleIncoming(msg);
      } catch (_) {}
    }
  }

  void startTyping() => _socket.startTyping(chatId);
  void stopTyping() => _socket.stopTyping(chatId);

  void _handleIncoming(MessageModel msg) {
    // Avoid duplicates
    if (state.messages.any((m) => m.id == msg.id)) return;
    state = state.copyWith(messages: [...state.messages, msg]);
  }

  @override
  void dispose() {
    _socket.leaveChat(chatId);
    _msgSub?.cancel();
    _delSub?.cancel();
    _pinSub?.cancel();
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

  TypingNotifier(this._socket, this.chatId) : super(const TypingState()) {
    _sub = _socket.typingStream.where((e) => e.chatId == chatId).listen((event) {
      if (event.isTyping) {
        state = TypingState(typingUsernames: {...state.typingUsernames, event.username});
      } else {
        final updated = {...state.typingUsernames}..remove(event.username);
        state = TypingState(typingUsernames: updated);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
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
