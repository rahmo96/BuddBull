import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logger/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// Socket.IO origin — mirrors `--dart-define=API_BASE_URL` with `/api/v1` stripped.
final String _socketUrl = const String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://178.105.65.91:8000/api/v1',
).replaceAll('/api/v1', '');

// ── Event data types ──────────────────────────────────────────────────────────
class TypingEvent {
  final String chatId;
  final String userId;
  final String username;
  final bool isTyping;

  const TypingEvent({
    required this.chatId,
    required this.userId,
    required this.username,
    required this.isTyping,
  });
}

class MessageDeletedEvent {
  final String messageId;
  const MessageDeletedEvent(this.messageId);
}

class MessagePinnedEvent {
  final String messageId;
  final bool isPinned;
  const MessagePinnedEvent(this.messageId, {this.isPinned = true});
}

/// Server fan-out from `send_message`: tells the recipient their badge
/// should increment for `chatId`. Carries enough context (preview + timestamp)
/// for the chat list to refresh inline without a full HTTP round-trip.
class ChatUnreadUpdateEvent {
  final String chatId;
  final String? messageId;
  final String? preview;
  final DateTime? sentAt;
  final String? senderId;

  const ChatUnreadUpdateEvent({
    required this.chatId,
    this.messageId,
    this.preview,
    this.sentAt,
    this.senderId,
  });
}

/// Server revoked this user's access to a chat room (left game, kicked, etc.).
class ChatAccessRevokedEvent {
  final String chatId;
  final String? gameId;
  /// `kicked`, `left`, or `denied` (for `room_access_denied`).
  final String reason;
  final String? detail;

  const ChatAccessRevokedEvent({
    required this.chatId,
    this.gameId,
    required this.reason,
    this.detail,
  });
}

// ── Socket connection status ──────────────────────────────────────────────────
enum SocketStatus { disconnected, connecting, connected, error }

// ── SocketService ─────────────────────────────────────────────────────────────
class SocketService {
  io.Socket? _socket;
  final Set<String> _joinedChats = <String>{};
  StreamSubscription<User?>? _authSub;
  String? _lastToken;
  final Logger _log = Logger();

  /// Prevents overlapping [connect] handshakes from auth + shell.
  bool _connectInProgress = false;

  /// Bumped on [disconnect] / teardown so in-flight [connect] aborts safely.
  int _connectGeneration = 0;

  // ── Broadcast streams ──────────────────────────────────────────────────────
  // Raw socket payloads for debugging + provider-side parsing. We keep
  // `SocketService` domain-agnostic — feature notifiers parse the JSON
  // Map into their own typed models so this file never has to import
  // every feature package.
  final _messageController = StreamController<dynamic>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _deletedController = StreamController<MessageDeletedEvent>.broadcast();
  final _pinnedController = StreamController<MessagePinnedEvent>.broadcast();
  final _statusController = StreamController<SocketStatus>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();
  final _chatAccessRevokedController =
      StreamController<ChatAccessRevokedEvent>.broadcast();
  final _chatUnreadController =
      StreamController<ChatUnreadUpdateEvent>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<MessageDeletedEvent> get deletedStream => _deletedController.stream;
  Stream<MessagePinnedEvent> get pinnedStream => _pinnedController.stream;
  Stream<SocketStatus> get statusStream => _statusController.stream;

  /// Raw `notification:new` payloads pushed by the server when a new
  /// inbox row is persisted for the current user. Subscribers are
  /// responsible for parsing via `NotificationModel.fromJson`.
  Stream<Map<String, dynamic>> get notificationStream =>
      _notificationController.stream;

  /// Fired when the server closes the user's chat membership (leave/kick).
  Stream<ChatAccessRevokedEvent> get chatAccessRevokedStream =>
      _chatAccessRevokedController.stream;

  /// Fired for every new message in a chat the user participates in
  /// (sender is filtered out server-side).
  Stream<ChatUnreadUpdateEvent> get chatUnreadStream =>
      _chatUnreadController.stream;

  SocketStatus _status = SocketStatus.disconnected;
  SocketStatus get status => _status;

