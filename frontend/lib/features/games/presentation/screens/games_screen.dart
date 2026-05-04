import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/presentation/widgets/game_card.dart';
import 'package:buddbull/features/games/presentation/widgets/game_filter_sheet.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';

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
    final searchState = ref.watch(gameSearchProvider);
    final user = ref.watch(authProvider).user;
    final activeFilters = _countActiveFilters(searchState.params);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.navGames),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text('$activeFilters'),
              backgroundColor: AppColors.primary,
              child: const Icon(Icons.tune_rounded),
            ),
            onPressed: _openFilters,
            tooltip: 'Filter',
          ),
          if (user?.isOrganizer ?? false)
            IconButton(
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => context.push('/games/create'),
              tooltip: 'Create game',
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Search bar ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              controller: _searchCtrl,
              hintText: 'Search games…',
              leading: const Icon(Icons.search_rounded, size: 20),
              trailing: [
                if (_searchCtrl.text.isNotEmpty)
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref
                          .read(gameSearchProvider.notifier)
                          .clearFilters();
                    },
                  ),
              ],
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: const WidgetStatePropertyAll(
                  AppColors.surface),
              shape: WidgetStatePropertyAll(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.grey300),
                ),
              ),
              onSubmitted: (q) => ref
                  .read(gameSearchProvider.notifier)
                  .search(
                    searchState.params
                        .copyWith(city: q.isEmpty ? null : q),
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
                    label: 'All',
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
                  label: sport,
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
                    '$activeFilters filter${activeFilters > 1 ? 's' : ''} active',
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
                      'Clear',
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
      floatingActionButton: (user?.isOrganizer ?? false)
          ? FloatingActionButton.extended(
              onPressed: () => context.push('/games/create'),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Create Game'),
            )
          : null,
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
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
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
          return GameCard(
            game: game,
            onTap: () => context.push('/games/${game.id}'),
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
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚽', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 16),
            const Text('No games found',
                style: AppTextStyles.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your filters or create a new game.',
              style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            if (onCreateTap != null) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: onCreateTap,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Create a game'),
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
