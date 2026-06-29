import 'package:buddbull/core/constants/app_assets.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/date_format_utils.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/presentation/widgets/game_card.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:buddbull/features/home/presentation/widgets/collapsing_home_search.dart';
import 'package:buddbull/features/notifications/providers/notification_provider.dart';
import 'package:buddbull/features/performance/presentation/widgets/streak_banner.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/features/profile/presentation/widgets/stats_card.dart';
import 'package:buddbull/features/rating/data/models/rating_model.dart';
import 'package:buddbull/features/rating/providers/rating_provider.dart';
import 'package:buddbull/features/search/presentation/widgets/search_transition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final pendingAsync = ref.watch(pendingRatingsProvider);
    final statsAsync = ref.watch(performanceStatsProvider);
    final l10n = context.l10n;

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? l10n.greetingGoodMorning
        : hour < 17
            ? l10n.greetingGoodAfternoon
            : l10n.greetingGoodEvening;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(calendarGamesProvider);
          ref.invalidate(performanceStatsProvider);
          ref.invalidate(pendingRatingsProvider);
          ref.invalidate(myGamesProvider);
          ref.invalidate(exploreGamesProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Gradient header ────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.background,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              automaticallyImplyLeading: false,
              flexibleSpace: _HomeHeaderFlexibleSpace(
                greeting: greeting,
                firstName: user?.firstName,
                notificationBell: _NotificationBellAction(
                  onTap: () => context.push('/notifications'),
                ),
                onCalendarTap: () => context.push('/games/calendar'),
                onSearchTap: (origin) => openGlobalSearch(context, origin: origin),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Quick stats ──────────────────────────
                  if (user?.stats != null) ...[
                    Row(
                      spacing: 8,
                      children: [
                        Expanded(
                          child: StatsCard(
                            value: user!.stats!.gamesPlayed.toString(),
                            label: l10n.statGames,
                            icon: Icons.sports_soccer_rounded,
                            accentColor: AppColors.metricGamesAccent,
                            backgroundColor: AppColors.metricGamesBg,
                          ),
                        ),
                        Expanded(
                          child: StatsCard(
                            value: user.stats!.averageRating.toStringAsFixed(1),
                            label: l10n.statRating,
                            icon: Icons.star_rounded,
                            accentColor: AppColors.metricRatingAccent,
                            backgroundColor: AppColors.metricRatingBg,
                          ),
                        ),
                        Expanded(
                          child: StatsCard(
                            value: l10n.streakDaysSuffix(user.stats!.currentStreak),
                            label: l10n.statStreak,
                            icon: Icons.local_fire_department_rounded,
                            accentColor: AppColors.metricStreakAccent,
                            backgroundColor: AppColors.metricStreakBg,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Streak banner ────────────────────────
                  statsAsync.maybeWhen(
                    data: (stats) => Column(
                      children: [
                        StreakBanner(
                          currentStreak: stats.currentStreak,
                          longestStreak: stats.longestStreak,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                    orElse: () => const SizedBox.shrink(),
                  ),

                  // ── My Upcoming Games ─────────────────────
                  _SectionHeader(
                    title: l10n.sectionMyUpcomingGames,
                    actionLabel: l10n.actionSeeAll,
                    onAction: () => context.go('/games'),
                  ),
                  const SizedBox(height: 10),
                  _UpcomingMineStrip(
                    pendingAsync: pendingAsync,
                    onSeeAll: () => context.go('/games'),
                    onTap: (id) => context.push('/games/$id'),
                  ),
                  const SizedBox(height: 20),

                  // ── Explore Near You ──────────────────────
                  _SectionHeader(
                    title: l10n.sectionExploreNearYou,
                    actionLabel: l10n.actionBrowseAll,
                    onAction: () => context.go('/games'),
                  ),
                  const SizedBox(height: 10),
                  _ExploreStrip(
                    currentUserId: user?.id,
                    onBrowse: () => context.go('/games'),
                    onTap: (id) => context.push('/games/$id'),
                  ),
                  const SizedBox(height: 20),

                  // ── Quick actions ─────────────────────────
                  _SectionHeader(title: l10n.sectionQuickActions),
                  const SizedBox(height: 10),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.search_rounded,
                          label: l10n.quickActionFindGame,
                          color: AppColors.primary,
                          onTap: () => context.go('/games'),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.add_rounded,
                          label: l10n.quickActionLogSession,
                          color: AppColors.success,
                          onTap: () => context
                              .push('/performance/log/create'),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.sports_score_rounded,
                          label: l10n.quickActionCreateGame,
                          color: AppColors.secondary,
                          onTap: () => context.push('/games/create'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Email verification warning ─────────────
                  // Removed: do not gate features on verification state.

                  // ── Recent activity ───────────────────────
                  _SectionHeader(
                    title: l10n.sectionRecentActivity,
                    actionLabel: l10n.actionSeeAll,
                    onAction: () => context.go('/performance'),
                  ),
                  const SizedBox(height: 10),
                  ref.watch(performanceLogsProvider).when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) =>
                            const SizedBox.shrink(),
                        data: (logs) {
                          if (logs.isEmpty) {
                            return _EmptySection(
                              emoji: '📊',
                              message: l10n.emptyNoRecentSessions,
                              actionLabel: l10n.actionLogSession,
                              onAction: () => context.push(
                                  '/performance/log/create'),
                            );
                          }
                          return Column(
                            children: logs
                                .take(3)
                                .map((log) => Container(
                                      key: ValueKey(log.id),
                                      margin: const EdgeInsets
                                          .only(bottom: 8),
                                      padding:
                                          const EdgeInsets.all(
                                              12),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius:
                                            BorderRadius.circular(
                                                12),
                                        border: Border.all(
                                            color: AppColors
                                                .grey200),
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            _sportEmoji(
                                                log.sport),
                                            style:
                                                const TextStyle(
                                                    fontSize:
                                                        20),
                                          ),
                                          const SizedBox(
                                              width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                              children: [
                                                Text(
                                                  log.sport,
                                                  style: AppTextStyles
                                                      .titleSmall,
                                                ),
                                                Text(
                                                  AppDateFormat.mediumDate(context, log.loggedAt),
                                                  style: AppTextStyles
                                                      .bodySmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (log.outcome !=
                                              null)
                                            _OutcomeIcon(
                                                outcome:
                                                    log.outcome!),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          );
                        },
                      ),

                  SizedBox(height: HomeScaffold.navBottomInset(context)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── My Upcoming Games strip ───────────────────────────────────────────────────
//
// Sources from `myGamesProvider` so we strictly show games the user is a
// participant in (backend already filters to `status: 'approved'` via
// `$elemMatch`). Completed games are listed only while ratings are still
// pending; the strip stays aligned with GET /ratings/pending.
class _UpcomingMineStrip extends ConsumerWidget {
  const _UpcomingMineStrip({
    required this.pendingAsync,
    required this.onSeeAll,
    required this.onTap,
  });

  final AsyncValue<List<PendingRatingItem>> pendingAsync;
  final VoidCallback onSeeAll;
  final void Function(String gameId) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final myGamesAsync = ref.watch(myGamesProvider);
    return myGamesAsync.when(
      loading: _UpcomingShimmer.new,
      error: (_, __) => _EmptySection(
        emoji: '📅',
        message: l10n.emptyNoUpcomingGames,
        actionLabel: l10n.actionBrowseGames,
        onAction: onSeeAll,
      ),
      data: (games) {
        final pendingLoaded = pendingAsync.hasValue;
        final pendingIds =
            pendingAsync.valueOrNull?.map((e) => e.gameId).toSet() ??
                <String>{};

        // Upcoming / in-progress, plus completed games only while this user
        // still owes peer ratings (aligned with GET /ratings/pending).
        final strip = games.where((g) {
          if (g.isCancelled) return false;
          if (g.isUpcoming || g.isInProgress) return true;
          if (g.isCompleted) {
            return pendingLoaded && pendingIds.contains(g.id);
          }
          return false;
        }).toList()
          ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        final shortlist = strip.take(8).toList();

        if (shortlist.isEmpty) {
          return _EmptySection(
            emoji: '📅',
            message: l10n.emptyNoUpcomingGames,
            actionLabel: l10n.actionBrowseGames,
            onAction: onSeeAll,
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: shortlist.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final game = shortlist[i];
              return GameCard(
                key: ValueKey('upcoming_${game.id}'),
                game: game,
                compact: true,
                onTap: () => onTap(game.id),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Explore Near You strip ────────────────────────────────────────────────────
//
// Renders public games the viewer is NOT already participating in, biased
// toward their home city. We deliberately filter out the viewer's own
// approved/pending/invited slots client-side as a defence-in-depth measure
// (server is the source of truth) so a freshly-joined game vanishes from
// "Explore" right after Join without waiting for a `searchGames` refetch.
class _ExploreStrip extends ConsumerWidget {
  const _ExploreStrip({
    required this.currentUserId,
    required this.onBrowse,
    required this.onTap,
  });

  final String? currentUserId;
  final VoidCallback onBrowse;
  final void Function(String gameId) onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final exploreAsync = ref.watch(exploreGamesProvider);
    return exploreAsync.when(
      loading: _UpcomingShimmer.new,
      error: (_, __) => _EmptySection(
        emoji: '🔍',
        message: l10n.emptyCouldntLoadNearbyGames,
        actionLabel: l10n.actionBrowseAll,
        onAction: onBrowse,
      ),
      data: (games) {
        final filtered = games.where((g) {
          if (g.isCancelled || g.isCompleted) return false;
          if (g.isPrivate) return false;
          if (currentUserId == null) return true;
          // Hide games the viewer is already linked to in any active state.
          final slot = g.getPlayer(currentUserId!);
          if (slot == null) {
            // Organisers aren't always in the players[] array; hide their own games too.
            return g.organizer.id != currentUserId;
          }
          return !(slot.isApproved || slot.isPending || slot.status == 'invited');
        }).take(10).toList();

        if (filtered.isEmpty) {
          return _EmptySection(
            emoji: '🔍',
            message: l10n.emptyNothingNearby,
            actionLabel: l10n.actionBrowseAll,
            onAction: onBrowse,
          );
        }

        return SizedBox(
          height: 220,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) {
              final game = filtered[i];
              return GameCard(
                key: ValueKey('explore_${game.id}'),
                game: game,
                compact: true,
                onTap: () => onTap(game.id),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        if (actionLabel != null && onAction != null)
          TextButton(
            onPressed: onAction,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
            ),
            child: Text(actionLabel!),
          ),
      ],
    );
  }
}

// ── Quick action card ─────────────────────────────────────────────────────────
class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: 8, vertical: 14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
              child:
                  Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty section ─────────────────────────────────────────────────────────────
class _EmptySection extends StatelessWidget {
  const _EmptySection({
    required this.emoji,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String emoji;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(message,
                style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: onAction,
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer for upcoming games ────────────────────────────────────────────────
class _UpcomingShimmer extends StatelessWidget {
  const _UpcomingShimmer();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: Shimmer.fromColors(
        baseColor: AppColors.grey200,
        highlightColor: AppColors.grey100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: 3,
          separatorBuilder: (_, __) =>
              const SizedBox(width: 12),
          itemBuilder: (_, __) => Container(
            width: 180,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Outcome icon ──────────────────────────────────────────────────────────────
class _OutcomeIcon extends StatelessWidget {
  const _OutcomeIcon({required this.outcome});
  final String outcome;

  @override
  Widget build(BuildContext context) {
    return Text(
      switch (outcome) {
        'win' => '🏆',
        'loss' => '❌',
        'draw' => '🤝',
        _ => '',
      },
      style: const TextStyle(fontSize: 18),
    );
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
    _ => '🏅',
  };
}

// ── Collapsing home header (name moves into app bar on scroll) ────────────────
class _HomeHeaderFlexibleSpace extends StatelessWidget {
  const _HomeHeaderFlexibleSpace({
    required this.greeting,
    required this.onCalendarTap,
    required this.onSearchTap,
    required this.notificationBell,
    this.firstName,
  });

  final String greeting;
  final String? firstName;
  final VoidCallback onCalendarTap;
  final SearchBarTapCallback onSearchTap;
  final Widget notificationBell;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final settings =
        context.dependOnInheritedWidgetOfExactType<FlexibleSpaceBarSettings>();
    final expandRatio = settings == null
        ? 1.0
        : ((settings.currentExtent - settings.minExtent) /
                (settings.maxExtent - settings.minExtent))
            .clamp(0.0, 1.0);

    final collapsedTitle = firstName ?? l10n.homeCollapsedTitleFallback;
    final expandedTitle = firstName != null
        ? l10n.greetingWithName(greeting, firstName!)
        : l10n.greetingNoName(greeting);
    final t = Curves.easeOutCubic.transform(expandRatio.clamp(0.0, 1.0));
    final showExpandedActions = t > 0.55;

    final edgeInset = 4.0 * expandRatio;
    final topInset = 4.0 * expandRatio;
    final cornerRadius =
        AppColors.radiusXl * expandRatio + AppColors.radiusMd * (1 - expandRatio);

    return Padding(
      padding: EdgeInsets.fromLTRB(edgeInset, topInset, edgeInset, 0),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(cornerRadius),
          boxShadow: expandRatio > 0.2
              ? [
                  BoxShadow(
                    color: AppColors.slate.withValues(alpha: 0.18),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(cornerRadius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                AppAssets.homeWallpaper,
                fit: BoxFit.cover,
                alignment: Alignment.center,
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.slate.withValues(alpha: 0.35),
                      AppColors.slate.withValues(alpha: 0.72),
                    ],
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Stack(
                  children: [
                    if (showExpandedActions)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: HomeHeaderActions(
                          onCalendarTap: onCalendarTap,
                          notificationBell: notificationBell,
                        ),
                      ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        20,
                        8,
                        showExpandedActions ? 88 : 20,
                        showExpandedActions ? 62 : 14,
                      ),
                      child: Stack(
                        children: [
                          Opacity(
                            opacity: expandRatio,
                            child: Align(
                              alignment: Alignment.bottomLeft,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    expandedTitle,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 26,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.6,
                                      height: 1.15,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    l10n.appTagline,
                                    style: TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 14,
                                      color:
                                          Colors.white.withValues(alpha: 0.82),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Opacity(
                            opacity: 1 - expandRatio,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                collapsedTitle,
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    CollapsingHomeSearch(
                      expandRatio: expandRatio,
                      onTap: onSearchTap,
                      collapsedTrailing: showExpandedActions
                          ? null
                          : HomeHeaderActions(
                              onCalendarTap: onCalendarTap,
                              notificationBell: notificationBell,
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Bell icon + unread badge ──────────────────────────────────────────────────
/// AppBar action that overlays a Material `Badge` with the current
/// unread notification count on top of the bell icon. Subscribes only
/// to `unreadNotificationCountProvider` so the rest of the AppBar
/// doesn't rebuild on every inbox change.
class _NotificationBellAction extends ConsumerWidget {
  const _NotificationBellAction({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadNotificationCountProvider);
    return IconButton(
      onPressed: onTap,
      tooltip: context.l10n.tooltipNotifications,
      icon: Badge.count(
        count: unread,
        isLabelVisible: unread > 0,
        backgroundColor: AppColors.error,
        textColor: Colors.white,
        child: const Icon(Icons.notifications_outlined, color: Colors.white),
      ),
    );
  }
}
