import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:buddbull/features/performance/presentation/widgets/activity_heatmap.dart';
import 'package:buddbull/features/performance/presentation/widgets/log_card.dart';
import 'package:buddbull/features/performance/presentation/widgets/progress_chart.dart';
import 'package:buddbull/features/performance/presentation/widgets/streak_banner.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class PerformanceScreen extends ConsumerStatefulWidget {
  const PerformanceScreen({super.key});

  @override
  ConsumerState<PerformanceScreen> createState() =>
      _PerformanceScreenState();
}

class _PerformanceScreenState
    extends ConsumerState<PerformanceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            title: Text(l10n.navPerformance),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () =>
                    context.push('/performance/log/create'),
                tooltip: l10n.tooltipLogSession,
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.slate,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.teal,
              indicatorWeight: 3,
              indicatorSize: TabBarIndicatorSize.label,
              dividerColor: Colors.transparent,
              overlayColor: WidgetStateProperty.all(Colors.transparent),
              labelStyle: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w500,
              ),
              tabs: [
                Tab(text: l10n.overviewTab),
                Tab(text: l10n.logsTab),
                Tab(text: l10n.statsTab),
              ],
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabCtrl,
          children: const [
            _OverviewTab(),
            _LogsTab(),
            _StatsTab(),
          ],
        ),
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(performanceStatsProvider);

    return statsAsync.when(
      loading: () =>
          const Center(child: BbLoadingIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(performanceStatsProvider),
      ),
      data: (stats) => RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(performanceStatsProvider);
          await ref.read(performanceStatsProvider.future);
        },
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            HomeScaffold.navBottomInset(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Streak banner ────────────────────────────
              StreakBanner(
                currentStreak: stats.currentStreak,
                longestStreak: stats.longestStreak,
              ),
              const SizedBox(height: 16),

              // ── Summary tiles ────────────────────────────
              Row(
                spacing: 10,
                children: [
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.sports_rounded,
                      value: '${stats.totalSessions}',
                      label: l10n.totalSessions,
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.timer_outlined,
                      value: _formatMinutes(stats.totalMinutes),
                      label: l10n.totalTime,
                      color: AppColors.info,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // ── Progress chart ────────────────────────────
              _Card(
                child: ProgressChart(
                    sessions: stats.recentSessions),
              ),
              const SizedBox(height: 16),

              // ── Win rate chart ────────────────────────────
              _Card(
                child: WinRateChart(
                    sessions: stats.recentSessions),
              ),
              const SizedBox(height: 16),

              // ── Heatmap ───────────────────────────────────
              _Card(
                child: ActivityHeatmap(
                    entries: stats.activityHeatmap),
              ),
              const SizedBox(height: 16),

              // ── Sport breakdown ───────────────────────────
              if (stats.sportBreakdown.isNotEmpty)
                _Card(
                  child: _SportBreakdown(
                      breakdown: stats.sportBreakdown),
                ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
    );
  }

  String _formatMinutes(int minutes) {
    final h = minutes ~/ 60;
    return h >= 10 ? '${h}h' : '${h}h ${minutes % 60}m';
  }
}

// ── Logs tab ──────────────────────────────────────────────────────────────────
class _LogsTab extends ConsumerWidget {
  const _LogsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final logsAsync = ref.watch(performanceLogsProvider);
    final deleteState = ref.watch(deleteLogProvider);

    ref.listen(deleteLogProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnackBar(context, next.error!);
      }
    });

    return logsAsync.when(
      loading: () =>
          const Center(child: BbLoadingIndicator()),
      error: (e, _) => ErrorView(
        message: e.toString(),
        onRetry: () =>
            ref.invalidate(performanceLogsProvider),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('📊',
                      style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 16),
                  Text(l10n.noSessionsYet,
                      style: AppTextStyles.headlineSmall),
                  const SizedBox(height: 8),
                  Text(
                    'Start logging your training and matches.',
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: () => context
                        .push('/performance/log/create'),
                    icon: const Icon(Icons.add_rounded,
                        size: 18),
                    label: Text(l10n.actionLogSession),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary),
                  ),
                ],
              ),
            ),
          );
        }

        return RefreshIndicator(
          color: AppColors.primary,
          onRefresh: () async =>
              ref.invalidate(performanceLogsProvider),
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              HomeScaffold.navBottomInset(context),
            ),
            itemCount: logs.length,
            separatorBuilder: (_, __) =>
                const SizedBox(height: 12),
            itemBuilder: (_, i) {
              final log = logs[i];
              return LogCard(
                log: log,
                onDelete: deleteState.deletingId == log.id
                    ? null
                    : () => ref
                        .read(deleteLogProvider.notifier)
                        .delete(log.id),
              );
            },
          ),
        );
      },
    );
  }
}

// ── Stats tab ─────────────────────────────────────────────────────────────────
class _StatsTab extends ConsumerWidget {
  const _StatsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final statsAsync = ref.watch(performanceStatsProvider);

    return statsAsync.when(
      loading: () =>
          const Center(child: BbLoadingIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (stats) => SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          16,
          16,
          16,
          HomeScaffold.navBottomInset(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Personal bests ────────────────────────────
            if (stats.personalBests.isNotEmpty) ...[
              Text(l10n.personalBests,
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              ...stats.personalBests.map(
                (pb) => _PBTile(pb: pb),
              ),
              const SizedBox(height: 16),
            ],

            // ── Sport breakdown ───────────────────────────
            if (stats.sportBreakdown.isNotEmpty) ...[
              Text(l10n.bySport, style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              _Card(
                child: _SportBreakdown(
                    breakdown: stats.sportBreakdown),
              ),
              const SizedBox(height: 16),
            ],

            // ── Empty ─────────────────────────────────────
            if (stats.personalBests.isEmpty &&
                stats.sportBreakdown.isEmpty)
              Center(
                child: Text(
                  'Log sessions to build your stats',
                  style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary),
                ),
              ),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        boxShadow: AppColors.cardShadow,
      ),
      child: child,
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppColors.radiusMd),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: AppTextStyles.titleMedium.copyWith(
                    color: color,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SportBreakdown extends StatelessWidget {
  const _SportBreakdown({required this.breakdown});
  final Map<String, int> breakdown;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final total =
        breakdown.values.fold(0, (a, b) => a + b);
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.bySport, style: AppTextStyles.titleSmall),
        const SizedBox(height: 12),
        ...sorted.map((entry) {
          final fraction = total > 0 ? entry.value / total : 0.0;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 80,
                  child: Text(entry.key,
                      style: AppTextStyles.bodySmall),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: fraction,
                      minHeight: 8,
                      backgroundColor: AppColors.grey100,
                      valueColor:
                          const AlwaysStoppedAnimation(
                              AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${entry.value}',
                  style: AppTextStyles.labelMedium.copyWith(
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _PBTile extends StatelessWidget {
  const _PBTile({required this.pb});
  final dynamic pb;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.secondaryLight.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.secondary.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Text('🏅', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${pb.metric}: ${pb.value}',
              style: AppTextStyles.bodyMedium,
            ),
          ),
          Text(
            pb.sport,
            style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.secondaryDark),
          ),
        ],
      ),
    );
  }
}
