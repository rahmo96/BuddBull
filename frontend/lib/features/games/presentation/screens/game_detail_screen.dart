import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/widgets/player_slot_row.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';

class GameDetailScreen extends ConsumerWidget {
  const GameDetailScreen({super.key, required this.gameId});
  final String gameId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameAsync = ref.watch(gameDetailProvider(gameId));
    final actionsState = ref.watch(gameActionsProvider(gameId));
    final currentUser = ref.watch(authProvider).user;

    ref.listen(gameActionsProvider(gameId), (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnackBar(context, next.error!);
        ref.read(gameActionsProvider(gameId).notifier).clearError();
      }
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        showSuccessSnackBar(context, next.successMessage!);
        ref.read(gameActionsProvider(gameId).notifier).clearSuccess();
      }
    });

    return gameAsync.when(
      loading: () => const Scaffold(
        body: Center(child: BbLoadingIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(gameDetailProvider(gameId)),
        ),
      ),
      data: (game) {
        final myPlayer = currentUser != null
            ? game.getPlayer(currentUser.id)
            : null;
        final isOrganizer = currentUser?.id == game.organizer.id;

        return LoadingOverlay(
          isLoading: actionsState.isProcessing,
          child: Scaffold(
            backgroundColor: AppColors.background,
            body: CustomScrollView(
              slivers: [
                // ── Coloured header ──────────────────────────
                _GameDetailAppBar(game: game),

                SliverPadding(
                  padding: const EdgeInsets.all(16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Info cards row ─────────────────────
                      Row(
                        spacing: 10,
                        children: [
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.calendar_today_rounded,
                              label: 'Date',
                              value: game.formattedDate,
                            ),
                          ),
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.access_time_rounded,
                              label: 'Time',
                              value: game.formattedTime,
                            ),
                          ),
                          Expanded(
                            child: _InfoCard(
                              icon: Icons.timer_outlined,
                              label: 'Duration',
                              value: game.formattedDuration,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // ── Location ───────────────────────────
                      _Section(
                        title: 'Location',
                        child: Row(
                          children: [
                            const Icon(Icons.location_on_rounded,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                game.location.displayName,
                                style: AppTextStyles.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // ── Description ────────────────────────
                      if (game.description != null &&
                          game.description!.isNotEmpty)
                        _Section(
                          title: 'About this game',
                          child: Text(
                            game.description!,
                            style: AppTextStyles.bodyMedium,
                          ),
                        ),

                      // ── Organiser ──────────────────────────
                      _Section(
                        title: 'Organiser',
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => context.push(
                                  '/users/${game.organizer.id}'),
                              child: CircleAvatar(
                                radius: 20,
                                backgroundColor:
                                    AppColors.primary.withOpacity(0.15),
                                child: Text(
                                  game.organizer.firstName[0]
                                      .toUpperCase(),
                                  style: AppTextStyles.titleSmall
                                      .copyWith(
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  game.organizer.fullName,
                                  style: AppTextStyles.titleSmall,
                                ),
                                Text(
                                  '@${game.organizer.username}',
                                  style: AppTextStyles.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // ── Players ────────────────────────────
                      _Section(
                        title: 'Players',
                        trailing: Text(
                          '${game.approvedCount}/${game.maxPlayers}',
                          style: AppTextStyles.labelMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                        child: Column(
                          children: [
                            PlayerAvatarRow(
                              players: game.players,
                              maxPlayers: game.maxPlayers,
                            ),
                            const SizedBox(height: 12),
                            _PlayerList(
                              game: game,
                              isOrganizer: isOrganizer,
                              currentUserId:
                                  currentUser?.id,
                              onApprove: (uid) => ref
                                  .read(gameActionsProvider(gameId)
                                      .notifier)
                                  .approvePlayer(uid),
                              onKick: (uid) => ref
                                  .read(gameActionsProvider(gameId)
                                      .notifier)
                                  .kickPlayer(uid),
                            ),
                          ],
                        ),
                      ),

                      // ── Result (if completed) ──────────────
                      if (game.isCompleted && game.result != null)
                        _Section(
                          title: 'Match Result',
                          child: _ResultCard(result: game.result!),
                        ),

                      // ── Tags ───────────────────────────────
                      if (game.tags.isNotEmpty)
                        _Section(
                          title: 'Tags',
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: game.tags
                                .map((t) => Chip(label: Text(t)))
                                .toList(),
                          ),
                        ),

                      const SizedBox(height: 100),
                    ]),
                  ),
                ),
              ],
            ),

            // ── Action button ──────────────────────────────────
            bottomNavigationBar: currentUser != null && !game.isCancelled
                ? _BottomActionBar(
                    game: game,
                    myPlayer: myPlayer,
                    isOrganizer: isOrganizer,
                    actionsState: actionsState,
                    onJoin: () => ref
                        .read(gameActionsProvider(gameId).notifier)
                        .join(),
                    onLeave: () => ref
                        .read(gameActionsProvider(gameId).notifier)
                        .leave(),
                    onOpenChat: () =>
                        context.push('/chats/${game.groupChatId}'),
                  )
                : null,
          ),
        );
      },
    );
  }
}

// ── Coloured sliver app bar ───────────────────────────────────────────────────
class _GameDetailAppBar extends StatelessWidget {
  const _GameDetailAppBar({required this.game});
  final GameModel game;

  Color get _sportColor => switch (game.sport.toLowerCase()) {
        'football' || 'soccer' => AppColors.footballBadge,
        'basketball' => AppColors.basketballBadge,
        'tennis' => AppColors.tennisBadge,
        'running' => AppColors.runningBadge,
        _ => AppColors.defaultBadge,
      };

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: _sportColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: _sportColor.withOpacity(0.9),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      Text(
                        _sportEmoji(game.sport),
                        style: const TextStyle(fontSize: 32),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          game.title,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 8,
                    children: [
                      _HeaderBadge(
                        label: game.sport,
                        color: Colors.white24,
                      ),
                      _HeaderBadge(
                        label: game.requiredSkillLevel[0]
                                .toUpperCase() +
                            game.requiredSkillLevel.substring(1),
                        color: Colors.white24,
                      ),
                      _StatusBadge(status: game.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderBadge extends StatelessWidget {
  const _HeaderBadge({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bgColor, label) = switch (status) {
      'open' => (AppColors.success, 'Open'),
      'full' => (AppColors.warning, 'Full'),
      'in_progress' => (AppColors.info, 'Live'),
      'completed' => (AppColors.grey500, 'Completed'),
      'cancelled' => (AppColors.error, 'Cancelled'),
      _ => (AppColors.grey500, status),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          fontFamily: 'Inter',
        ),
      ),
    );
  }
}

// ── Section wrapper ───────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTextStyles.titleSmall),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// ── Info card ─────────────────────────────────────────────────────────────────
class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: AppTextStyles.titleSmall,
              textAlign: TextAlign.center),
          Text(label,
              style: AppTextStyles.labelSmall,
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── Player list ───────────────────────────────────────────────────────────────
class _PlayerList extends StatelessWidget {
  const _PlayerList({
    required this.game,
    required this.isOrganizer,
    required this.currentUserId,
    required this.onApprove,
    required this.onKick,
  });

  final GameModel game;
  final bool isOrganizer;
  final String? currentUserId;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onKick;

  @override
  Widget build(BuildContext context) {
    final approved =
        game.players.where((p) => p.isApproved).toList();
    final pending =
        game.players.where((p) => p.isPending).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (approved.isNotEmpty) ...[
          Text('Approved',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.success)),
          const SizedBox(height: 6),
          ...approved.map((p) => _PlayerTile(
                player: p,
                isCurrentUser: p.userId == currentUserId,
                isOrganizer: isOrganizer,
                onApprove: null,
                onKick: () => onKick(p.userId),
              )),
        ],
        if (isOrganizer && pending.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text('Pending requests',
              style: AppTextStyles.labelMedium
                  .copyWith(color: AppColors.warning)),
          const SizedBox(height: 6),
          ...pending.map((p) => _PlayerTile(
                player: p,
                isCurrentUser: p.userId == currentUserId,
                isOrganizer: isOrganizer,
                onApprove: () => onApprove(p.userId),
                onKick: () => onKick(p.userId),
              )),
        ],
      ],
    );
  }
}

class _PlayerTile extends StatelessWidget {
  const _PlayerTile({
    required this.player,
    required this.isCurrentUser,
    required this.isOrganizer,
    required this.onApprove,
    required this.onKick,
  });

  final GamePlayer player;
  final bool isCurrentUser;
  final bool isOrganizer;
  final VoidCallback? onApprove;
  final VoidCallback? onKick;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: CircleAvatar(
        radius: 18,
        backgroundColor: AppColors.primary.withOpacity(0.12),
        child: Text(
          player.displayName[0].toUpperCase(),
          style: AppTextStyles.labelMedium
              .copyWith(color: AppColors.primary),
        ),
      ),
      title: Text(
        player.displayName + (isCurrentUser ? ' (You)' : ''),
        style: AppTextStyles.bodyMedium,
      ),
      subtitle: Text('@${player.username}',
          style: AppTextStyles.bodySmall),
      trailing: isOrganizer && !isCurrentUser
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onApprove != null)
                  IconButton(
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        color: AppColors.success, size: 20),
                    onPressed: onApprove,
                    tooltip: 'Approve',
                  ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline_rounded,
                      color: AppColors.error, size: 20),
                  onPressed: onKick,
                  tooltip: 'Kick',
                ),
              ],
            )
          : null,
    );
  }
}

