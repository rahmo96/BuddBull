import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/network/api_endpoints.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/widgets/player_slot_row.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/profile/presentation/widgets/bb_profile_avatar.dart';
import 'package:buddbull/features/rating/data/models/rating_model.dart';
import 'package:buddbull/features/rating/presentation/widgets/rate_player_sheet.dart';
import 'package:buddbull/features/rating/presentation/widgets/rating_stars.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';

class GameDetailScreen extends ConsumerStatefulWidget {
  const GameDetailScreen({super.key, required this.gameId});
  final String gameId;

  @override
  ConsumerState<GameDetailScreen> createState() => _GameDetailScreenState();
}

class _GameDetailScreenState extends ConsumerState<GameDetailScreen> {
  /// Latches once we've observed at least one pending rating for this game.
  /// We only auto-navigate home when an existing queue drains — never on the
  /// initial load of a game that was already fully rated.
  bool _hadPendingRatings = false;

  /// Prevents the delayed pop from firing more than once after the queue
  /// empties (the provider can emit multiple loading → data transitions while
  /// other refreshes are in flight).
  bool _autoPoppedHome = false;

  /// One-shot guard: once we've seen the game in `completed` state we kick
  /// `pendingRatingsProvider` so the rate button can appear immediately even
  /// when the queue was loaded before the organizer marked the game complete.
  bool _didRefreshPendingOnComplete = false;

