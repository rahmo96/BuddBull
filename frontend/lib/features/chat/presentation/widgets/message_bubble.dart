import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';

class MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMe;
  final bool showSenderName; // true in group chats
  final bool showAvatar;
  final VoidCallback? onReply;
  final VoidCallback? onPin;
  final VoidCallback? onDelete;

  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.showSenderName = false,
    this.showAvatar = true,
    this.onReply,
    this.onPin,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (message.isDeleted) return _deletedBubble();

    return GestureDetector(
      onLongPress: () => _showOptions(context),
      child: Padding(
        padding: EdgeInsets.only(
          left: isMe ? 48 : 8,
          right: isMe ? 8 : 48,
          bottom: 4,
        ),
        child: Row(
          mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // ── Other-user avatar ─────────────────────────────────
            if (!isMe && showAvatar) ...[
              _buildAvatar(),
              const SizedBox(width: 6),
            ] else if (!isMe) ...[
              const SizedBox(width: 36),
            ],

            // ── Bubble ────────────────────────────────────────────
            Flexible(
              child: Column(
                crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (!isMe && showSenderName)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 2),
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
                    padding: const EdgeInsets.only(top: 2, left: 4, right: 4),
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
                        if (message.isEdited) ...[
                          const SizedBox(width: 4),
                          Text(
                            '• edited',
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
      backgroundColor: AppColors.primary.withOpacity(0.15),
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
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: const Border(left: BorderSide(color: AppColors.primary, width: 3)),
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
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isMe ? 16 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 16),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
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

  Widget _deletedBubble() {
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
                  'Message deleted',
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

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (onReply != null)
              ListTile(
                leading: const Icon(Icons.reply),
                title: const Text('Reply'),
                onTap: () {
                  Navigator.pop(ctx);
                  onReply!();
                },
              ),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy text'),
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content));
                Navigator.pop(ctx);
              },
            ),
            if (onPin != null)
              ListTile(
                leading: Icon(message.isPinned ? Icons.push_pin_outlined : Icons.push_pin),
                title: Text(message.isPinned ? 'Unpin' : 'Pin message'),
                onTap: () {
                  Navigator.pop(ctx);
                  onPin!();
                },
              ),
            if (isMe && onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Delete', style: TextStyle(color: Colors.red)),
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
