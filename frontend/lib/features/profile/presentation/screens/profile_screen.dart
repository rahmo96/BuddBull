import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/profile/presentation/widgets/sport_chip.dart';
import 'package:buddbull/features/profile/presentation/widgets/stats_card.dart';
import 'package:buddbull/features/profile/providers/profile_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:cached_network_image/cached_network_image.dart';
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
                        _AvatarWidget(
                          imageUrl: user.profilePicture,
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
                            color: Colors.white.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Role badge ────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: _RoleBadge(role: user.role),
              ),
            ),

            // ── Social stats ──────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: _SocialStat(
                        count: user.followersCount,
                        label: AppStrings.followers,
                      ),
                    ),
                    const SizedBox(width: 1),
                    Expanded(
                      child: _SocialStat(
                        count: user.followingCount,
                        label: AppStrings.following,
                      ),
                    ),
                  ],
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
                          color: AppColors.primary,
                        ),
                      ),
                      Expanded(
                        child: StatsCard(
                          value:
                              user.stats!.averageRating.toStringAsFixed(1),
                          label: AppStrings.rating,
                          icon: Icons.star_rounded,
                          color: AppColors.secondary,
                        ),
                      ),
                      Expanded(
                        child: StatsCard(
                          value: '${user.stats!.currentStreak}d',
                          label: AppStrings.streakDays,
                          icon: Icons.local_fire_department_rounded,
                          color: AppColors.error,
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

            // ── Email verification warning ────────────────────
            if (!user.isEmailVerified)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Container(
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
                            'Please verify your email address.',
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
                        _AvatarWidget(
                          imageUrl: user.profilePicture,
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
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: _FollowButton(userId: userId),
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
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }
}

// ── Follow button ─────────────────────────────────────────────────────────────
class _FollowButton extends ConsumerStatefulWidget {
  const _FollowButton({required this.userId});
  final String userId;

  @override
  ConsumerState<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends ConsumerState<_FollowButton> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return _following
        ? OutlinedButton.icon(
            onPressed: _unfollow,
            icon: const Icon(Icons.person_remove_outlined, size: 18),
            label: const Text('Following'),
          )
        : FilledButton.icon(
            onPressed: _follow,
            icon: const Icon(Icons.person_add_outlined, size: 18),
            label: const Text('Follow'),
            style:
                FilledButton.styleFrom(backgroundColor: AppColors.primary),
          );
  }

  Future<void> _follow() async {
    setState(() => _following = true);
    await ref.read(profileProvider.notifier).followUser(widget.userId);
  }

  Future<void> _unfollow() async {
    setState(() => _following = false);
    await ref.read(profileProvider.notifier).unfollowUser(widget.userId);
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _AvatarWidget extends StatelessWidget {
  const _AvatarWidget({
    required this.imageUrl,
    required this.radius,
    required this.initials,
  });

  final String? imageUrl;
  final double radius;
  final String initials;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: Colors.white,
      child: imageUrl != null
          ? ClipOval(
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                width: radius * 2,
                height: radius * 2,
                fit: BoxFit.cover,
                placeholder: (_, __) => const CircularProgressIndicator(
                  strokeWidth: 2,
                ),
                errorWidget: (_, __, ___) => _InitialsAvatar(
                  initials: initials,
                  radius: radius,
                ),
              ),
            )
          : _InitialsAvatar(initials: initials, radius: radius),
    );
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.radius});
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: const BoxDecoration(
        gradient: AppColors.brandGradient,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: TextStyle(
            color: Colors.white,
            fontSize: radius * 0.65,
            fontWeight: FontWeight.w700,
            fontFamily: 'Inter',
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});
  final String role;

  @override
  Widget build(BuildContext context) {
    final isOrganizer = role == 'organizer';
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isOrganizer
              ? AppColors.secondaryLight
              : AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOrganizer
                ? AppColors.secondary
                : AppColors.primary.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isOrganizer
                  ? Icons.military_tech_rounded
                  : Icons.sports_soccer_rounded,
              size: 14,
              color: isOrganizer ? AppColors.secondaryDark : AppColors.primary,
            ),
            const SizedBox(width: 4),
            Text(
              isOrganizer ? 'Organizer' : 'Player',
              style: AppTextStyles.labelSmall.copyWith(
                color:
                    isOrganizer ? AppColors.secondaryDark : AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialStat extends StatelessWidget {
  const _SocialStat({required this.count, required this.label});
  final int count;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.grey200),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            count.toString(),
            style: AppTextStyles.titleMedium.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
          Text(label, style: AppTextStyles.labelSmall),
        ],
      ),
    );
  }
}

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