  @override
  Widget build(BuildContext context) {
    final gameId = widget.gameId;
    final gameAsync = ref.watch(gameDetailProvider(gameId));
    final actionsState = ref.watch(gameActionsProvider(gameId));
    final currentUser = ref.watch(authProvider).user;

    // Refresh the pending-rating queue the first time we observe this game as
    // completed. Without this, the bottom bar would stay on "Leave Game" /
    // empty until the user pulled to refresh, because the queue may have been
    // cached before the game's status flipped.
    final loadedGame = gameAsync.valueOrNull;
    if (loadedGame != null &&
        loadedGame.isCompleted &&
        !_didRefreshPendingOnComplete) {
      _didRefreshPendingOnComplete = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.invalidate(pendingRatingsProvider);
      });
    }

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

    // ── Auto-return home when this game's rating queue drains ────────────────
    // Fires when the user finishes the last pending rating for this game *or*
    // chooses "Don't rate this game" (which dismisses the queue server-side).
    // A 500ms delay lets the rate sheet animate out and the success snackbar
    // register before we leave the screen.
    ref.listen<AsyncValue<List<PendingRatingItem>>>(pendingRatingsProvider,
        (prev, next) {
      if (_autoPoppedHome) return;

      final game = gameAsync.valueOrNull;
      if (game == null || !game.isCompleted) return;

      final user = ref.read(authProvider).user;
      if (user == null) return;
      final myPlayer = game.getPlayer(user.id);
      // Only participants can have ratings to do; organizers who weren't on
      // the pitch should stay on the detail screen.
      if (myPlayer?.isApproved != true) return;

      final hasPendingNow = next.valueOrNull?.any(
            (e) => e.gameId == gameId && e.pendingPlayers.isNotEmpty,
          ) ??
          false;

      if (hasPendingNow) {
        _hadPendingRatings = true;
        return;
      }

      // Only act on freshly loaded data — never the AsyncLoading snapshot
      // that retains the cached value during a refetch.
      final settled = next is AsyncData<List<PendingRatingItem>>;
      if (!settled || !_hadPendingRatings) return;

      _autoPoppedHome = true;
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!mounted) return;
        if (!context.mounted) return;
        // Prefer popping (returns the user to wherever they came from); fall
        // back to navigating to home when this screen is the root entry.
        if (context.canPop()) {
          context.pop();
        } else {
          context.go(Routes.home);
        }
      });
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
        final user = currentUser;
        final myPlayer =
            user != null ? game.getPlayer(user.id) : null;
        final isOrganizer = user?.id == game.organizer.id;
        final pendingRatingsAsync = ref.watch(pendingRatingsProvider);
        final showBottomBar = user != null &&
            !game.isCancelled &&
            _gameDetailBottomBarHasContent(
              game: game,
              myPlayer: myPlayer,
              isOrganizer: isOrganizer,
              pendingRatings: pendingRatingsAsync,
            );

        return LoadingOverlay(
          isLoading: actionsState.isProcessing || actionsState.isCompleting,
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
                      _StaticLocationMap(location: game.location),

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
                                  '/profile/${game.organizer.id}'),
                              child: BbProfileAvatar(
                                profilePicture: game.organizer.profilePicture,
                                initials:
                                    '${game.organizer.firstName[0]}${game.organizer.lastName[0]}',
                                radius: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
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
                                  if (game.organizer.averageRating > 0) ...[
                                    const SizedBox(height: 2),
                                    _NameRatingBadge(
                                      rating: game.organizer.averageRating,
                                    ),
                                  ],
                                ],
                              ),
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
                            if (game.isCompleted &&
                                myPlayer?.isApproved == true)
                              const _RatePromptBanner(),
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
                              onRate: (p) =>
                                  _openRatePlayerSheet(context, gameId, p),
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
            bottomNavigationBar: showBottomBar
                ? _BottomActionBar(
                    gameId: gameId,
                    game: game,
                    myPlayer: myPlayer,
                    isOrganizer: isOrganizer,
                    currentUserId: user.id,
                    actionsState: actionsState,
                    onJoin: () => ref
                        .read(gameActionsProvider(gameId).notifier)
                        .join(),
                    onLeave: () => ref
                        .read(gameActionsProvider(gameId).notifier)
                        .leave(),
                    onOpenChat: () =>
                        context.push('/chats/${game.groupChatId}'),
                    onManage: () => _showManageSheet(context, ref, gameId),
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

class _StaticLocationMap extends StatelessWidget {
  const _StaticLocationMap({required this.location});

  final GameLocation location;

  @override
  Widget build(BuildContext context) {
    final lat = location.latitude;
    final lng = location.longitude;
    if (lat == null || lng == null) return const SizedBox.shrink();

    final imageUrl = '${ApiEndpoints.baseUrl}'
        '${ApiEndpoints.mapsStatic(lat: lat, lng: lng)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      clipBehavior: Clip.antiAlias,
      child: AspectRatio(
        aspectRatio: 16 / 7,
        child: Image.network(
          imageUrl,
          fit: BoxFit.cover,
          errorBuilder: (context, _, __) => Container(
            color: AppColors.grey100,
            alignment: Alignment.center,
            child: Text(
              'Map preview unavailable',
              style: AppTextStyles.bodySmall,
            ),
          ),
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator());
          },
        ),
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
    required this.onRate,
  });

  final GameModel game;
  final bool isOrganizer;
  final String? currentUserId;
  final ValueChanged<String> onApprove;
  final ValueChanged<String> onKick;
  final ValueChanged<GamePlayer> onRate;

  @override
  Widget build(BuildContext context) {
    final approved =
        game.players.where((p) => p.isApproved).toList();
    final pending =
        game.players.where((p) => p.isPending).toList();

    // Current viewer is an approved player → eligible to rate teammates.
    final viewerIsApproved = currentUserId != null &&
        approved.any((p) => p.userId == currentUserId);
    final canRate = game.isCompleted && viewerIsApproved;

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
                canRate: canRate,
                onApprove: null,
                onKick: () => onKick(p.userId),
                onRate: () => onRate(p),
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
                canRate: false,
                onApprove: () => onApprove(p.userId),
                onKick: () => onKick(p.userId),
                onRate: () => onRate(p),
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
    required this.canRate,
    required this.onApprove,
    required this.onKick,
    required this.onRate,
  });

  final GamePlayer player;
  final bool isCurrentUser;
  final bool isOrganizer;
  final bool canRate;
  final VoidCallback? onApprove;
  final VoidCallback? onKick;
  final VoidCallback onRate;

  String get _initials {
    final fn = player.firstName;
    final ln = player.lastName;
    if (fn != null && fn.isNotEmpty && ln != null && ln.isNotEmpty) {
      return '${fn[0]}${ln[0]}';
    }
    if (fn != null && fn.isNotEmpty) return fn[0];
    if (player.username.isEmpty) return '?';
    return player.username[0];
  }

  @override
  Widget build(BuildContext context) {
    // Rating UI is hidden for the viewer's own row (no self-rating).
    final showRateButton = canRate && !isCurrentUser && player.isApproved;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      dense: true,
      leading: BbProfileAvatar(
        profilePicture: player.profilePicture,
        initials: _initials,
        radius: 18,
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              player.displayName + (isCurrentUser ? ' (You)' : ''),
              style: AppTextStyles.bodyMedium,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (player.averageRating > 0) ...[
            const SizedBox(width: 6),
            RatingStars(rating: player.averageRating, size: 12),
            const SizedBox(width: 4),
            Text(
              player.averageRating.toStringAsFixed(1),
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
      subtitle: Text('@${player.username}',
          style: AppTextStyles.bodySmall),
      trailing: _buildTrailing(showRateButton),
    );
  }

  Widget? _buildTrailing(bool showRateButton) {
    final hasOrganizerControls = isOrganizer && !isCurrentUser;
    if (!hasOrganizerControls && !showRateButton) return null;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showRateButton)
          TextButton.icon(
            onPressed: onRate,
            icon: const Icon(Icons.star_outline_rounded, size: 18),
            label: const Text('Rate'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.secondary,
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
            ),
          ),
        if (hasOrganizerControls) ...[
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
      ],
    );
  }
}

