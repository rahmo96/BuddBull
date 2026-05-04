import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/services/socket_service.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';
import 'package:buddbull/features/chat/providers/chat_provider.dart';
import 'package:buddbull/features/chat/presentation/widgets/message_bubble.dart';
import 'package:buddbull/features/chat/presentation/widgets/pinned_message_banner.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String chatId;

  const ChatScreen({super.key, required this.chatId});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  MessageModel? _replyingTo;
  Timer? _typingTimer;
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Connect socket when entering chat
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(socketServiceProvider).connect();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _typingTimer?.cancel();
    super.dispose();
  }

  void _onScroll() {
    // Load older messages when scrolled to top
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(messagesProvider(widget.chatId).notifier).loadMore();
    }
  }

  void _handleTyping() {
    if (!_isTyping) {
      _isTyping = true;
      ref.read(messagesProvider(widget.chatId).notifier).startTyping();
    }
    _typingTimer?.cancel();
    _typingTimer = Timer(const Duration(seconds: 3), () {
      _isTyping = false;
      ref.read(messagesProvider(widget.chatId).notifier).stopTyping();
    });
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _typingTimer?.cancel();
    _isTyping = false;

    ref.read(messagesProvider(widget.chatId).notifier).sendMessage(
          text,
          replyToId: _replyingTo?.id,
        );

    _controller.clear();
    setState(() => _replyingTo = null);

    // Scroll to bottom
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatAsync = ref.watch(chatDetailProvider(widget.chatId));
    final messagesState = ref.watch(messagesProvider(widget.chatId));
    final typingState = ref.watch(typingProvider(widget.chatId));
    final authState = ref.watch(authProvider);
    final currentUserId = authState.user?.id ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: chatAsync.when(
        loading: () => AppBar(title: const Text('Loading...')),
        error: (_, __) => AppBar(title: const Text('Chat')),
        data: (chat) => _buildAppBar(chat, currentUserId),
      ),
      body: Column(
        children: [
          // ── Pinned message banner ──────────────────────────────────
          chatAsync.maybeWhen(
            data: (chat) {
              final pinned = chat.pinnedMessages;
              if (pinned.isEmpty) return const SizedBox.shrink();
              return PinnedMessageBanner(
                pinnedMessage: pinned.last,
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),

          // ── Loading older messages indicator ───────────────────────
          if (messagesState.isLoadingMore)
            const LinearProgressIndicator(minHeight: 2),

          // ── Message list ───────────────────────────────────────────
          Expanded(
            child: messagesState.isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: messagesState.messages.length,
                    itemBuilder: (ctx, i) {
                      // reversed: index 0 is newest
                      final index = messagesState.messages.length - 1 - i;
                      final msg = messagesState.messages[index];
                      final isMe = msg.senderId == currentUserId;

                      // Show avatar only if next message has a different sender
                      final showAvatar = index == 0 ||
                          messagesState.messages[index - 1].senderId != msg.senderId;
                      final isGroup = chatAsync.valueOrNull?.type == 'group';

                      return MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showSenderName: !isMe && isGroup && showAvatar,
                        showAvatar: !isMe && showAvatar,
                        onReply: () => setState(() => _replyingTo = msg),
                        onPin: chatAsync.valueOrNull?.isAdmin == true
                            ? () => _pinMessage(msg)
                            : null,
                        onDelete: isMe ? () => _deleteMessage(msg) : null,
                      );
                    },
                  ),
          ),

          // ── Typing indicator ───────────────────────────────────────
          if (typingState.typingUsernames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    '${typingState.typingUsernames.join(', ')} ${typingState.typingUsernames.length == 1 ? 'is' : 'are'} typing...',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

          // ── Reply preview ──────────────────────────────────────────
          if (_replyingTo != null) _buildReplyPreview(),

          // ── Input bar ─────────────────────────────────────────────
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ChatModel chat, String currentUserId) {
    final title = chat.chatTitle(currentUserId);
    final participantCount = chat.participants.length;
    final subtitle = chat.type == 'group' ? '$participantCount members' : null;

    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      titleSpacing: 0,
      leading: const BackButton(color: AppColors.textPrimary),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
          if (subtitle != null)
            Text(subtitle, style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildReplyPreview() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Container(width: 3, height: 36, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to ${_replyingTo!.senderName}',
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _replyingTo!.content,
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => setState(() => _replyingTo = null),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Text field ───────────────────────────────────────
            Expanded(
              child: Container(
                constraints: const BoxConstraints(maxHeight: 120),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                ),
                child: TextField(
                  controller: _controller,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => _handleTyping(),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // ── Send button ──────────────────────────────────────
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _pinMessage(MessageModel msg) {
    ref.read(socketServiceProvider).pinMessage(widget.chatId, msg.id);
  }

  void _deleteMessage(MessageModel msg) {
    ref.read(socketServiceProvider).deleteMessage(msg.id);
  }
}