  SocketService() {
    _authSub = FirebaseAuth.instance.idTokenChanges().listen((user) async {
      if (user == null) {
        _lastToken = null;
        disconnect();
        return;
      }

      String? token;
      try {
        token = await user.getIdToken();
      } catch (_) {
        return;
      }
      if (token == null || token == _lastToken) return;
      _lastToken = token;

      // Re-handshake with the refreshed Firebase token (guarded inside connect).
      await connect();
    });
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (_socket?.connected == true) {
      debugPrint(
        '⚪ SOCKET connect skipped — already connected (${_socket?.id})',
      );
      return;
    }

    if (_connectInProgress) {
      debugPrint('⚪ SOCKET connect skipped — handshake already in progress');
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      // Expected when logged out or in widget tests without a signed-in user.
      return;
    }

    _connectInProgress = true;
    final generation = ++_connectGeneration;

    try {
      _tearDownSocket();

      String? token;
      try {
        token = await FirebaseAuth.instance.currentUser?.getIdToken();
      } on FirebaseAuthException catch (e, st) {
        debugPrint(
          '❌ SOCKET abort — FirebaseAuthException getting token: $e\n$st',
        );
        try {
          await FirebaseAuth.instance.signOut();
        } catch (_) {}
        return;
      } catch (e, st) {
        debugPrint('❌ SOCKET abort — error getting token: $e\n$st');
        return;
      }

      if (token == null) return;
      if (generation != _connectGeneration) return;

      _lastToken = token;
      _setStatus(SocketStatus.connecting);

      final serverUrl = _socketUrl;
      debugPrint('🟡 SOCKET handshake → $serverUrl');

      io.Socket socket;
      try {
        socket = io.io(
          serverUrl,
          io.OptionBuilder()
              .setTransports(['websocket'])
              .enableForceNew()
              .enableReconnection()
              .setAuth({'token': token})
              // Must defer connect until handlers below are attached.
              .disableAutoConnect()
              .build(),
        );
      } catch (e, st) {
        debugPrint('❌ SOCKET io.io() failed: $e\n$st');
        _setStatus(SocketStatus.error);
        return;
      }

      if (generation != _connectGeneration) {
        _disposeSocketInstance(socket);
        return;
      }

      _socket = socket;
      _attachSocketListeners(socket);

      debugPrint('🟡 SOCKET calling connect()…');
      socket.connect();
    } finally {
      _connectInProgress = false;
    }
  }

  // ── Room management ───────────────────────────────────────────────────────
  void joinChat(String chatId) {
    debugPrint('🔵 SOCKET EMITTING JOIN ROOM: $chatId');
    _joinedChats.add(chatId);
    final socket = _socket;
    if (socket == null || socket.connected != true) return;
    socket.emit('join_chat', <String, dynamic>{'chatId': chatId});
  }

  void leaveChat(String chatId) {
    _joinedChats.remove(chatId);
    _emit('leave_chat', {'chatId': chatId});
  }

  void markAsRead(String chatId, String lastMessageId) =>
      _emit('markAsRead', {'chatId': chatId, 'lastMessageId': lastMessageId});

  // ── Messaging ─────────────────────────────────────────────────────────────
  void sendMessage(String chatId, String content,
      {String type = 'text', String? replyToId}) {
    _emit('send_message', {
      'chatId': chatId,
      'content': content,
      'type': type,
      if (replyToId != null) 'replyTo': replyToId,
    });
  }

  // ── Typing ────────────────────────────────────────────────────────────────
  void startTyping(String chatId) => _emit('typing', {'chatId': chatId});
  void stopTyping(String chatId) => _emit('stop_typing', {'chatId': chatId});

  // ── Admin actions ─────────────────────────────────────────────────────────
  void pinMessage(String chatId, String messageId) =>
      _emit('pin_message', {'chatId': chatId, 'messageId': messageId});

  void deleteMessage(String messageId) =>
      _emit('delete_message', {'messageId': messageId});

  // ── Disconnect ────────────────────────────────────────────────────────────
  void disconnect() {
    _connectGeneration++;
    _connectInProgress = false;
    _tearDownSocket();
    _setStatus(SocketStatus.disconnected);
  }