// ── Post-game "rate your teammates" prompt ───────────────────────────────────
class _RatePromptBanner extends StatelessWidget {
  const _RatePromptBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.secondary.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.star_rounded,
              color: AppColors.secondary, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Rate participants below to share how the game went.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Inline rating badge (stars + numeric average) ─────────────────────────────
class _NameRatingBadge extends StatelessWidget {
  const _NameRatingBadge({required this.rating});
  final double rating;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        RatingStars(rating: rating, size: 12),
        const SizedBox(width: 4),
        Text(
          rating.toStringAsFixed(1),
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
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

bool _gameDetailBarShowsChat(GameModel game, GamePlayer? myPlayer) =>
    game.groupChatId != null && myPlayer?.isApproved == true;

/// While [pendingRatings] is still loading, assume there may be pending
/// opponents so the "Rate Participants" affordance stays visible until the
/// network round-trip settles (avoids a one-frame flash to "all done").
bool _hasPendingRatingsForGame(
  AsyncValue<List<PendingRatingItem>> pendingRatings,
  String gameId,
) {
  return pendingRatings.when(
    data: (list) => list.any(
      (e) => e.gameId == gameId && e.pendingPlayers.isNotEmpty,
    ),
    loading: () => true,
    error: (_, __) => true,
  );
}

/// Whether the bottom bar should render at all (avoids an empty padded strip).
bool _gameDetailBottomBarHasContent({
  required GameModel game,
  required GamePlayer? myPlayer,
  required bool isOrganizer,
  required AsyncValue<List<PendingRatingItem>> pendingRatings,
}) {
  if (_gameDetailBarShowsChat(game, myPlayer)) return true;

  if (isOrganizer && !game.isCompleted) return true;
  if (isOrganizer && game.isCompleted) {
    if (myPlayer?.isApproved == true &&
        _hasPendingRatingsForGame(pendingRatings, game.id)) {
      return true;
    }
    return true;
  }
  if (myPlayer == null) return true;
  if (myPlayer.isPending) return true;
  if (myPlayer.isApproved && !game.isCompleted) return true;
  // Approved player on a completed game: always render the bar so the
  // "Rate Participants" affordance is visible immediately. The picker handles
  // the edge case where the queue is empty (it shows a friendly snackbar).
  if (myPlayer.isApproved && game.isCompleted) return true;
  return false;
}

// ── Bottom action bar ─────────────────────────────────────────────────────────
class _BottomActionBar extends ConsumerWidget {
  const _BottomActionBar({
    required this.gameId,
    required this.game,
    required this.myPlayer,
    required this.isOrganizer,
    required this.currentUserId,
    required this.actionsState,
    required this.onJoin,
    required this.onLeave,
    required this.onOpenChat,
    required this.onManage,
  });

  final String gameId;
  final GameModel game;
  final GamePlayer? myPlayer;
  final bool isOrganizer;
  final String currentUserId;
  final GameActionsState actionsState;
  final VoidCallback onJoin;
  final VoidCallback onLeave;
  final VoidCallback onOpenChat;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasChat =
        game.groupChatId != null && myPlayer?.isApproved == true;
    final main = _buildMainAction(context, ref);

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
          if (hasChat)
            Expanded(
              flex: 1,
              child: BbButton(
                label: 'Chat',
                onPressed: onOpenChat,
                variant: BbButtonVariant.outlined,
                icon: Icons.chat_outlined,
              ),
            ),
          if (main != null)
            Expanded(
              flex: hasChat ? 2 : 1,
              child: main,
            ),
        ],
      ),
    );
  }

  /// Primary / leave / join / manage slot. Returns `null` only when no action
  /// makes sense (e.g. cancelled game).
  Widget? _buildMainAction(
    BuildContext context,
    WidgetRef ref,
  ) {
    if (isOrganizer) {
      if (game.isCompleted) {
        // Organizer who played on the pitch should always get the rate CTA
        // as soon as the game flips to completed — independent of whether
        // `pendingRatingsProvider` has refetched yet. The picker refreshes
        // the queue itself and falls back to `game.players` if needed.
        if (myPlayer?.isApproved == true) {
          return BbButton(
            label: 'Rate Participants',
            onPressed: () => _openRateParticipantsPicker(
              context,
              ref,
              game,
              gameId,
              currentUserId,
            ),
            variant: BbButtonVariant.primary,
            icon: Icons.star_rate_rounded,
          );
        }
        return const BbButton(
          label: 'Game Completed',
          onPressed: null,
          variant: BbButtonVariant.outlined,
          icon: Icons.check_circle_outline_rounded,
        );
      }
      return BbButton(
        label: 'Manage (Organiser)',
        onPressed: onManage,
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
      if (game.isCompleted) {
        // The moment the game flips to completed, "Leave Game" must swap to
        // "Rate Participants" for every approved player — regardless of the
        // pending-rating provider's current state. The picker handles the
        // (rare) case where the queue is genuinely empty.
        return BbButton(
          label: 'Rate Participants',
          onPressed: () => _openRateParticipantsPicker(
            context,
            ref,
            game,
            gameId,
            currentUserId,
          ),
          variant: BbButtonVariant.primary,
          icon: Icons.star_rate_rounded,
        );
      }
      return BbButton(
        label: 'Leave Game',
        onPressed: game.isUpcoming ? onLeave : null,
        variant: BbButtonVariant.danger,
        isLoading: actionsState.isLeaving,
      );
    }

    return null;
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

Future<void> _showManageSheet(
  BuildContext context,
  WidgetRef ref,
  String gameId,
) async {
  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Edit Game'),
            onTap: () {
              Navigator.pop(sheetCtx);
              if (!context.mounted) return;
              context.push('/games/$gameId/edit');
            },
          ),
          ListTile(
            leading: const Icon(Icons.emoji_events_outlined,
                color: AppColors.success),
            title: const Text('Complete Game'),
            subtitle: const Text(
              'Mark the game as finished and open ratings for participants.',
            ),
            onTap: () async {
              final confirmed = await _confirmComplete(context);
              if (!confirmed || !context.mounted) return;

              Navigator.pop(sheetCtx);

              final ok = await ref
                  .read(gameActionsProvider(gameId).notifier)
                  .completeGame();
              if (!ok || !context.mounted) return;

              // Success snackbar is fired by the listener in build().
            },
          ),
          ListTile(
            leading: const Icon(Icons.cancel_outlined, color: AppColors.error),
            title: const Text('Cancel Game'),
            onTap: () async {
              // Keep a strict teardown order to avoid "used after disposed" / "attached is not true".
              final confirmed = await _confirmCancel(context);
              if (!confirmed || !context.mounted) return;

              final reason = await _askCancelReason(context);
              if (reason == null || reason.trim().isEmpty || !context.mounted) return;

              // Keyboard cleanup before any async/network work.
              FocusScope.of(context).unfocus();

              // Close the bottom sheet BEFORE triggering navigation.
              Navigator.pop(sheetCtx);

              try {
                await ref.read(gameRepositoryProvider).cancelGame(
                      gameId,
                      reason: reason.trim(),
                    );
                ref.invalidate(gameDetailProvider(gameId));
                ref.invalidate(myGamesProvider);
                ref.invalidate(calendarGamesProvider);
                if (!context.mounted) return;

                showSuccessSnackBar(context, 'Game cancelled.');

                // Small delay lets route stack settle after modal teardown.
                await Future<void>.delayed(const Duration(milliseconds: 80));
                if (!context.mounted) return;
                context.go(Routes.home);
              } catch (e) {
                if (!context.mounted) return;
                showErrorSnackBar(context, e.toString());
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

Future<bool> _confirmCancel(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Cancel game?'),
      content: const Text('This will mark the game as cancelled for all players.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('No'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Yes, cancel'),
        ),
      ],
    ),
  );
  return res ?? false;
}

Future<bool> _confirmComplete(BuildContext context) async {
  final res = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Complete game?'),
      content: const Text(
        'This marks the game as finished, updates player stats, and unlocks '
        'rating for all approved players. This action cannot be undone.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Not yet'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: AppColors.success),
          child: const Text('Mark completed'),
        ),
      ],
    ),
  );
  return res ?? false;
}

