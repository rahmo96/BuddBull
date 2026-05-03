import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/performance/presentation/widgets/activity_heatmap.dart';
import 'package:buddbull/features/performance/presentation/widgets/log_card.dart';
import 'package:buddbull/features/performance/presentation/widgets/progress_chart.dart';
import 'package:buddbull/features/performance/presentation/widgets/streak_banner.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxScrolled) => [
          SliverAppBar(
            title: const Text(AppStrings.navPerformance),
            floating: true,
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () =>
                    context.push('/performance/log/create'),
                tooltip: 'Log a session',
              ),
            ],
            bottom: TabBar(
              controller: _tabCtrl,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.label,
              labelStyle: AppTextStyles.labelLarge.copyWith(
                fontWeight: FontWeight.w600,
              ),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Logs'),
                Tab(text: 'Stats'),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/performance/log/create'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Log Session'),
      ),
    );
  }
}

// ── Overview tab ──────────────────────────────────────────────────────────────
class _OverviewTab extends ConsumerWidget {
  const _OverviewTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          padding: const EdgeInsets.all(16),
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
                      label: 'Total sessions',
                      color: AppColors.primary,
                    ),
                  ),
                  Expanded(
                    child: _SummaryTile(
                      icon: Icons.timer_outlined,
                      value: _formatMinutes(stats.totalMinutes),
                      label: 'Total time',
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
                  const Text('No sessions yet',
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
                    label: const Text('Log a session'),
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
            padding: const EdgeInsets.fromLTRB(
                16, 8, 16, 100),
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
    final statsAsync = ref.watch(performanceStatsProvider);

    return statsAsync.when(
      loading: () =>
          const Center(child: BbLoadingIndicator()),
      error: (e, _) => ErrorView(message: e.toString()),
      data: (stats) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Personal bests ────────────────────────────
            if (stats.personalBests.isNotEmpty) ...[
              const Text('Personal Bests',
                  style: AppTextStyles.titleMedium),
              const SizedBox(height: 12),
              ...stats.personalBests.map(
                (pb) => _PBTile(pb: pb),
              ),
              const SizedBox(height: 16),
            ],

            // ── Sport breakdown ───────────────────────────
            if (stats.sportBreakdown.isNotEmpty) ...[
              const Text('By sport', style: AppTextStyles.titleMedium),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              shape: BoxShape.circle,
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
                      color: color),
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
    final total =
        breakdown.values.fold(0, (a, b) => a + b);
    final sorted = breakdown.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('By sport', style: AppTextStyles.titleSmall),
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
        color: AppColors.secondaryLight.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: AppColors.secondary.withOpacity(0.4)),
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
