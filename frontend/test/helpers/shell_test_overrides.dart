import 'package:buddbull/features/chat/data/chat_repository.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';
import 'package:buddbull/features/chat/providers/chat_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Riverpod overrides for widget tests that pump [HomeScaffold] without auth.
List<Override> shellTestOverrides() => [
      chatRepositoryProvider.overrideWithValue(const StubChatRepository()),
    ];

/// Stub — [ChatUnreadNotifier] only needs [getChats] during bootstrap.
class StubChatRepository implements ChatRepository {
  const StubChatRepository();

  @override
  Future<List<ChatModel>> getChats() async => [];

  @override
  Future<ChatModel> getChatById(String chatId) => throw UnimplementedError();

  @override
  Future<ChatModel> createOrGetDM(String recipientId) =>
      throw UnimplementedError();

  @override
  Future<List<MessageModel>> getMessages(
    String chatId, {
    int page = 1,
    int limit = 30,
    String? before,
  }) =>
      throw UnimplementedError();

  @override
  Future<MessageModel> sendMessage(
    String chatId,
    String content, {
    String type = 'text',
    String? replyToId,
  }) =>
      throw UnimplementedError();

  @override
  Future<void> pinMessage(String chatId, String messageId) =>
      throw UnimplementedError();

  @override
  Future<void> unpinMessage(String chatId, String messageId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteMessage(String chatId, String messageId) =>
      throw UnimplementedError();

  @override
  Future<Map<String, int>> getUnreadCounts() async => {};
}