class _RatePickerEntry {
  const _RatePickerEntry({required this.rateeId, required this.displayName});
  final String rateeId;
  final String displayName;
}

/// Lists opponents the viewer still owes a rating for this [gameId], then
/// opens [RatePlayerSheet] for the chosen player.
Future<void> _openRateParticipantsPicker(
  BuildContext context,
  WidgetRef ref,
  GameModel game,
  String gameId,
  String currentUserId,
) async {
  ref.invalidate(pendingRatingsProvider);
  List<PendingRatingItem> list;
  try {
    list = await ref.read(pendingRatingsProvider.future);
  } catch (_) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not load pending ratings. Pull to refresh and try again.'),
        ),
      );
    }
    return;
  }

  PendingRatingItem? found;
  for (final e in list) {
    if (e.gameId == gameId) {
      found = e;
      break;
    }
  }

  final entries = <_RatePickerEntry>[];
  if (found != null) {
    for (final raw in found.pendingPlayers) {
      final id = (raw['_id'] ?? raw['id'] ?? '').toString();
      if (id.isEmpty || id == currentUserId) continue;
      final fn = raw['firstName']?.toString() ?? '';
      final ln = raw['lastName']?.toString() ?? '';
      final un = raw['username']?.toString() ?? '';
      final display = (fn.isNotEmpty && ln.isNotEmpty)
          ? '$fn $ln'
          : (un.isNotEmpty ? un : 'Player');
      entries.add(_RatePickerEntry(rateeId: id, displayName: display));
    }
  }

  if (entries.isEmpty) {
    for (final p in game.players.where(
      (p) => p.isApproved && p.userId != currentUserId,
    )) {
      entries.add(
        _RatePickerEntry(rateeId: p.userId, displayName: p.displayName),
      );
    }
  }

  if (entries.isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Everyone in this game has been rated.'),
          backgroundColor: AppColors.success,
        ),
      );
    }
    return;
  }

  if (!context.mounted) return;

  if (entries.length == 1) {
    final only = entries.first;
    await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => RatePlayerSheet(
        rateeId: only.rateeId,
        rateeDisplayName: only.displayName,
        gameId: gameId,
      ),
    );
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetCtx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
            child: Text(
              'Rate a participant',
              style: AppTextStyles.titleSmall,
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text(
              game.title,
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.textSecondary),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entries.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, color: AppColors.grey200),
            itemBuilder: (_, i) {
              final e = entries[i];
              return ListTile(
                title: Text(e.displayName, style: AppTextStyles.bodyMedium),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                ),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  if (!context.mounted) return;
                  await showModalBottomSheet<bool>(
                    context: context,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => RatePlayerSheet(
                      rateeId: e.rateeId,
                      rateeDisplayName: e.displayName,
                      gameId: gameId,
                    ),
                  );
                },
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(sheetCtx);
                if (!context.mounted) return;
                try {
                  await dismissGameRatingQueue(ref, gameId);
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'You will not be prompted to rate this game.',
                      ),
                    ),
                  );
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(e.toString())),
                    );
                  }
                }
              },
              child: Text(
                "Don't rate this game",
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondary),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}

/// Opens the post-game rating bottom sheet for a single ratee.
Future<void> _openRatePlayerSheet(
  BuildContext context,
  String gameId,
  GamePlayer player,
) async {
  await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => RatePlayerSheet(
      rateeId: player.userId,
      rateeDisplayName: player.displayName,
      gameId: gameId,
    ),
  );
}

Future<String?> _askCancelReason(BuildContext context) async {
  final ctrl = TextEditingController();
  final res = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Reason for cancellation'),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        maxLength: 300,
        decoration: const InputDecoration(
          hintText: 'e.g. Weather, venue issue, not enough players…',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Back'),
        ),
        FilledButton(
          onPressed: () {
            FocusScope.of(ctx).unfocus();
            Navigator.pop(ctx, ctrl.text);
          },
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: const Text('Cancel game'),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return res;
}