// ── Result card ───────────────────────────────────────────────────────────────
class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});
  final GameResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (result.score != null)
          Text('Score: ${result.score}',
              style: AppTextStyles.titleMedium),
        if (result.winner != null)
          Text('Winner: ${result.winner}',
              style: AppTextStyles.bodyMedium),
        if (result.notes != null)
          Text(result.notes!, style: AppTextStyles.bodyMedium),
      ],
    );
  }
}

// ── Bottom action bar ─────────────────────────────────────────────────────────
class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.game,
    required this.myPlayer,
    required this.isOrganizer,
    required this.actionsState,
    required this.onJoin,
    required this.onLeave,
    required this.onOpenChat,
  });

  final GameModel game;
  final GamePlayer? myPlayer;
  final bool isOrganizer;
  final GameActionsState actionsState;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onOpenChat;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        12 + MediaQuery.paddingOf(context).bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.grey200)),
      ),
      child: Row(
        spacing: 12,
        children: [
          // Chat button (if in game)
          if (game.groupChatId != null && myPlayer?.isApproved == true)
            Expanded(
              flex: 1,
              child: BbButton(
                label: 'Chat',
                onPressed: onOpenChat,
                variant: BbButtonVariant.outlined,
                icon: Icons.chat_outlined,
              ),
            ),

          // Join / Leave / Status button
          Expanded(
            flex: 2,
            child: _buildMainAction(),
          ),
        ],
      ),
    );
  }

  Widget _buildMainAction() {
    if (isOrganizer) {
      return const BbButton(
        label: 'Manage (Organiser)',
        onPressed: null,
        variant: BbButtonVariant.outlined,
        icon: Icons.military_tech_rounded,
      );
    }

    if (myPlayer == null) {
      if (game.isFull) {
        return const BbButton(
          label: 'Game is Full',
          onPressed: null,
          variant: BbButtonVariant.outlined,
        );
      }
      return BbButton(
        label: 'Request to Join',
        onPressed: game.isUpcoming ? onJoin : null,
        isLoading: actionsState.isJoining,
      );
    }

    if (myPlayer!.isPending) {
      return BbButton(
        label: 'Request Pending…',
        onPressed: onLeave,
        variant: BbButtonVariant.outlined,
        isLoading: actionsState.isLeaving,
      );
    }

    if (myPlayer!.isApproved) {
      return BbButton(
        label: 'Leave Game',
        onPressed: game.isUpcoming ? onLeave : null,
        variant: BbButtonVariant.danger,
        isLoading: actionsState.isLeaving,
      );
    }

    return const SizedBox.shrink();
  }
}

String _sportEmoji(String sport) {
  return switch (sport.toLowerCase()) {
    'football' || 'soccer' => '⚽',
    'basketball' => '🏀',
    'tennis' => '🎾',
    'running' => '🏃',
    'swimming' => '🏊',
    'cycling' => '🚴',
    'volleyball' => '🏐',
    'cricket' => '🏏',
    _ => '🏅',
  };
}
