import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class AdminGamesScreen extends ConsumerStatefulWidget {
  const AdminGamesScreen({super.key});

  @override
  ConsumerState<AdminGamesScreen> createState() => _AdminGamesScreenState();
}

class _AdminGamesScreenState extends ConsumerState<AdminGamesScreen> {
  String? _status;

  @override
  Widget build(BuildContext context) {
    final gamesAsync = ref.watch(adminGamesProvider(_status));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _StatusChip(
                        label: 'All',
                        selected: _status == null,
                        onTap: () => setState(() => _status = null),
                      ),
                      _StatusChip(
                        label: 'Open',
                        selected: _status == 'open',
                        onTap: () => setState(() => _status = 'open'),
                      ),
                      _StatusChip(
                        label: 'Full',
                        selected: _status == 'full',
                        onTap: () => setState(() => _status = 'full'),
                      ),
                      _StatusChip(
                        label: 'Completed',
                        selected: _status == 'completed',
                        onTap: () => setState(() => _status = 'completed'),
                      ),
                      _StatusChip(
                        label: 'Cancelled',
                        selected: _status == 'cancelled',
                        onTap: () => setState(() => _status = 'cancelled'),
                      ),
                    ],
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Create event',
                onPressed: () => context.push(Routes.createGame),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
        Expanded(
          child: gamesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load games: $e')),
            data: (data) {
              final games = (data['games'] as List? ?? []).cast<Map<String, dynamic>>();
              if (games.isEmpty) {
                return const Center(child: Text('No games found'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(adminGamesProvider(_status).future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: games.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final game = games[i];
                    final gameId = (game['_id'] ?? game['id'])?.toString() ?? '';
                    return ListTile(
                      tileColor: AppColors.surface,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppColors.border),
                      ),
                      title: Text(game['title']?.toString() ?? ''),
                      subtitle: Text(
                        '${game['sport'] ?? ''} · ${game['status'] ?? ''}',
                        style: AppTextStyles.caption,
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error),
                        onPressed: () async {
                          await ref.read(adminRepositoryProvider).deleteGame(gameId);
                          ref.invalidate(adminGamesProvider(_status));
                        },
                      ),
                      onTap: () => context.push(Routes.gameDetail(gameId)),
                    );
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
      ),
    );
  }
}
