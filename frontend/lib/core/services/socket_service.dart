import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';

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

// ── Socket connection status ──────────────────────────────────────────────────
enum SocketStatus { disconnected, connecting, connected, error }

// ── SocketService ─────────────────────────────────────────────────────────────
class SocketService {
  io.Socket? _socket;
  final Set<String> _joinedChats = <String>{};
  StreamSubscription<User?>? _authSub;
  String? _lastToken;

  // ── Broadcast streams ──────────────────────────────────────────────────────
  // Raw socket payloads for debugging + provider-side parsing.
  final _messageController = StreamController<dynamic>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _deletedController = StreamController<MessageDeletedEvent>.broadcast();
  final _pinnedController = StreamController<MessagePinnedEvent>.broadcast();
  final _statusController = StreamController<SocketStatus>.broadcast();

  Stream<dynamic> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<MessageDeletedEvent> get deletedStream => _deletedController.stream;
  Stream<MessagePinnedEvent> get pinnedStream => _pinnedController.stream;
  Stream<SocketStatus> get statusStream => _statusController.stream;

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

      // Refresh auth and reconnect so the new token is used.
      if (_socket != null) {
        _socket!.auth = {'token': token};
        if (_socket!.connected == true) {
          _socket!.disconnect();
        }
        _socket!.connect();
      }
    });
  }

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (_socket?.connected == true) return;

    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } on FirebaseAuthException {
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      return;
    } catch (_) {
      return;
    }
    if (token == null) return;
    _lastToken = token;

    _setStatus(SocketStatus.connecting);

    // Strip /api/v1 suffix — socket connects to the base server URL
    final serverUrl = ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/v1$'), '');

    _socket = io.io(
      serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': token})
          .setTimeout(10000)
          .setReconnectionAttempts(5)
          .build(),
    );

    _socket!
      ..onConnect((_) {
        _setStatus(SocketStatus.connected);
        // Re-join rooms after reconnect.
        for (final chatId in _joinedChats) {
          _emit('join_chat', {'chatId': chatId});
        }
      })
      ..onDisconnect((_) {
        _setStatus(SocketStatus.disconnected);
      })
      ..onConnectError((err) {
        _setStatus(SocketStatus.error);
      })
      ..on('receive_message', (data) {
        try {
          // ignore: avoid_print
          print('SOCKET_DEBUG: Received message: $data');
          _messageController.add(data);
        } catch (_) {}
      })
      ..on('newMessage', (data) {
        // ignore: avoid_print
        print('FRONTEND_RECEIVE: $data'); // This will prove the message arrived
        _messageController.add(data);
      })
      ..on('messageRead', (data) {
        // Forward as a lightweight pinned event channel reuse isn't ideal; handled in provider via socket raw if needed.
      })
      ..on('typing', (data) {
        try {
          final d = data as Map;
          _typingController.add(TypingEvent(
            chatId: d['chatId']?.toString() ?? '',
            userId: d['userId']?.toString() ?? '',
            username: d['username']?.toString() ?? '',
            isTyping: true,
          ));
        } catch (_) {}
      })
      ..on('stop_typing', (data) {
        try {
          final d = data as Map;
          _typingController.add(TypingEvent(
            chatId: d['chatId']?.toString() ?? '',
            userId: d['userId']?.toString() ?? '',
            username: '',
            isTyping: false,
          ));
        } catch (_) {}
      })
      ..on('message_deleted', (data) {
        try {
          final d = data as Map;
          _deletedController
              .add(MessageDeletedEvent(d['messageId'].toString()));
        } catch (_) {}
      })
      ..on('message_pinned', (data) {
        try {
          final d = data as Map;
          _pinnedController.add(
              MessagePinnedEvent(d['messageId'].toString(), isPinned: true));
        } catch (_) {}
      })
      ..on('message_unpinned', (data) {
        try {
          final d = data as Map;
          _pinnedController.add(
              MessagePinnedEvent(d['messageId'].toString(), isPinned: false));
        } catch (_) {}
      });

    _socket!.connect();
  }

  // ── Room management ───────────────────────────────────────────────────────
  void joinChat(String chatId) {
    _joinedChats.add(chatId);
    _emit('join_chat', {'chatId': chatId});
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
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
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
  }

  // ── Private helpers ───────────────────────────────────────────────────────
  void _emit(String event, Map<String, dynamic> data) {
    if (_socket?.connected == true) _socket!.emit(event, data);
  }

  void _setStatus(SocketStatus status) {
    _status = status;
    if (!_statusController.isClosed) _statusController.add(status);
  }
}

// ── Providers ─────────────────────────────────────────────────────────────────
final socketServiceProvider = Provider<SocketService>((ref) {
  final service = SocketService();
  ref.onDispose(service.dispose);
  return service;
});
