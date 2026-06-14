import 'dart:async';

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/notifications/data/notification_model.dart';
import 'package:buddbull/features/notifications/providers/notification_provider.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Inbox view backed by `notificationsProvider`. Tapping a row marks it
/// read and, when possible, deep-links into the relevant context
/// (game detail, chat room, public profile).
///
/// `gameJoinRequest` rows additionally expose inline "Approve" /
/// "Reject" buttons that route to the new
/// `PATCH /games/:id/join-request/:userId` endpoint without forcing the
/// organiser to open the Game Detail screen.
///
/// `gameCompleted` rows perform a smart-sync check before navigating:
/// if `pendingRatingsProvider` confirms the user has already finished
/// rating that game, we surface a SnackBar and stay on the inbox.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
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
          isMutating: state.isMutating,
          onTap: () => _handleTap(context, n),
          onApproveJoinRequest: () => _handleJoinRequestDecision(
            context: context,
            notificationId: n.id,
            decision: 'approve',
          ),
          onRejectJoinRequest: () => _handleJoinRequestDecision(
            context: context,
            notificationId: n.id,
            decision: 'reject',
          ),
          onAcceptFriendRequest: () => _handleFriendRequestDecision(
            context: context,
            notificationId: n.id,
            decision: 'accept',
          ),
          onDeclineFriendRequest: () => _handleFriendRequestDecision(
            context: context,
            notificationId: n.id,
            decision: 'decline',
          ),
          onAcceptGameInvite: () => _handleGameInviteDecision(
            context: context,
            notificationId: n.id,
            decision: 'accept',
          ),
          onDeclineGameInvite: () => _handleGameInviteDecision(
            context: context,
            notificationId: n.id,
            decision: 'decline',
          ),
        );
      },
    );
  }

  Future<void> _handleTap(BuildContext context, NotificationModel n) async {
    final notifier = ref.read(notificationsProvider.notifier);

    // ── Smart Sync ───────────────────────────────────────────────────────
    // A `gameCompleted` notification deep-links to the rating screen, but
    // if the user already finished (or dismissed) the rating queue for
    // that game we shouldn't drag them back in. Read the cached pending
    // list synchronously — by the time the bell badge is tapped, the
    // rating submit/dismiss flow has already invalidated this provider,
    // so the cached value is fresh.
    if (n.type == 'gameCompleted') {
      final gameId = n.gameId;
      final pending = ref.read(pendingRatingsProvider);
      final pendingList = pending.value;
      final stillHasPending = gameId != null &&
          gameId.isNotEmpty &&
          pendingList != null &&
          pendingList.any((p) => p.gameId == gameId);

      if (pendingList != null && !stillHasPending) {
        if (n.isUnread) unawaited(notifier.markAsRead(n.id));
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("You've already rated the players for this game."),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    if (n.isUnread) {
      // Fire-and-forget — the optimistic update inside the notifier
      // means we don't need to await before navigating.
      unawaited(notifier.markAsRead(n.id));
    }
    final target = _routeFor(n);
    if (target != null && context.mounted) context.push(target);
  }

  Future<void> _handleFriendRequestDecision({
    required BuildContext context,
    required String notificationId,
    required String decision,
  }) async {
    final ok = await ref
        .read(notificationsProvider.notifier)
        .handleFriendRequest(notificationId, decision);
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            decision == 'accept'
                ? 'Friend request accepted'
                : 'Friend request declined',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      final err = ref.read(notificationsProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err ?? 'Could not update friend request'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _handleGameInviteDecision({
    required BuildContext context,
    required String notificationId,
    required String decision,
  }) async {
    final ok = await ref
        .read(notificationsProvider.notifier)
        .handleGameInvite(notificationId, decision);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(
          decision == 'accept'
              ? 'You joined the game.'
              : 'Invite declined.',
        ),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } else {
      final err = ref.read(notificationsProvider).error ?? 'Action failed.';
      final message = err.contains('no longer valid')
          ? 'This invitation is no longer valid.'
          : err;
      messenger.showSnackBar(SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _handleJoinRequestDecision({
    required BuildContext context,
    required String notificationId,
    required String decision,
  }) async {
    final notifier = ref.read(notificationsProvider.notifier);
    final ok = await notifier.handleJoinRequest(notificationId, decision);
    if (!context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    if (ok) {
      messenger.showSnackBar(SnackBar(
        content: Text(decision == 'approve'
            ? 'Player approved.'
            : 'Join request rejected.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    } else {
      final err = ref.read(notificationsProvider).error ?? 'Action failed.';
      messenger.showSnackBar(SnackBar(
        content: Text(err),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ));
    }
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
    required this.isMutating,
    this.onApproveJoinRequest,
    this.onRejectJoinRequest,
    this.onAcceptFriendRequest,
    this.onDeclineFriendRequest,
    this.onAcceptGameInvite,
    this.onDeclineGameInvite,
  });

  final NotificationModel notification;
  final VoidCallback onTap;
  final bool isMutating;

  final VoidCallback? onApproveJoinRequest;
  final VoidCallback? onRejectJoinRequest;
  final VoidCallback? onAcceptFriendRequest;
  final VoidCallback? onDeclineFriendRequest;
  final VoidCallback? onAcceptGameInvite;
  final VoidCallback? onDeclineGameInvite;

  bool get _showJoinQuickActions =>
      notification.type == 'gameJoinRequest' &&
      notification.isUnread &&
      onApproveJoinRequest != null &&
      onRejectJoinRequest != null;

  bool get _showFriendQuickActions =>
      notification.type == 'friendRequest' &&
      notification.isUnread &&
      onAcceptFriendRequest != null &&
      onDeclineFriendRequest != null;

  bool get _showGameInviteQuickActions =>
      notification.type == 'gameInvite' &&
      notification.isUnread &&
      onAcceptGameInvite != null &&
      onDeclineGameInvite != null;

  @override
  Widget build(BuildContext context) {
    final isUnread = notification.isUnread;
    return Material(
      color: isUnread ? AppColors.infoLight.withValues(alpha: 0.35) : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
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
              if (_showJoinQuickActions) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: _JoinRequestQuickActions(
                    isMutating: isMutating,
                    onApprove: onApproveJoinRequest!,
                    onReject: onRejectJoinRequest!,
                  ),
                ),
              ],
              if (_showFriendQuickActions) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: _JoinRequestQuickActions(
                    isMutating: isMutating,
                    onApprove: onAcceptFriendRequest!,
                    onReject: onDeclineFriendRequest!,
                    approveLabel: 'Accept',
                    rejectLabel: 'Decline',
                  ),
                ),
              ],
              if (_showGameInviteQuickActions) ...[
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 52),
                  child: _JoinRequestQuickActions(
                    isMutating: isMutating,
                    onApprove: onAcceptGameInvite!,
                    onReject: onDeclineGameInvite!,
                    approveLabel: 'Accept',
                    rejectLabel: 'Decline',
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

class _JoinRequestQuickActions extends StatelessWidget {
  const _JoinRequestQuickActions({
    required this.isMutating,
    required this.onApprove,
    required this.onReject,
    this.approveLabel = 'Approve',
    this.rejectLabel = 'Reject',
  });

  final bool isMutating;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final String approveLabel;
  final String rejectLabel;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.tonalIcon(
            onPressed: isMutating ? null : onApprove,
            icon: const Icon(Icons.check_rounded, size: 18),
            label: Text(approveLabel),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
              foregroundColor: AppColors.success,
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isMutating ? null : onReject,
            icon: const Icon(Icons.close_rounded, size: 18),
            label: Text(rejectLabel),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: BorderSide(
                color: AppColors.error.withValues(alpha: 0.4),
              ),
              padding: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ),
      ],
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
      case 'gameJoinRequestDenied':
      case 'gameKicked':
        return (Icons.person_off_outlined, AppColors.error);
      case 'gameReminder':
        return (Icons.alarm_rounded, AppColors.warning);
      case 'retentionReminder':
        return (Icons.favorite_outline_rounded, AppColors.primary);
      case 'gameCancelled':
        return (Icons.cancel_outlined, AppColors.error);
      case 'gameCompleted':
        return (Icons.emoji_events_outlined, AppColors.secondary);
      case 'ratingPending':
      case 'ratingReceived':
        return (Icons.star_border_rounded, AppColors.secondary);
      case 'newFollower':
      case 'friendRequest':
      case 'friendRequestAccepted':
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
