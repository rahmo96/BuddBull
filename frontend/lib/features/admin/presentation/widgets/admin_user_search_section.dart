import 'dart:async';

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/admin/presentation/widgets/admin_user_tile.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Searchable user lookup for the admin dashboard and users screen.
class AdminUserSearchSection extends ConsumerStatefulWidget {
  const AdminUserSearchSection({
    super.key,
    this.maxResults,
    this.showSeeAllLink = false,
    this.showRecentWhenEmpty = false,
    this.initialQuery = '',
  });

  /// Limits how many matches are rendered (dashboard preview mode).
  final int? maxResults;

  /// Shows a link to the full Users tab when results are truncated.
  final bool showSeeAllLink;

  /// When true, loads the latest users if the search box is empty.
  final bool showRecentWhenEmpty;

  final String initialQuery;

  @override
  ConsumerState<AdminUserSearchSection> createState() => _AdminUserSearchSectionState();
}

class _AdminUserSearchSectionState extends ConsumerState<AdminUserSearchSection> {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;
  String _search = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery.isNotEmpty) {
      _searchCtrl.text = widget.initialQuery;
      _search = widget.initialQuery;
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  String _normalize(String value) => value.trim().replaceFirst(RegExp(r'^@+'), '');

  void _onQueryChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      setState(() => _search = _normalize(value));
    });
  }

  void _clearSearch() {
    _debounce?.cancel();
    _searchCtrl.clear();
    setState(() => _search = '');
  }

  @override
  Widget build(BuildContext context) {
    final hasQuery = _search.isNotEmpty;
    final shouldLoad = hasQuery || widget.showRecentWhenEmpty;
    final usersAsync = shouldLoad ? ref.watch(adminUsersProvider(_search)) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _searchCtrl,
          decoration: InputDecoration(
            hintText: 'Search by name, username, or email',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchCtrl.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: _clearSearch,
                  ),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            isDense: true,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (value) {
            setState(() {});
            _onQueryChanged(value);
          },
          onSubmitted: (value) {
            _debounce?.cancel();
            setState(() => _search = _normalize(value));
          },
        ),
        const SizedBox(height: 12),
        if (!shouldLoad)
          Text(
            'Type to find a user and manage their account.',
            style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
          )
        else
          usersAsync!.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Could not load users: $e',
                style: AppTextStyles.caption.copyWith(color: AppColors.error),
              ),
            ),
            data: (data) {
              final users = (data['users'] as List? ?? []).cast<Map<String, dynamic>>();
              final total = (data['total'] as num?)?.toInt() ?? users.length;
              final visibleUsers =
                  widget.maxResults == null ? users : users.take(widget.maxResults!).toList();
              final hiddenCount = widget.maxResults == null
                  ? 0
                  : (total - visibleUsers.length).clamp(0, total);

              if (users.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    hasQuery ? 'No users match "$_search".' : 'No users in the database yet.',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    hasQuery
                        ? '$total match${total == 1 ? '' : 'es'}'
                        : 'Recent users ($total total)',
                    style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  ...visibleUsers.map(
                    (user) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AdminUserTile(user: user, searchQuery: _search),
                    ),
                  ),
                  if (widget.showSeeAllLink && (hiddenCount > 0 || !hasQuery))
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(
                        onPressed: () => context.go(Routes.adminUsers),
                        child: Text(
                          hasQuery && hiddenCount > 0
                              ? 'View all $total results in Users'
                              : 'Open full Users list',
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }
}
