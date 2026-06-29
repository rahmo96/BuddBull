import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/profile/presentation/widgets/bb_profile_avatar.dart';
import 'package:buddbull/features/profile/providers/profile_provider.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Mutual friends list with per-row unfriend (removes from both users).
class FriendsListScreen extends ConsumerStatefulWidget {
  const FriendsListScreen({super.key});

  @override
  ConsumerState<FriendsListScreen> createState() => _FriendsListScreenState();
}

class _FriendsListScreenState extends ConsumerState<FriendsListScreen> {
  String? _unfriendingId;

  Future<void> _confirmUnfriend(UserModel friend) async {
    final l10n = context.l10n;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogUnfriendTitle),
        content: Text(l10n.dialogUnfriendBody(friend.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.buttonUnfriend),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _unfriendingId = friend.id);
    try {
      await ref.read(profileProvider.notifier).unfriend(friend.id);
      ref.invalidate(friendsProvider);
      await ref.read(profileProvider.notifier).refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.snackRemovedFromFriends(friend.fullName))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _unfriendingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final friendsAsync = ref.watch(friendsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.friendsTitle),
        backgroundColor: AppColors.surface,
      ),
      body: friendsAsync.when(
        loading: () => const Center(child: BbLoadingIndicator()),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(friendsProvider),
        ),
        data: (friends) {
          if (friends.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Text(
                  l10n.emptyNoFriendsYet,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            );
          }

          return RefreshIndicator(
            color: AppColors.primary,
            onRefresh: () async {
              ref.invalidate(friendsProvider);
              await ref.read(friendsProvider.future);
            },
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: friends.length,
              separatorBuilder: (_, __) => const Divider(
                height: 1,
                indent: 72,
                color: AppColors.border,
              ),
              itemBuilder: (_, i) {
                final friend = friends[i];
                final isBusy = _unfriendingId == friend.id;
                return ListTile(
                  leading: BbProfileAvatar(
                    profilePicture: friend.profilePicture,
                    radius: 24,
                    initials: '${friend.firstName[0]}${friend.lastName[0]}',
                  ),
                  title: Text(
                    friend.fullName,
                    style: AppTextStyles.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text('@${friend.username}'),
                  onTap: () => context.push(Routes.publicProfile(friend.id)),
                  trailing: TextButton(
                    onPressed: isBusy ? null : () => _confirmUnfriend(friend),
                    child: isBusy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            l10n.buttonUnfriend,
                            style: AppTextStyles.labelMedium.copyWith(
                              color: AppColors.error,
                            ),
                          ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
