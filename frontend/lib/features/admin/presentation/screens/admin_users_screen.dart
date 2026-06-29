import 'dart:async';

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/admin/presentation/widgets/admin_user_tile.dart';
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
  Timer? _debounce;
  String _search = '';

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _search = value.trim().replaceFirst(RegExp(r'^@+'), ''));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final usersAsync = ref.watch(adminUsersProvider(_search));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: l10n.searchUsersHint,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchCtrl.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: _clearSearch,
                    ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            textInputAction: TextInputAction.search,
            onChanged: (value) {
              setState(() {});
              _onQueryChanged(value);
            },
            onSubmitted: (value) {
              _debounce?.cancel();
              setState(() => _search = value.trim().replaceFirst(RegExp(r'^@+'), ''));
            },
          ),
        ),
        Expanded(
          child: usersAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text(l10n.failedToLoadUsers('$e'))),
            data: (data) {
              final users = (data['users'] as List? ?? [])
                  .whereType<Map>()
                  .map((u) => Map<String, dynamic>.from(u))
                  .toList();
              final total = (data['total'] as num?)?.toInt() ?? users.length;
              if (users.isEmpty) {
                return Center(
                  child: Text(
                    _search.isEmpty
                        ? l10n.adminNoUsersFound
                        : l10n.adminNoUsersMatchSearch(_search),
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(adminUsersProvider(_search).future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: users.length + 1,
                  separatorBuilder: (_, i) => SizedBox(height: i == 0 ? 4 : 8),
                  itemBuilder: (_, i) {
                    if (i == 0) {
                      return Text(
                        l10n.adminUserCount(total),
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      );
                    }
                    final user = users[i - 1];
                    return AdminUserTile(user: user, searchQuery: _search);
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
