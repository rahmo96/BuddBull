import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showSenderName;
  final bool showAvatar;
  final String? currentUserId;
  final VoidCallback? onReply;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
    this.showAvatar = true,
    this.currentUserId,
    this.onReply,
    this.onPin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _deletedBubble(context);

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: isMe ? 48 : 8,
          end: isMe ? 8 : 48,
          bottom: 4,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isMe && showAvatar) ...[
              _buildAvatar(),
              const SizedBox(width: 6),
            ] else if (!isMe) ...[
              const SizedBox(width: 36),
            ],
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && showSenderName)
                    Padding(
                      padding: const EdgeInsetsDirectional.only(start: 4, bottom: 2),
                      child: Text(
                        message.senderName,
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (message.replyTo != null) _buildReplyPreview(),
                  _buildBody(),
                  Padding(
                    padding: const EdgeInsetsDirectional.only(top: 2, start: 4, end: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (message.isPinned) ...[
                          const Icon(Icons.push_pin, size: 10, color: AppColors.textSecondary),
                          const SizedBox(width: 2),
                        ],
                        Text(
                          DateFormat.Hm().format(message.sentAt),
                          style: AppTextStyles.caption.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                          ),
                        ),
                        if (isMe && currentUserId != null) ...[
                          const SizedBox(width: 6),
                          Icon(
                            _isSeenBySomeoneElse(currentUserId!)
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 14,
                            color: _isSeenBySomeoneElse(currentUserId!)
                                ? AppColors.success
                                : AppColors.textSecondary,
                          ),
                        ],
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            context.l10n.messageEdited,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.textSecondary,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final pic = message.senderPicture;
    return CircleAvatar(
      radius: 14,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      child: pic != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: pic,
                width: 28,
                height: 28,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _avatarFallback(),
              ),
            )
          : _avatarFallback(),
    );
  }

  Widget _avatarFallback() {
    final name = message.senderName;
    return Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildReplyPreview() {
    final reply = message.replyTo!;
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: const BorderDirectional(
          start: BorderSide(color: AppColors.primary, width: 3),
        ),
      ),
      child: Text(
        reply.content,
        style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary : AppColors.surface,
        borderRadius: BorderRadiusDirectional.only(
          topStart: const Radius.circular(16),
          topEnd: const Radius.circular(16),
          bottomStart: Radius.circular(isMe ? 16 : 4),
          bottomEnd: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        message.content,
        style: AppTextStyles.bodySmall.copyWith(
          color: isMe ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _deletedBubble(BuildContext context) {
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.not_interested, size: 12, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  l10n.messageDeleted,
                  style: AppTextStyles.caption.copyWith(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSeenBySomeoneElse(String currentUserId) {
    final readBy = message.readBy;
    return readBy.isNotEmpty && readBy.any((id) => id != currentUserId);
  }

  void _showOptions(BuildContext context) {
    final l10n = context.l10n;
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: Text(l10n.messageActionReply),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.messageActionCopyText),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
              },
            ),
            if (onPin != null)
              ListTile(
                leading: Icon(message.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                title: Text(message.isPinned ? l10n.messageActionUnpin : l10n.messageActionPin),
                onTap: () {
                  Navigator.pop(ctx);
                  onPin!();
                },
              ),
            if (isMe && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: Text(l10n.messageActionDelete, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}
