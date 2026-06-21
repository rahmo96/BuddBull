import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider(_search));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: 'Search users…',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchCtrl.clear();
                  setState(() => _search = '');
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onSubmitted: (v) => setState(() => _search = v.trim()),
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load users: $e')),
            data: (data) {
              final users = (data['users'] as List? ?? []).cast<Map<String, dynamic>>();
              if (users.isEmpty) {
                return const Center(child: Text('No users found'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(adminUsersProvider(_search).future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _AdminUserTile(user: users[i], search: _search),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _AdminUserTile extends ConsumerWidget {
  const _AdminUserTile({required this.user, required this.search});
  final Map<String, dynamic> user;
  final String search;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = (user['_id'] ?? user['id'])?.toString() ?? '';
    final isBanned = user['isBanned'] == true;
    final isRestricted = user['isRestricted'] == true;
    final username = user['username']?.toString() ?? '';
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();

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
                ),
                Text(
                  '@$username · ${user['role'] ?? ''}',
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
      ref.invalidate(adminUsersProvider(search));
    } else if (action == 'restrict' || action == 'unrestrict') {
      await ref.read(restrictUserProvider.notifier).restrictUser(
            userId,
            isRestricted: action == 'restrict',
          );
      ref.invalidate(adminUsersProvider(search));
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
        ref.invalidate(adminUsersProvider(search));
      }
    }
  }
}
