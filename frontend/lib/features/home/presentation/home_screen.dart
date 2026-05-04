import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/presentation/widgets/game_card.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/performance/presentation/widgets/streak_banner.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/features/profile/presentation/widgets/stats_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final calendarAsync = ref.watch(calendarGamesProvider);
    final statsAsync = ref.watch(performanceStatsProvider);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? 'Good morning'
        : hour < 17
            ? 'Good afternoon'
            : 'Good evening';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(calendarGamesProvider);
          ref.invalidate(performanceStatsProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Gradient header ────────────────────────────
            SliverAppBar(
              expandedHeight: 160,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                IconButton(
                  icon: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white),
                  onPressed: () =>
                      context.push('/games/calendar'),
                  tooltip: 'My calendar',
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white),
                  onPressed: () {},
                  tooltip: 'Notifications',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                          20, 56, 20, 16),
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        mainAxisAlignment:
                            MainAxisAlignment.end,
                        children: [
                          Text(
                            '$greeting${user != null ? ', ${user.firstName}!' : '!'}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color: Colors.white70,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'BuddBull',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          Text(
                            'Find your squad. Play your game.',
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13,
                              color:
                                  Colors.white.withOpacity(0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
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
                            value: user!.stats!.gamesPlayed
                                .toString(),
                            label: 'Games',
                            icon: Icons.sports_soccer_rounded,
                            color: AppColors.primary,
                          ),
                        ),
                        Expanded(
                          child: StatsCard(
                            value: user.stats!.averageRating
                                .toStringAsFixed(1),
                            label: 'Rating',
                            icon: Icons.star_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                        Expanded(
                          child: StatsCard(
                            value:
                                '${user.stats!.currentStreak}d',
                            label: 'Streak',
                            icon: Icons.local_fire_department_rounded,
                            color: AppColors.error,
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

                  // ── Upcoming games ────────────────────────
                  _SectionHeader(
                    title: 'Upcoming Games',
                    actionLabel: 'See all',
                    onAction: () => context.go('/games'),
                  ),
                  const SizedBox(height: 10),
                  calendarAsync.when(
                    loading: _UpcomingShimmer.new,
                    error: (_, __) => _EmptySection(
                      emoji: '📅',
                      message: 'No upcoming games',
                      actionLabel: 'Browse games',
                      onAction: () => context.go('/games'),
                    ),
                    data: (games) {
                      final upcoming = games
                          .where((g) => g.isUpcoming)
                          .take(5)
                          .toList();

                      if (upcoming.isEmpty) {
                        return _EmptySection(
                          emoji: '📅',
                          message: 'No upcoming games',
                          actionLabel: 'Browse games',
                          onAction: () => context.go('/games'),
                        );
                      }

                      return SizedBox(
                        height: 220,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: upcoming.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 12),
                          itemBuilder: (_, i) => GameCard(
                            game: upcoming[i],
                            compact: true,
                            onTap: () => context
                                .push('/games/${upcoming[i].id}'),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),

                  // ── Quick actions ─────────────────────────
                  const _SectionHeader(title: 'Quick Actions'),
                  const SizedBox(height: 10),
                  Row(
                    spacing: 10,
                    children: [
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.search_rounded,
                          label: 'Find a Game',
                          color: AppColors.primary,
                          onTap: () => context.go('/games'),
                        ),
                      ),
                      Expanded(
                        child: _QuickActionCard(
                          icon: Icons.add_rounded,
                          label: 'Log Session',
                          color: AppColors.success,
                          onTap: () => context
                              .push('/performance/log/create'),
                        ),
                      ),
                      if (user?.isOrganizer ?? false)
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.sports_score_rounded,
                            label: 'Create Game',
                            color: AppColors.secondary,
                            onTap: () =>
                                context.push('/games/create'),
                          ),
                        ),
                      if (!(user?.isOrganizer ?? false))
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.calendar_month_rounded,
                            label: 'Calendar',
                            color: AppColors.info,
                            onTap: () => context
                                .push('/games/calendar'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // ── Email verification warning ─────────────
                  if (user != null && !user.isEmailVerified)
                    _VerifyEmailBanner(),

                  // ── Recent activity ───────────────────────
                  _SectionHeader(
                    title: 'Recent Activity',
                    actionLabel: 'See all',
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
                              message: 'No recent sessions',
                              actionLabel: 'Log a session',
                              onAction: () => context.push(
                                  '/performance/log/create'),
                            );
                          }
                          return Column(
                            children: logs
                                .take(3)
                                .map((log) => Container(
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
                                                  log.formattedDate,
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

                  const SizedBox(height: 100),
                ]),
              ),
            ),
          ],
        ),
      ),
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
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
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

// ── Email verify banner ───────────────────────────────────────────────────────
class _VerifyEmailBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.warningLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.warning.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Please verify your email to access all features.',
              style: AppTextStyles.bodySmall
                  .copyWith(color: AppColors.warning),
            ),
          ),
        ],
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
