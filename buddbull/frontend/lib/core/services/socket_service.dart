import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/core/storage/secure_storage.dart';
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
  final SecureStorage _storage;

  // ── Broadcast streams ──────────────────────────────────────────────────────
  final _messageController = StreamController<MessageModel>.broadcast();
  final _typingController = StreamController<TypingEvent>.broadcast();
  final _deletedController = StreamController<MessageDeletedEvent>.broadcast();
  final _pinnedController = StreamController<MessagePinnedEvent>.broadcast();
  final _statusController = StreamController<SocketStatus>.broadcast();

  Stream<MessageModel> get messageStream => _messageController.stream;
  Stream<TypingEvent> get typingStream => _typingController.stream;
  Stream<MessageDeletedEvent> get deletedStream => _deletedController.stream;
  Stream<MessagePinnedEvent> get pinnedStream => _pinnedController.stream;
  Stream<SocketStatus> get statusStream => _statusController.stream;

  SocketStatus _status = SocketStatus.disconnected;
  SocketStatus get status => _status;

  SocketService(this._storage);

  // ── Connect ───────────────────────────────────────────────────────────────
  Future<void> connect() async {
    if (_socket?.connected == true) return;

    final token = await _storage.getAccessToken();
    if (token == null) return;

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
      })
      ..onDisconnect((_) {
        _setStatus(SocketStatus.disconnected);
      })
      ..onConnectError((err) {
        _setStatus(SocketStatus.error);
      })
      ..on('receive_message', (data) {
        try {
          final msgRaw = (data is Map) ? data['message'] as Map<String, dynamic>? : null;
          if (msgRaw != null) _messageController.add(MessageModel.fromJson(msgRaw));
        } catch (_) {}
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
          _deletedController.add(MessageDeletedEvent(d['messageId'].toString()));
        } catch (_) {}
      })
      ..on('message_pinned', (data) {
        try {
          final d = data as Map;
          _pinnedController.add(MessagePinnedEvent(d['messageId'].toString(), isPinned: true));
        } catch (_) {}
      })
      ..on('message_unpinned', (data) {
        try {
          final d = data as Map;
          _pinnedController.add(MessagePinnedEvent(d['messageId'].toString(), isPinned: false));
        } catch (_) {}
      });

    _socket!.connect();
  }

  // ── Room management ───────────────────────────────────────────────────────
  void joinChat(String chatId) => _emit('join_chat', {'chatId': chatId});
  void leaveChat(String chatId) => _emit('leave_chat', {'chatId': chatId});

  // ── Messaging ─────────────────────────────────────────────────────────────
  void sendMessage(String chatId, String content, {String type = 'text', String? replyToId}) {
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
  final storage = ref.watch(secureStorageProvider);
  final service = SocketService(storage);
  ref.onDispose(service.dispose);
  return service;
});
