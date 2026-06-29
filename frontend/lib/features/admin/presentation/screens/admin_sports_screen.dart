import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSportsScreen extends ConsumerWidget {
  const AdminSportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final sportsAsync = ref.watch(adminSportsProvider);

    return sportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text(l10n.failedToLoadSports('$e'))),
      data: (sports) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showSportForm(context, ref),
                icon: const Icon(Icons.add),
                label: Text(l10n.dialogAddSportTitle),
              ),
            ),
            Expanded(
              child: sports.isEmpty
                  ? Center(child: Text(l10n.adminNoSportsYet))
                  : RefreshIndicator(
                      onRefresh: () => ref.refresh(adminSportsProvider.future),
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: sports.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final sport = sports[i];
                          final id = (sport['_id'] ?? sport['id'])?.toString() ?? '';
                          final isActive = sport['isActive'] != false;
                          return ListTile(
                            tileColor: AppColors.surface,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: const BorderSide(color: AppColors.border),
                            ),
                            leading: Text(
                              sport['icon']?.toString() ?? '🏅',
                              style: const TextStyle(fontSize: 24),
                            ),
                            title: Text(sport['name']?.toString() ?? ''),
                            subtitle: Text(
                              isActive ? l10n.adminSportActive : l10n.adminSportInactive,
                              style: AppTextStyles.caption,
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (action) async {
                                if (action == 'edit') {
                                  _showSportForm(context, ref, sport: sport);
                                } else if (action == 'delete') {
                                  await ref
                                      .read(adminRepositoryProvider)
                                      .deleteSport(id);
                                  ref.invalidate(adminSportsProvider);
                                }
                              },
                              itemBuilder: (_) => [
                                PopupMenuItem(value: 'edit', child: Text(l10n.adminEdit)),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text(l10n.adminDeactivateSport),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showSportForm(
    BuildContext context,
    WidgetRef ref, {
    Map<String, dynamic>? sport,
  }) async {
    final l10n = context.l10n;
    final nameCtrl = TextEditingController(text: sport?['name']?.toString() ?? '');
    final iconCtrl = TextEditingController(text: sport?['icon']?.toString() ?? '🏅');
    final descCtrl =
        TextEditingController(text: sport?['description']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sport == null ? l10n.dialogAddSportTitle : l10n.adminEditSport),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(labelText: l10n.fieldNameLabel),
            ),
            TextField(
              controller: iconCtrl,
              decoration: InputDecoration(labelText: l10n.fieldIconLabel),
            ),
            TextField(
              controller: descCtrl,
              decoration: InputDecoration(labelText: l10n.descriptionLabel),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.save)),
        ],
      ),
    );

    if (saved == true) {
      final payload = {
        'name': nameCtrl.text.trim(),
        'icon': iconCtrl.text.trim(),
        'description': descCtrl.text.trim(),
      };
      if (sport == null) {
        await ref.read(adminRepositoryProvider).createSport(payload);
      } else {
        final id = (sport['_id'] ?? sport['id'])?.toString() ?? '';
        await ref.read(adminRepositoryProvider).updateSport(id, payload);
      }
      ref.invalidate(adminSportsProvider);
    }

    nameCtrl.dispose();
    iconCtrl.dispose();
    descCtrl.dispose();
  }
}
