import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUserTile extends ConsumerWidget {
  const AdminUserTile({
    super.key,
    required this.user,
    required this.searchQuery,
  });

  final Map<String, dynamic> user;
  final String searchQuery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = (user['_id'] ?? user['id'])?.toString() ?? '';
    final isBanned = user['isBanned'] == true;
    final isRestricted = user['isRestricted'] == true;
    final username = user['username']?.toString() ?? '';
    final email = user['email']?.toString() ?? '';
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final gamesPlayed = (user['stats'] as Map<String, dynamic>?)?['gamesPlayed'];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name.isNotEmpty ? name : username,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '@$username · ${user['role'] ?? ''}',
                  style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (gamesPlayed != null)
                  Text(
                    '$gamesPlayed games played',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                if (isBanned || isRestricted)
                  Text(
                    [
                      if (isBanned) 'Banned',
                      if (isRestricted) 'Restricted',
                    ].join(' · '),
                    style: AppTextStyles.caption.copyWith(color: AppColors.error),
                  ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (action) => _handleAction(context, ref, action, userId),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: isBanned ? 'unban' : 'ban',
                child: Text(isBanned ? 'Unban' : 'Ban'),
              ),
              PopupMenuItem(
                value: isRestricted ? 'unrestrict' : 'restrict',
                child: Text(isRestricted ? 'Unrestrict' : 'Restrict'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(
    BuildContext context,
    WidgetRef ref,
    String action,
    String userId,
  ) async {
    if (action == 'ban' || action == 'unban') {
      await ref.read(banUserProvider.notifier).banUser(
            userId,
            isBanned: action == 'ban',
          );
      ref.invalidate(adminUsersProvider(searchQuery));
    } else if (action == 'restrict' || action == 'unrestrict') {
      await ref.read(restrictUserProvider.notifier).restrictUser(
            userId,
            isRestricted: action == 'restrict',
          );
      ref.invalidate(adminUsersProvider(searchQuery));
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete User'),
          content: const Text('This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: AppColors.error)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(adminRepositoryProvider).deleteUser(userId);
        ref.invalidate(adminUsersProvider(searchQuery));
      }
    }
  }
}
