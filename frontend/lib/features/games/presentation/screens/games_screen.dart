import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/widgets/game_card.dart';
import 'package:buddbull/features/games/presentation/widgets/game_filter_sheet.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

const _sports = [
  'Football', 'Basketball', 'Tennis', 'Running',
  'Swimming', 'Cycling', 'Volleyball', 'Cricket',
];

class GamesScreen extends ConsumerStatefulWidget {
  const GamesScreen({super.key});

  @override
  ConsumerState<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends ConsumerState<GamesScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(gameSearchProvider.notifier).loadMore();
    }
  }

  Future<void> _openFilters() async {
    final params = ref.read(gameSearchProvider).params;
    final result = await showModalBottomSheet<GameSearchParams>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => GameFilterSheet(params: params),
    );
    if (result != null) {
      ref.read(gameSearchProvider.notifier).search(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final searchState = ref.watch(gameSearchProvider);
    final user = ref.watch(authProvider).user;
    final activeFilters = _countActiveFilters(searchState.params);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.navGames),
        backgroundColor: AppColors.background,
        elevation: 0,
        actions: [
          if (user?.isOrganizer ?? false)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => context.push('/games/create'),
              tooltip: l10n.tooltipCreateGame,
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppColors.radiusMd),
                boxShadow: AppColors.cardShadow,
              ),
              child: TextField(
                controller: _searchCtrl,
                onSubmitted: (q) => ref.read(gameSearchProvider.notifier).search(
                      searchState.params.copyWith(city: q.isEmpty ? null : q),
                    ),
                decoration: InputDecoration(
                  hintText: l10n.searchGamesHint,
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondary,
                  ),
                  suffixIcon: IconButton(
                    icon: Badge(
                      isLabelVisible: activeFilters > 0,
                      label: Text('$activeFilters'),
                      backgroundColor: AppColors.teal,
                      child: const Icon(Icons.tune_rounded),
                    ),
                    onPressed: _openFilters,
                    tooltip: l10n.tooltipFilter,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // ── Sport chips ─────────────────────────────────────
          SizedBox(
            height: 44,
            child: ListView.separated(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _sports.length + 1,
              separatorBuilder: (_, __) =>
                  const SizedBox(width: 8),
              itemBuilder: (_, i) {
                if (i == 0) {
                  final isActive =
                      searchState.params.sport == null;
                  return _SportFilterChip(
                    label: l10n.sportFilterAll,
                    emoji: '🏆',
                    selected: isActive,
                    onTap: () => ref
                        .read(gameSearchProvider.notifier)
                        .setSport(null),
                  );
                }
                final sport = _sports[i - 1];
                final selected =
                    searchState.params.sport == sport;
                return _SportFilterChip(
                  label: _sportDisplayName(context, sport),
                  emoji: _sportEmoji(sport),
                  selected: selected,
                  onTap: () => ref
                      .read(gameSearchProvider.notifier)
                      .setSport(selected ? null : sport),
                );
              },
            ),
          ),

          const SizedBox(height: 4),

          // ── Active filter summary ───────────────────────────
          if (activeFilters > 0)
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Text(
                    l10n.filtersActive(activeFilters),
                    style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.primary),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      _searchCtrl.clear();
                      ref
                          .read(gameSearchProvider.notifier)
                          .clearFilters();
                    },
                    child: Text(
                      l10n.clearFilters,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // ── List ────────────────────────────────────────────
          Expanded(
            child: _buildList(searchState),
          ),
        ],
      ),
    );
  }

  Widget _buildList(GameSearchState state) {
    if (state.isLoading) {
      return _ShimmerList();
    }

    if (state.error != null && state.games.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () =>
            ref.read(gameSearchProvider.notifier).search(),
      );
    }

    if (state.games.isEmpty) {
      return _EmptyGames(
        onCreateTap:
            (ref.watch(authProvider).user?.isOrganizer ?? false)
                ? () => context.push('/games/create')
                : null,
      );
    }

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: () =>
          ref.read(gameSearchProvider.notifier).search(),
      child: ListView.separated(
        controller: _scrollCtrl,
        padding: EdgeInsets.fromLTRB(
          16,
          4,
          16,
          HomeScaffold.navBottomInset(context),
        ),
        itemCount: state.games.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          if (i == state.games.length) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CircularProgressIndicator(
                    color: AppColors.primary),
              ),
            );
          }
          final game = state.games[i];
          final gameId = game.id;
          return GameCard(
            game: game,
            showJoinButton: true,
            onTap: () => context.push('/games/$gameId'),
            onJoin: () => context.push('/games/$gameId'),
          );
        },
      ),
    );
  }

  int _countActiveFilters(GameSearchParams p) {
    int count = 0;
    if (p.sport != null) count++;
    if (p.city != null) count++;
    if (p.skillLevel != null) count++;
    if (p.nearMe) count++;
    return count;
  }
}

// ── Sport chip ────────────────────────────────────────────────────────────────
class _SportFilterChip extends StatelessWidget {
  const _SportFilterChip({
    required this.label,
    required this.emoji,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String emoji;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.slate : AppColors.chipUnselected,
          borderRadius: BorderRadius.circular(24),
          boxShadow: selected ? AppColors.cardShadow : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              emoji,
              style: TextStyle(
                fontSize: 14,
                color: selected ? Colors.white : null,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected ? Colors.white : AppColors.textPrimary,
                fontWeight:
                    selected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyGames extends StatelessWidget {
  const _EmptyGames({this.onCreateTap});
  final VoidCallback? onCreateTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚽', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            Text(l10n.emptyNoGamesFound,
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              l10n.emptyTryAdjustingFilters,
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onCreateTap != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.buttonCreateGame),
                style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Shimmer loading skeleton ──────────────────────────────────────────────────
class _ShimmerList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        itemCount: 5,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, __) => Container(
          height: 160,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

String _sportDisplayName(BuildContext context, String sport) {
  final l10n = context.l10n;
  return switch (sport) {
    'Football' => l10n.sportFootball,
    'Basketball' => l10n.sportBasketball,
    'Tennis' => l10n.sportTennis,
    'Running' => l10n.sportRunning,
    'Swimming' => l10n.sportSwimming,
    'Cycling' => l10n.sportCycling,
    'Volleyball' => l10n.sportVolleyball,
    'Cricket' => l10n.sportCricket,
    _ => sport,
  };
}

String _sportEmoji(String sport) {
  return switch (sport.toLowerCase()) {
    'football' => '⚽',
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
