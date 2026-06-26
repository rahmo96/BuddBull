import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/error/app_exception.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/chat/data/models/chat_model.dart';
import 'package:buddbull/features/chat/providers/chat_provider.dart';
import 'package:buddbull/features/home/home_scaffold.dart';
import 'package:buddbull/features/profile/presentation/widgets/bb_profile_avatar.dart';
import 'package:buddbull/features/profile/presentation/widgets/sport_chip.dart';
import 'package:buddbull/features/profile/presentation/widgets/stats_card.dart';
import 'package:buddbull/features/profile/providers/profile_provider.dart';
import 'package:buddbull/features/rating/presentation/widgets/rating_stars.dart';
import 'package:buddbull/features/reports/data/report_repository.dart';
import 'package:buddbull/features/reports/presentation/widgets/report_flow.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.userId});

  /// If null, shows the current user's profile.
  final String? userId;

  bool get _isOwnProfile => userId == null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!_isOwnProfile) {
      return _PublicProfileView(userId: userId!);
    }

    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: BbLoadingIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () => ref.read(profileProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            // ── App bar with avatar ────────────────────────────
            SliverAppBar(
              expandedHeight: 220,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              actions: [
                if (user.role == 'admin')
                  IconButton(
                    icon: const Icon(Icons.admin_panel_settings_outlined, color: Colors.white),
                    onPressed: () => context.push(Routes.adminDashboard),
                    tooltip: 'Admin Dashboard',
                  ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, color: Colors.white),
                  onPressed: () => context.push(Routes.editProfile),
                  tooltip: 'Edit profile',
                ),
                IconButton(
                  icon:
                      const Icon(Icons.logout_rounded, color: Colors.white),
                  onPressed: () => _confirmLogout(context, ref),
                  tooltip: 'Sign out',
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: AppColors.brandGradient,
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        BbProfileAvatar(
                          profilePicture: user.profilePicture,
                          radius: 44,
                          initials: '${user.firstName[0]}${user.lastName[0]}',
                        ),
                        const SizedBox(height: 10),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 14,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                        if (user.stats != null)
                          _HeaderRatingRow(
                            rating: user.stats!.averageRating,
                            totalRatings: user.stats!.totalRatings,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Friends row (navigates to friends list) ───────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Material(
                  color: AppColors.surface,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: AppColors.grey200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () => context.push(Routes.friends),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.people_outline_rounded,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      title: Text(
                        AppStrings.friends,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        user.friendsCount == 1
                            ? '1 mutual connection'
                            : '${user.friendsCount} mutual connections',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Performance stats ─────────────────────────────
            if (user.stats != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: StatsCard(
                          value: user.stats!.gamesPlayed.toString(),
                          label: AppStrings.gamesPlayed,
                          icon: Icons.sports_soccer_rounded,
                          accentColor: AppColors.metricGamesAccent,
                          backgroundColor: AppColors.metricGamesBg,
                        ),
                      ),
                      Expanded(
                        child: StatsCard(
                          value:
                              user.stats!.averageRating.toStringAsFixed(1),
                          label: AppStrings.rating,
                          icon: Icons.star_rounded,
                          accentColor: AppColors.metricRatingAccent,
                          backgroundColor: AppColors.metricRatingBg,
                        ),
                      ),
                      Expanded(
                        child: StatsCard(
                          value: '${user.stats!.currentStreak}d',
                          label: AppStrings.streakDays,
                          icon: Icons.local_fire_department_rounded,
                          accentColor: AppColors.metricStreakAccent,
                          backgroundColor: AppColors.metricStreakBg,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Bio ───────────────────────────────────────────
            if (user.bio != null && user.bio!.isNotEmpty)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'About',
                  child: Text(
                    user.bio!,
                    style: AppTextStyles.bodyMedium,
                  ),
                ),
              ),

            // ── Location ──────────────────────────────────────
            if (user.location?.city != null)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Location',
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded,
                          size: 16, color: AppColors.grey500),
                      const SizedBox(width: 6),
                      Text(
                        [
                          user.location?.neighborhood,
                          user.location?.city,
                        ]
                            .whereType<String>()
                            .join(', '),
                        style: AppTextStyles.bodyMedium,
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${user.location?.radiusKm ?? 10} km radius',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.info,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // ── Sports ────────────────────────────────────────
            if (user.sportsInterests.isNotEmpty)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: AppStrings.sportsInterests,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.sportsInterests
                        .map((s) => SportChip(interest: s))
                        .toList(),
                  ),
                ),
              ),

            if (user.performanceSummary?.recentActivity.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Recent Activity',
                  child: _ActivityFeed(
                    items: user.performanceSummary!.recentActivity,
                  ),
                ),
              ),

            SliverToBoxAdapter(
              child: SizedBox(height: HomeScaffold.navBottomInset(context)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sign out?'),
        content: const Text('You will need to sign in again.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              ref.read(authProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sign out'),
          ),
        ],
      ),
    );
  }
}

