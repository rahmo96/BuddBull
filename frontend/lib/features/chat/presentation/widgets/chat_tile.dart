import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';

class ChatTile extends StatelessWidget {
  final ChatModel chat;
  final String currentUserId;
  final VoidCallback? onTap;

  const ChatTile({
    super.key,
    required this.chat,
    required this.currentUserId,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final title = chat.chatTitle(currentUserId);
    final avatarUrl = chat.chatAvatar(currentUserId);
    final hasUnread = chat.unreadCount > 0;
    final lastMsg = chat.lastMessage;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────
            _Avatar(
              avatarUrl: avatarUrl,
              title: title,
              isGroup: chat.type == 'group',
            ),
            const SizedBox(width: 12),

            // ── Content ──────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: AppTextStyles.bodyMedium.copyWith(
                            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastMsg != null)
                        Text(
                          _formatTime(lastMsg.sentAt),
                          style: AppTextStyles.caption.copyWith(
                            color: hasUnread ? AppColors.primary : AppColors.textSecondary,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastMsg?.content ?? 'No messages yet',
                          style: AppTextStyles.caption.copyWith(
                            color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (chat.isMuted)
                        const Icon(Icons.volume_off, size: 14, color: AppColors.textSecondary),
                      if (hasUnread && !chat.isMuted)
                        Container(
                          constraints: const BoxConstraints(minWidth: 20),
                          height: 20,
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            chat.unreadCount > 99 ? '99+' : chat.unreadCount.toString(),
                            style: AppTextStyles.caption.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays == 0) return DateFormat.Hm().format(dt);
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return DateFormat.EEEE().format(dt);
    return DateFormat.yMd().format(dt);
  }
}

// ── Avatar widget ─────────────────────────────────────────────────────────────
class _Avatar extends StatelessWidget {
  final String? avatarUrl;
  final String title;
  final bool isGroup;

  const _Avatar({this.avatarUrl, required this.title, required this.isGroup});

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 26,
      backgroundColor: AppColors.primary.withOpacity(0.15),
      child: avatarUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: avatarUrl!,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => _fallback(),
              ),
            )
          : _fallback(),
    );
  }

  Widget _fallback() {
    if (isGroup) {
      return const Icon(Icons.group, color: AppColors.primary, size: 22);
    }
    final initials = title.isNotEmpty ? title[0].toUpperCase() : '?';
    return Text(
      initials,
      style: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.bold,
        fontSize: 18,
      ),
    );
  }
}