  // ── Dispose ───────────────────────────────────────────────────────────────
  void dispose() {
    _authSub?.cancel();
    _authSub = null;
    disconnect();
    _messageController.close();
    _typingController.close();
    _deletedController.close();
    _pinnedController.close();
    _statusController.close();
    _notificationController.close();
    _chatAccessRevokedController.close();
    _chatUnreadController.close();
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _tearDownSocket() {
    final socket = _socket;
    _socket = null;
    if (socket == null) return;

    debugPrint('⚪ SOCKET tearing down stale instance (${socket.id})');
    _disposeSocketInstance(socket);
  }

  void _disposeSocketInstance(io.Socket socket) {
    try {
      if (socket.connected) {
        socket.disconnect();
      }
    } catch (e, st) {
      _log.w('SOCKET disconnect error', error: e, stackTrace: st);
    }
    try {
      socket.dispose();
    } catch (e, st) {
      _log.w('SOCKET dispose error', error: e, stackTrace: st);
    }
  }

  void _attachSocketListeners(io.Socket socket) {
    socket
      ..onConnect((_) {
        final active = _socket;
        if (active == null || active.connected != true) return;

        debugPrint('🟢 SOCKET CONNECTED: ${active.id}');
        _setStatus(SocketStatus.connected);

        // Re-join rooms after reconnect — contract: `{ 'chatId': chatId }`.
        final s = _socket;
        if (s == null || s.connected != true) return;
        for (final chatId in _joinedChats) {
          s.emit('join_chat', <String, dynamic>{'chatId': chatId});
        }
      })
      ..onDisconnect((_) {
        debugPrint('🔴 SOCKET DISCONNECTED');
        _setStatus(SocketStatus.disconnected);
      })
      ..onConnectError((err) {
        debugPrint('❌ SOCKET ERROR: $err');
        _setStatus(SocketStatus.error);
      })
      ..on('messageRead', (data) {
        // Handled in provider via socket raw if needed.
      })
      ..on('typing', (data) => _handleTypingEvent(data, isTyping: true))
      ..on('stop_typing', (data) => _handleTypingEvent(data, isTyping: false))
      ..on('message_deleted', _handleMessageDeleted)
      ..on('message_pinned', (data) => _handleMessagePinned(data, isPinned: true))
      ..on('message_unpinned', (data) => _handleMessagePinned(data, isPinned: false))
      ..on('receive_message', _handleReceiveMessage)
      ..on('notification:new', (data) {
        try {
          if (data is Map) {
            _notificationController.add(Map<String, dynamic>.from(data));
          }
        } catch (e, st) {
          _log.w(
            'SOCKET notification:new parse error',
            error: e,
            stackTrace: st,
          );
        }
      })
      ..on('chat:kicked', (data) => _emitChatAccessRevoked(data, 'kicked'))
      ..on('chat:left', (data) => _emitChatAccessRevoked(data, 'left'))
      ..on('room_access_denied', (data) => _emitChatAccessRevoked(data, 'denied'))
      ..on('chat:unread_update', _emitChatUnread);
  }

  void _emit(String event, Map<String, dynamic> data) {
    final socket = _socket;
    if (socket == null || socket.connected != true) return;
    socket.emit(event, data);
  }

  void _setStatus(SocketStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }

  void _handleReceiveMessage(dynamic data) {
    if (_messageController.isClosed) return;
    try {
      _messageController.add(data);
    } catch (e, st) {
      _log.e('SOCKET receive_message handler error', error: e, stackTrace: st);
    }
  }

  void _handleTypingEvent(dynamic data, {required bool isTyping}) {
    if (_typingController.isClosed) return;
    try {
      final d = data as Map;
      _typingController.add(TypingEvent(
        chatId: d['chatId']?.toString() ?? '',
        userId: d['userId']?.toString() ?? '',
        username: isTyping ? (d['username']?.toString() ?? '') : '',
        isTyping: isTyping,
      ));
    } catch (e, st) {
      _log.w(
        'SOCKET ${isTyping ? 'typing' : 'stop_typing'} parse error',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _handleMessageDeleted(dynamic data) {
    if (_deletedController.isClosed) return;
    try {
      final d = data as Map;
      _deletedController.add(MessageDeletedEvent(d['messageId'].toString()));
    } catch (e, st) {
      _log.w('SOCKET message_deleted parse error', error: e, stackTrace: st);
    }
  }

  void _handleMessagePinned(dynamic data, {required bool isPinned}) {
    if (_pinnedController.isClosed) return;
    try {
      final d = data as Map;
      _pinnedController.add(
        MessagePinnedEvent(d['messageId'].toString(), isPinned: isPinned),
      );
    } catch (e, st) {
      _log.w(
        'SOCKET ${isPinned ? 'message_pinned' : 'message_unpinned'} parse error',
        error: e,
        stackTrace: st,
      );
    }
  }

  void _emitChatUnread(dynamic data) {
    if (_chatUnreadController.isClosed) return;
    try {
      if (data is! Map) return;
      final d = Map<String, dynamic>.from(data);
      final chatId = d['chatId']?.toString();
      if (chatId == null || chatId.isEmpty) return;
      _chatUnreadController.add(ChatUnreadUpdateEvent(
        chatId: chatId,
        messageId: d['messageId']?.toString(),
        preview: d['preview']?.toString(),
        sentAt: DateTime.tryParse(d['sentAt']?.toString() ?? ''),
        senderId: d['senderId']?.toString(),
      ));
    } catch (e, st) {
      _log.w('SOCKET chat:unread_update parse error', error: e, stackTrace: st);
    }
  }

  void _emitChatAccessRevoked(dynamic data, String reason) {
    if (_chatAccessRevokedController.isClosed) return;
    try {
      if (data is! Map) return;
      final d = Map<String, dynamic>.from(data);
      final chatId = d['chatId']?.toString();
      if (chatId == null || chatId.isEmpty) return;
      _chatAccessRevokedController.add(ChatAccessRevokedEvent(
        chatId: chatId,
        gameId: d['gameId']?.toString(),
        reason: (d['reason'] ?? reason).toString(),
        detail: d['detail']?.toString(),
      ));
    } catch (e, st) {
      _log.w('SOCKET chat access revoked parse error', error: e, stackTrace: st);
    }
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.dispose);
  return service;
});
