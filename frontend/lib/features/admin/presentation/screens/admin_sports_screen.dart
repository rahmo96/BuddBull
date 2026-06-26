import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminSportsScreen extends ConsumerWidget {
  const AdminSportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sportsAsync = ref.watch(adminSportsProvider);

    return sportsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Failed to load sports: $e')),
      data: (sports) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () => _showSportForm(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('Add Sport'),
              ),
            ),
            Expanded(
              child: sports.isEmpty
                  ? const Center(child: Text('No sports yet'))
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
                              isActive ? 'Active' : 'Inactive',
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
                              itemBuilder: (_) => const [
                                PopupMenuItem(value: 'edit', child: Text('Edit')),
                                PopupMenuItem(
                                  value: 'delete',
                                  child: Text('Deactivate'),
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
    final nameCtrl = TextEditingController(text: sport?['name']?.toString() ?? '');
    final iconCtrl = TextEditingController(text: sport?['icon']?.toString() ?? '🏅');
    final descCtrl =
        TextEditingController(text: sport?['description']?.toString() ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(sport == null ? 'Add Sport' : 'Edit Sport'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: iconCtrl, decoration: const InputDecoration(labelText: 'Icon')),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
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
