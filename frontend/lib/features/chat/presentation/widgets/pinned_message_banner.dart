import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// A slim banner shown at the top of a chat screen when there is a pinned message.
class PinnedMessageBanner extends StatelessWidget {
  final PinnedMessage pinnedMessage;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const PinnedMessageBanner({
    super.key,
    required this.pinnedMessage,
    this.onTap,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.08),
          border: const BorderDirectional(
            start: BorderSide(color: AppColors.primary, width: 3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.push_pin, size: 14, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    context.l10n.chatPinnedMessage,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    pinnedMessage.content,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (onDismiss != null)
              GestureDetector(
                onTap: onDismiss,
                child: const Icon(Icons.close, size: 16, color: AppColors.textSecondary),
              ),
          ],
        ),
      ),
    );
  }
}
