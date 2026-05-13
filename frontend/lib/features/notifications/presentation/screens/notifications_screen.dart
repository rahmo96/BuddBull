import 'dart:async';

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/notifications/data/notification_model.dart';
import 'package:buddbull/features/notifications/providers/notification_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inbox view backed by `notificationsProvider`. Tapping a row marks it
/// read and, when possible, deep-links into the relevant context
/// (game detail, chat room, public profile).
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationsProvider);
    final notifier = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: state.isMutating ? null : notifier.markAllAsRead,
              child: Text(
                'Mark all read',
                style: TextStyle(
                  color: state.isMutating
                      ? AppColors.textDisabled
                      : AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: notifier.refresh,
        child: _buildBody(context, state, notifier),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    NotificationsState state,
    NotificationsNotifier notifier,
  ) {
    if (state.isLoading && !state.hasLoadedOnce) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: notifier.refresh,
      );
    }

    if (state.notifications.isEmpty) {
      // ListView so the pull-to-refresh gesture still works on the empty
      // state — otherwise the `RefreshIndicator` host needs a scrollable.
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 120),
          _EmptyInbox(),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: state.notifications.length,
      separatorBuilder: (_, __) => const Divider(
        height: 1,
        thickness: 0.5,
        color: AppColors.border,
        indent: 72,
      ),
      itemBuilder: (context, index) {
        final n = state.notifications[index];
        return _NotificationTile(
          notification: n,
          onTap: () => _handleTap(context, n, notifier),
        );
      },
    );
  }

  Future<void> _handleTap(
    BuildContext context,
    NotificationModel n,
    NotificationsNotifier notifier,
  ) async {
    if (n.isUnread) {
      // Fire-and-forget — the optimistic update inside the notifier
      // means we don't need to await before navigating.
      unawaited(notifier.markAsRead(n.id));
    }
    final target = _routeFor(n);
    if (target != null && context.mounted) context.push(target);
  }

  String? _routeFor(NotificationModel n) {
    final gameId = n.gameId;
    if (gameId != null && gameId.isNotEmpty) return Routes.gameDetail(gameId);
    final chatId = n.chatId;
    if (chatId != null && chatId.isNotEmpty) return Routes.chatRoom(chatId);
    final userId = n.userId;
    if (userId != null && userId.isNotEmpty) return Routes.publicProfile(userId);
    return null;
  }
}

// ── Internal widgets ──────────────────────────────────────────────────────────
class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;
    return Material(
      color: isUnread ? AppColors.infoLight.withValues(alpha: 0.35) : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _LeadingIcon(type: notification.type, isUnread: isUnread),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _relativeTime(notification.createdAt),
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        notification.body,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          fontWeight: isUnread ? FontWeight.w500 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (isUnread) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _LeadingIcon extends StatelessWidget {
  const _LeadingIcon({required this.type, required this.isUnread});
  final String type;
  final bool isUnread;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _iconFor(type);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withValues(alpha: isUnread ? 0.18 : 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  (IconData, Color) _iconFor(String type) {
    switch (type) {
      case 'gameInvite':
      case 'gameJoinRequest':
        return (Icons.mail_outline_rounded, AppColors.info);
      case 'gameApproved':
        return (Icons.check_circle_outline_rounded, AppColors.success);
      case 'gameReminder':
        return (Icons.alarm_rounded, AppColors.warning);
      case 'gameCancelled':
        return (Icons.cancel_outlined, AppColors.error);
      case 'gameCompleted':
        return (Icons.emoji_events_outlined, AppColors.secondary);
      case 'ratingPending':
      case 'ratingReceived':
        return (Icons.star_border_rounded, AppColors.secondary);
      case 'newFollower':
        return (Icons.person_add_alt_1_outlined, AppColors.info);
      case 'broadcast':
        return (Icons.campaign_outlined, AppColors.primary);
      default:
        return (Icons.notifications_none_rounded, AppColors.textSecondary);
    }
  }
}

class _EmptyInbox extends StatelessWidget {
  const _EmptyInbox();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: AppColors.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.notifications_none_rounded,
                size: 40,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "You're all caught up",
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              "We'll let you know when something new happens.",
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
String _relativeTime(DateTime t) {
  final diff = DateTime.now().difference(t);
  if (diff.inSeconds < 60) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${diff.inDays ~/ 7}w';
}
