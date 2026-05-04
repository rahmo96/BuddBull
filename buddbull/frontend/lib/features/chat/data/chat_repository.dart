import 'package:buddbull/core/network/api_client.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';

class ChatRepository {
  final ApiClient _client;

  const ChatRepository(this._client);

  // ── Get all chats for the current user ─────────────────────────────────────
  Future<List<ChatModel>> getChats() async {
    final res = await _client.get(ApiEndpoints.chats);
    final raw = res['data']['chats'] as List;
    return raw.whereType<Map<String, dynamic>>().map(ChatModel.fromJson).toList();
  }

  // ── Get a single chat with messages and pinned messages ────────────────────
  Future<ChatModel> getChatById(String chatId) async {
    final res = await _client.get(ApiEndpoints.chat(chatId));
    return ChatModel.fromJson(res['data']['chat'] as Map<String, dynamic>);
  }

  // ── Create or get DM ───────────────────────────────────────────────────────
  Future<ChatModel> createOrGetDM(String recipientId) async {
    final res = await _client.post(
      ApiEndpoints.createDm,
      data: {'recipientId': recipientId},
    );
    return ChatModel.fromJson(res['data']['chat'] as Map<String, dynamic>);
  }

  // ── Get paginated messages ─────────────────────────────────────────────────
  Future<List<MessageModel>> getMessages(
    String chatId, {
    int page = 1,
    int limit = 30,
    String? before,
  }) async {
    final res = await _client.get(
      ApiEndpoints.chatMessages(chatId),
      queryParams: {
        'page': page,
        'limit': limit,
        if (before != null) 'before': before,
      },
    );
    final raw = res['data']['messages'] as List;
    return raw.whereType<Map<String, dynamic>>().map(MessageModel.fromJson).toList();
  }

  // ── Send a message via HTTP (fallback) ─────────────────────────────────────
  Future<MessageModel> sendMessage(
    String chatId,
    String content, {
    String type = 'text',
    String? replyToId,
  }) async {
    final res = await _client.post(
      ApiEndpoints.chatMessages(chatId),
      data: {
        'content': content,
        'type': type,
        if (replyToId != null) 'replyTo': replyToId,
      },
    );
    return MessageModel.fromJson(res['data']['message'] as Map<String, dynamic>);
  }

  // ── Pin a message ──────────────────────────────────────────────────────────
  Future<void> pinMessage(String chatId, String messageId) async {
    await _client.post(
      ApiEndpoints.chatPin(chatId),
      data: {'messageId': messageId},
    );
  }

  // ── Unpin a message ────────────────────────────────────────────────────────
  Future<void> unpinMessage(String chatId, String messageId) async {
    await _client.delete(ApiEndpoints.chatUnpin(chatId, messageId));
  }

  // ── Delete a message ───────────────────────────────────────────────────────
  Future<void> deleteMessage(String chatId, String messageId) async {
    await _client.delete(ApiEndpoints.chatMessage(chatId, messageId));
  }

  // ── Unread counts map ──────────────────────────────────────────────────────
  Future<Map<String, int>> getUnreadCounts() async {
    final res = await _client.get(ApiEndpoints.unreadCounts);
    final raw = res['data']['counts'] as Map<String, dynamic>;
    return raw.map((k, v) => MapEntry(k, (v as num).toInt()));
  }
}
