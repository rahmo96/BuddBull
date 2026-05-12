import 'dart:async';

import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

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
    if (_socket?.connected == true) {
      debugPrint('⚪ SOCKET connect skipped — already connected (${_socket!.id})');
      return;
    }

    // Drop half-open client so a later connect() always rebuilds listeners + handshake.
    if (_socket != null) {
      debugPrint('⚪ SOCKET disposing stale socket before new handshake');
      try {
        _socket!.dispose();
      } catch (_) {}
      _socket = null;
    }

    String? token;
    try {
      token = await FirebaseAuth.instance.currentUser?.getIdToken();
    } on FirebaseAuthException catch (e, st) {
      debugPrint('❌ SOCKET abort — FirebaseAuthException getting token: $e\n$st');
      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}
      return;
    } catch (e, st) {
      debugPrint('❌ SOCKET abort — error getting token: $e\n$st');
      return;
    }
    if (token == null) {
      debugPrint(
        '❌ SOCKET abort — no Firebase ID token (currentUser: ${FirebaseAuth.instance.currentUser?.uid})',
      );
      return;
    }
    _lastToken = token;

    _setStatus(SocketStatus.connecting);

    final serverUrl = ApiEndpoints.socketUrl;
    debugPrint('🟡 SOCKET handshake → $serverUrl (same origin as ApiClient base, minus /api/v1)');

    try {
      _socket = io.io(
        serverUrl,
        io.OptionBuilder()
            .setTransports(['websocket'])
            .enableForceNew()
            .enableReconnection()
            .setAuth({'token': token})
            // Must defer connect until handlers below are attached (see Socket ctor).
            .disableAutoConnect()
            .build(),
      );
    } catch (e, st) {
      debugPrint('❌ SOCKET io.io() failed: $e\n$st');
      _setStatus(SocketStatus.error);
      return;
    }

    _socket!
      ..onConnect((_) {
        debugPrint('🟢 SOCKET CONNECTED: ${_socket!.id}');
        _setStatus(SocketStatus.connected);
        // Re-join rooms after reconnect — contract: `{ 'chatId': chatId }`.
        for (final chatId in _joinedChats) {
          if (_socket?.connected == true) {
            _socket!.emit('join_chat', <String, dynamic>{'chatId': chatId});
          }
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

    debugPrint('🟡 SOCKET calling connect()…');
    _socket!.connect();

    _socket!.onAny((event, data) {
      debugPrint('⚡ GLOBAL CAUGHT: Event: $event | Data: $data');
    });

    // Register message handlers immediately after connect() so they always bind to this instance.
    _socket!.on('receive_message', (data) {
      debugPrint('🔥 RECEIVED: $data');
      try {
        _messageController.add(data);
      } catch (_) {}
    });
    _socket!.on('newMessage', (data) {
      debugPrint('🔥 RECEIVED newMessage: $data');
      try {
        _messageController.add(data);
      } catch (_) {}
    });
  }

  // ── Room management ───────────────────────────────────────────────────────
  void joinChat(String chatId) {
    debugPrint('🔵 SOCKET EMITTING JOIN ROOM: $chatId');
    _joinedChats.add(chatId);
    if (_socket?.connected == true) {
      _socket!.emit('join_chat', <String, dynamic>{'chatId': chatId});
    }
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