// ── Public profile view ───────────────────────────────────────────────────────
class _PublicProfileView extends ConsumerWidget {
  const _PublicProfileView({required this.userId});
  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(publicProfileProvider(userId));

    return userAsync.when(
      loading: () => const Scaffold(
        body: Center(child: BbLoadingIndicator()),
      ),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: ErrorView(message: e.toString()),
      ),
      data: (user) => Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration:
                      const BoxDecoration(gradient: AppColors.brandGradient),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        BbProfileAvatar(
                          profilePicture: user.profilePicture,
                          radius: 40,
                          initials:
                              '${user.firstName[0]}${user.lastName[0]}',
                        ),
                        const SizedBox(height: 8),
                        Text(
                          user.fullName,
                          style: const TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '@${user.username}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 13,
                          ),
                        ),
                        if (user.stats != null)
                          _HeaderRatingRow(
                            rating: user.stats!.averageRating,
                            totalRatings: user.stats!.totalRatings,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (ref.watch(currentUserProvider)?.id != userId)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _PublicProfileActions(
                    userId: userId,
                    friendRequestStatus: user.friendRequestStatus,
                    friendRequestId: user.friendRequestId,
                    isFriend: user.isFriend,
                    initialFriendsCount: user.friendsCount,
                  ),
                ),
              ),
            if (user.stats != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                  child: Row(
                    spacing: 8,
                    children: [
                      Expanded(
                        child: StatsCard(
                          value: user.stats!.gamesPlayed.toString(),
                          label: AppStrings.gamesPlayed,
                          icon: Icons.sports_soccer_rounded,
                          accentColor: AppColors.metricGamesAccent,
                          backgroundColor: AppColors.metricGamesBg,
                        ),
                      ),
                      Expanded(
                        child: StatsCard(
                          value: user.stats!.averageRating.toStringAsFixed(1),
                          label: user.stats!.totalRatings > 0
                              ? '${AppStrings.rating} (${user.stats!.totalRatings})'
                              : AppStrings.rating,
                          icon: Icons.star_rounded,
                          accentColor: AppColors.metricRatingAccent,
                          backgroundColor: AppColors.metricRatingBg,
                        ),
                      ),
                      Expanded(
                        child: StatsCard(
                          value: _winRate(user).toStringAsFixed(0),
                          label: 'Win Rate %',
                          icon: Icons.emoji_events_outlined,
                          accentColor: AppColors.success,
                          backgroundColor: AppColors.successLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (user.stats != null && user.stats!.totalRatings > 0)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    'Community average ${user.stats!.averageRating.toStringAsFixed(1)} from ${user.stats!.totalRatings} peer ${user.stats!.totalRatings == 1 ? 'rating' : 'ratings'}',
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            if (user.bio != null)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'About',
                  child: Text(user.bio!, style: AppTextStyles.bodyMedium),
                ),
              ),
            if (user.sportsInterests.isNotEmpty)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Sports',
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: user.sportsInterests
                        .map((s) => SportChip(interest: s))
                        .toList(),
                  ),
                ),
              ),
            if (user.performanceSummary != null)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Ratings Summary',
                  child: Row(
                    children: [
                      Expanded(
                        child: _Metric(
                          label: 'Overall',
                          value: user.performanceSummary!.ratings.avgComposite
                              .toStringAsFixed(1),
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Reliability',
                          value: user.performanceSummary!.ratings.avgReliability
                              .toStringAsFixed(1),
                        ),
                      ),
                      Expanded(
                        child: _Metric(
                          label: 'Behavior',
                          value: user.performanceSummary!.ratings.avgBehavior
                              .toStringAsFixed(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            if (user.performanceSummary?.recentActivity.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Recent Activity',
                  child: _ActivityFeed(
                    items: user.performanceSummary!.recentActivity,
                  ),
                ),
              ),
            if (user.performanceSummary?.upcomingGames.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: _SectionCard(
                  title: 'Upcoming Games',
                  child: _UpcomingGamesList(
                    games: user.performanceSummary!.upcomingGames,
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  HomeScaffold.navBottomInset(context) + 16,
                ),
                child: ReportActionButton(
                  targetType: ReportTargetType.user,
                  targetId: user.id,
                  targetLabel: '@${user.username}',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Public profile actions (friend requests, message, social counts) ────────
class _PublicProfileActions extends ConsumerStatefulWidget {
  const _PublicProfileActions({
    required this.userId,
    required this.friendRequestStatus,
    this.friendRequestId,
    required this.isFriend,
    required this.initialFriendsCount,
  });

  final String userId;
  final String friendRequestStatus;
  final String? friendRequestId;
  final bool isFriend;
  final int initialFriendsCount;

  @override
  ConsumerState<_PublicProfileActions> createState() =>
      _PublicProfileActionsState();
}

class _PublicProfileActionsState extends ConsumerState<_PublicProfileActions> {
  late String _status;
  late int _friendsCount;
  bool _actionLoading = false;
  bool _messageLoading = false;

  @override
  void initState() {
    super.initState();
    _status = widget.isFriend ? 'friends' : widget.friendRequestStatus;
    _friendsCount = widget.initialFriendsCount;
  }

  void _snack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _errorMessage(Object e) {
    if (e is AppException) return e.message;
    final raw = e.toString();
    final match = RegExp(r'\): (.+)$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }

  Future<void> _sendFriendRequest() async {
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      await ref.read(profileProvider.notifier).sendFriendRequest(widget.userId);
      if (!mounted) return;
      setState(() => _status = 'pending_sent');
      _snack('Friend request sent');
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _acceptRequest() async {
    final requestId = widget.friendRequestId;
    if (requestId == null || requestId.isEmpty) return;
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      final count = await ref
          .read(profileProvider.notifier)
          .acceptFriendRequest(requestId);
      if (!mounted) return;
      setState(() {
        _status = 'friends';
        if (count != null) _friendsCount = count;
      });
      ref.invalidate(publicProfileProvider(widget.userId));
      _snack('You are now friends');
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _declineRequest() async {
    final requestId = widget.friendRequestId;
    if (requestId == null || requestId.isEmpty) return;
    if (_actionLoading) return;
    setState(() => _actionLoading = true);
    try {
      await ref.read(profileProvider.notifier).declineFriendRequest(requestId);
      if (!mounted) return;
      setState(() => _status = 'none');
      ref.invalidate(publicProfileProvider(widget.userId));
      _snack('Friend request declined');
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  Future<void> _openMessage() async {
    final me = ref.read(currentUserProvider);
    if (me == null) {
      _snack('Please sign in to send a message.');
      return;
    }
    if (me.id == widget.userId) {
      _snack('You cannot message yourself.');
      return;
    }
    if (_messageLoading) return;

    setState(() => _messageLoading = true);
    try {
      final repo = ref.read(chatRepositoryProvider);
      final chats = await repo.getChats();
      ChatModel? existingDm;
      for (final c in chats) {
        if (c.type == 'dm' &&
            c.participants.any((p) => p.userId == widget.userId)) {
          existingDm = c;
          break;
        }
      }
      final chat = existingDm ?? await repo.createOrGetDM(widget.userId);
      ref.invalidate(chatListProvider);
      if (!mounted) return;
      context.push(Routes.chatRoom(chat.id));
    } catch (e) {
      _snack(_errorMessage(e));
    } finally {
      if (mounted) setState(() => _messageLoading = false);
    }
  }

  Widget _primaryFriendButton() {
    if (_actionLoading) {
      return const Center(
        child: SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    switch (_status) {
      case 'friends':
        return OutlinedButton.icon(
          onPressed: _messageLoading ? null : _openMessage,
          icon: _messageLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.chat_bubble_outline, size: 18),
          label: const Text('Message'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );
      case 'pending_sent':
        return OutlinedButton.icon(
          onPressed: null,
          icon: const Icon(Icons.hourglass_top_rounded, size: 18),
          label: const Text('Request sent'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.textSecondary,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );
      case 'pending_received':
        return Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: _acceptRequest,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: const Text('Accept'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _declineRequest,
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text('Decline'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ],
        );
      default:
        return OutlinedButton.icon(
          onPressed: _sendFriendRequest,
          icon: const Icon(Icons.person_add_outlined, size: 18),
          label: const Text('Add Friend'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _primaryFriendButton(),
        const SizedBox(height: 12),
        Material(
          color: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppColors.grey200),
          ),
          clipBehavior: Clip.antiAlias,
          child: ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
            leading: const Icon(
              Icons.people_outline_rounded,
              color: AppColors.primary,
              size: 20,
            ),
            title: Text(
              '$_friendsCount ${AppStrings.friends}',
              style: AppTextStyles.bodySmall.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.grey200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTextStyles.titleSmall),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: AppTextStyles.titleSmall.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed({required this.items});
  final List<UserActivityItem> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: items.map((item) {
        final loggedAt = item.loggedAt;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.timeline_rounded, size: 18),
          title: Text(
            '${item.sport} • ${item.type}',
            style: AppTextStyles.bodyMedium,
          ),
          subtitle: Text(
            [
              if (item.matchOutcome != null) item.matchOutcome,
              if (item.durationMinutes != null) '${item.durationMinutes} min',
              if (loggedAt != null)
                '${loggedAt.day}/${loggedAt.month}/${loggedAt.year}',
            ].whereType<String>().join(' • '),
          ),
        );
      }).toList(),
    );
  }
}

class _UpcomingGamesList extends StatelessWidget {
  const _UpcomingGamesList({required this.games});
  final List<UserUpcomingGame> games;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: games.map((game) {
        final schedule = game.scheduledAt;
        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.event_rounded, size: 18),
          title: Text(game.title, style: AppTextStyles.bodyMedium),
          subtitle: Text(
            [
              game.sport,
              if (schedule != null)
                '${schedule.day}/${schedule.month}/${schedule.year}',
              game.status,
            ].whereType<String>().join(' • '),
          ),
        );
      }).toList(),
    );
  }
}

double _winRate(UserModel user) {
  final stats = user.stats;
  if (stats == null || stats.gamesPlayed == 0) return 0;
  return (stats.gamesWon / stats.gamesPlayed) * 100;
}

/// Inline stars + numeric average + total ratings count, rendered under the
/// user's name in the profile header.
class _HeaderRatingRow extends StatelessWidget {
  const _HeaderRatingRow({required this.rating, required this.totalRatings});

  final double rating;
  final int totalRatings;

  @override
  Widget build(BuildContext context) {
    // No score yet → render a discreet placeholder rather than a zero rating.
    if (totalRatings == 0 || rating <= 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          'No ratings yet',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.75),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingStars(
            rating: rating,
            size: 14,
            activeColor: const Color(0xFFFFC857),
          ),
          const SizedBox(width: 6),
          Text(
            '${rating.toStringAsFixed(1)} · $totalRatings',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.95),
            ),
          ),
        ],
      ),
    );
  }
}
