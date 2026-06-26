import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/games/presentation/widgets/game_card.dart';
import 'package:buddbull/features/profile/presentation/widgets/bb_profile_avatar.dart';
import 'package:buddbull/features/search/presentation/widgets/search_transition.dart';
import 'package:buddbull/features/search/providers/global_search_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';

class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() =>
      _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchCtrl = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future<void>.delayed(const Duration(milliseconds: 200), () {
        if (mounted) _focusNode.requestFocus();
      });
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    ref.read(globalSearchProvider.notifier).setQuery(value);
  }

  void _applyQuery(String value) {
    _searchCtrl.text = value;
    _searchCtrl.selection = TextSelection.collapsed(offset: value.length);
    _onQueryChanged(value);
  }

  void _clear() {
    _searchCtrl.clear();
    ref.read(globalSearchProvider.notifier).clear();
    _focusNode.requestFocus();
  }

  void _close() {
    HapticFeedback.lightImpact();
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(globalSearchProvider);

    return Material(
      color: Colors.transparent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border(
                bottom: BorderSide(
                  color: AppColors.grey200.withValues(alpha: 0.7),
                ),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 20),
                      color: AppColors.slate,
                      onPressed: _close,
                      tooltip: 'Close search',
                    ),
                    Expanded(
                      child: GlobalSearchField(
                        controller: _searchCtrl,
                        focusNode: _focusNode,
                        onChanged: _onQueryChanged,
                        showClear: _searchCtrl.text.isNotEmpty,
                        onClear: _clear,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: _buildBody(state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(GlobalSearchState state) {
    final trimmed = state.query.trim();

    if (trimmed.isEmpty) {
      return _IdleSearchHints(onHintTap: _applyQuery);
    }

    if (trimmed.length < 2) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Type at least 2 characters to search',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    if (state.isLoading) {
      return const _SearchShimmer();
    }

    if (state.error != null && state.games.isEmpty && state.users.isEmpty) {
      return ErrorView(
        message: state.error!,
        onRetry: () => _onQueryChanged(state.query),
      );
    }

    if (state.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.grey100,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  size: 32,
                  color: AppColors.textDisabled,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'No results found',
                style: AppTextStyles.titleSmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Try a different sport, city, or player name',
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (state.hasPartialFailure) ...[
          _PartialSearchNotice(state: state),
          const SizedBox(height: 12),
        ],
        if (state.games.isNotEmpty) ...[
          _SectionLabel(title: 'Games', count: state.games.length),
          const SizedBox(height: 10),
          SizedBox(
            height: 220,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.games.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final game = state.games[i];
                return GameCard(
                  key: ValueKey('search_game_${game.id}'),
                  game: game,
                  compact: true,
                  onTap: () => context.push(Routes.gameDetail(game.id)),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
        ],
        if (state.users.isNotEmpty) ...[
          _SectionLabel(title: 'Players', count: state.users.length),
          const SizedBox(height: 8),
          ...state.users.map((user) => _PlayerResultTile(user: user)),
        ],
      ],
    );
  }
}

class _PartialSearchNotice extends StatelessWidget {
  const _PartialSearchNotice({required this.state});

  final GlobalSearchState state;

  @override
  Widget build(BuildContext context) {
    final messages = <String>[];
    if (state.gamesError != null && state.games.isEmpty) {
      messages.add('Games: ${state.gamesError}');
    }
    if (state.usersError != null && state.users.isEmpty) {
      messages.add('Players: ${state.usersError}');
    }
    if (messages.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.metricRatingBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.metricRatingAccent.withValues(alpha: 0.25),
        ),
      ),
      child: Text(
        messages.join('\n'),
        style: AppTextStyles.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _IdleSearchHints extends StatelessWidget {
  const _IdleSearchHints({required this.onHintTap});

  final ValueChanged<String> onHintTap;

  static const _hints = [
    ('Football', Icons.sports_soccer_rounded),
    ('Basketball', Icons.sports_basketball_rounded),
    ('Tennis', Icons.sports_tennis_rounded),
    ('Nearby games', Icons.near_me_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.mint.withValues(alpha: 0.25),
                    AppColors.teal.withValues(alpha: 0.15),
                  ],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.travel_explore_rounded,
                size: 36,
                color: AppColors.teal,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Discover your next game',
              style: AppTextStyles.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Search by sport, city, username, or player name',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _hints
                  .map(
                    (hint) => ActionChip(
                      avatar: Icon(hint.$2, size: 16, color: AppColors.teal),
                      label: Text(hint.$1),
                      labelStyle: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.slate,
                        fontWeight: FontWeight.w500,
                      ),
                      backgroundColor: AppColors.surface,
                      side: BorderSide(
                        color: AppColors.grey200.withValues(alpha: 0.8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      onPressed: () => onHintTap(hint.$1),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title, required this.count});

  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(title, style: AppTextStyles.titleMedium),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.teal.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.teal,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerResultTile extends StatelessWidget {
  const _PlayerResultTile({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    final city = user.location?.city;
    final subtitle = [
      '@${user.username}',
      if (city != null && city.isNotEmpty) city,
    ].join(' · ');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push(Routes.publicProfile(user.id)),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.grey200),
            ),
            child: Row(
              children: [
                BbProfileAvatar(
                  profilePicture: user.profilePicture,
                  initials: '${user.firstName[0]}${user.lastName[0]}',
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.fullName, style: AppTextStyles.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (user.stats?.averageRating != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.metricRatingBg,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star_rounded,
                            size: 14, color: AppColors.metricRatingAccent),
                        const SizedBox(width: 2),
                        Text(
                          user.stats!.averageRating.toStringAsFixed(1),
                          style: AppTextStyles.labelSmall.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textDisabled,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SearchShimmer extends StatelessWidget {
  const _SearchShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.grey200,
      highlightColor: AppColors.grey100,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            height: 20,
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 180,
            child: Row(
              children: List.generate(
                3,
                (_) => Container(
                  width: 180,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            height: 20,
            width: 80,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(
            4,
            (_) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                height: 64,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
