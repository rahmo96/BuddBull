import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/features/admin/data/admin_repository.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:buddbull/features/admin/presentation/widgets/stat_card.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  String _period = '30d';
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastBodyCtrl = TextEditingController();

  @override
  void dispose() {
    _broadcastTitleCtrl.dispose();
    _broadcastBodyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dashboardAsync = ref.watch(adminDashboardProvider(_period));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: Text('Admin Dashboard', style: AppTextStyles.titleLarge),
        actions: [
          // Period selector
          PopupMenuButton<String>(
            initialValue: _period,
            onSelected: (v) => setState(() => _period = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: '7d', child: Text('Last 7 days')),
              PopupMenuItem(value: '30d', child: Text('Last 30 days')),
              PopupMenuItem(value: '90d', child: Text('Last 90 days')),
            ],
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Text(_period, style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  const Icon(Icons.arrow_drop_down, color: AppColors.primary),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(adminDashboardProvider(_period)),
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Failed to load dashboard', style: AppTextStyles.bodyMedium),
              TextButton(
                onPressed: () => ref.invalidate(adminDashboardProvider(_period)),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (stats) => _buildDashboard(stats),
      ),
    );
  }

  Widget _buildDashboard(AdminDashboardStats stats) {
    return RefreshIndicator(
      onRefresh: () => ref.refresh(adminDashboardProvider(_period).future),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User stats ──────────────────────────────────────────
          Text('Users', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdminStatCard(label: 'Total Users', value: '${stats.users.total}', icon: Icons.people),
              AdminStatCard(
                label: 'Active (30d)',
                value: '${stats.users.active}',
                icon: Icons.trending_up,
                color: AppColors.success,
              ),
              AdminStatCard(
                label: 'New (period)',
                value: '+${stats.users.newUsers}',
                icon: Icons.person_add_alt_1,
                color: const Color(0xFF8B5CF6),
              ),
              AdminStatCard(
                label: 'Churn Rate',
                value: stats.users.churnRate,
                icon: Icons.trending_down,
                color: Colors.orange,
                subtitle: '${stats.users.churned} users',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Registration chart ──────────────────────────────────
          if (stats.dailyRegistrations.isNotEmpty) ...[
            Text('Registrations', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            _RegistrationChart(data: stats.dailyRegistrations),
            const SizedBox(height: 24),
          ],

          // ── Game stats ──────────────────────────────────────────
          Text('Games', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
          const SizedBox(height: 10),
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdminStatCard(label: 'Total Games', value: '${stats.games.total}', icon: Icons.sports),
              AdminStatCard(
                label: 'Active',
                value: '${stats.games.active}',
                icon: Icons.play_circle_outline,
                color: AppColors.success,
              ),
              AdminStatCard(
                label: 'Completed',
                value: '${stats.games.completed}',
                icon: Icons.check_circle_outline,
                color: AppColors.primary,
              ),
              AdminStatCard(
                label: 'Cancelled',
                value: '${stats.games.cancelled}',
                icon: Icons.cancel_outlined,
                color: Colors.red,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ── Sport breakdown ─────────────────────────────────────
          if (stats.sportBreakdown.isNotEmpty) ...[
            Text('Top Sports', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 10),
            ...stats.sportBreakdown.take(5).map((s) => _SportRow(sport: s)),
            const SizedBox(height: 24),
          ],

          // ── Broadcast panel ──────────────────────────────────────
          _BroadcastPanel(
            titleCtrl: _broadcastTitleCtrl,
            bodyCtrl: _broadcastBodyCtrl,
            onSend: _sendBroadcast,
          ),

          const SizedBox(height: 32),

          // ── Users table shortcut ─────────────────────────────────
          _AdminUsersPreview(),
        ],
      ),
    );
  }

  Future<void> _sendBroadcast() async {
    final title = _broadcastTitleCtrl.text.trim();
    final body = _broadcastBodyCtrl.text.trim();
    if (title.isEmpty || body.isEmpty) return;

    final success = await ref.read(broadcastProvider.notifier).send(
          title: title,
          body: body,
          channel: 'both',
        );
    if (mounted) {
      if (success) {
        _broadcastTitleCtrl.clear();
        _broadcastBodyCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast sent!'), backgroundColor: AppColors.success),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Broadcast failed'), backgroundColor: Colors.red),
        );
      }
    }
  }
}

// ── Registration sparkline chart ──────────────────────────────────────────────
class _RegistrationChart extends StatelessWidget {
  final List<DailyCount> data;
  const _RegistrationChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final spots = data.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.count.toDouble())).toList();
    final maxY = data.map((d) => d.count).fold(0, (a, b) => a > b ? a : b).toDouble() + 2;

    return Container(
      height: 140,
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: const FlTitlesData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppColors.primary,
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              belowBarData: BarAreaData(
                show: true,
                color: AppColors.primary.withOpacity(0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sport breakdown row ───────────────────────────────────────────────────────
class _SportRow extends StatelessWidget {
  final SportCount sport;
  const _SportRow({required this.sport});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Text(
              _capitalize(sport.sport),
              style: AppTextStyles.bodySmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: LinearProgressIndicator(
              value: 1.0, // simplified — would need max for real ratio
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 8),
          Text('${sport.count}', style: AppTextStyles.caption.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _capitalize(String s) => s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}

// ── Broadcast panel ───────────────────────────────────────────────────────────
class _BroadcastPanel extends ConsumerWidget {
  final TextEditingController titleCtrl;
  final TextEditingController bodyCtrl;
  final VoidCallback onSend;

  const _BroadcastPanel({
    required this.titleCtrl,
    required this.bodyCtrl,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final broadcastState = ref.watch(broadcastProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.campaign_outlined, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text('Global Broadcast', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: bodyCtrl,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Message body',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          BbButton(
            label: 'Send to All Users',
            isLoading: broadcastState.isLoading,
            onPressed: onSend,
          ),
        ],
      ),
    );
  }
}

// ── Admin users mini-list ─────────────────────────────────────────────────────
class _AdminUsersPreview extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Recent Users', style: AppTextStyles.labelLarge.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 10),
        usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const Text('Failed to load users', style: AppTextStyles.caption),
          data: (data) {
            final users = (data['users'] as List? ?? []).cast<Map<String, dynamic>>();
            if (users.isEmpty) {
              return Text('No users found', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary));
            }
            return Column(
              children: users.take(10).map((u) => _UserRow(user: u, ref: ref)).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _UserRow extends StatelessWidget {
  final Map<String, dynamic> user;
  final WidgetRef ref;

  const _UserRow({required this.user, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isBanned = user['isBanned'] == true;
    final name = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
    final username = user['username']?.toString() ?? '';
    final role = user['role']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isBanned ? Colors.red.withOpacity(0.3) : AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name.isNotEmpty ? name : username, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w600)),
                Text('@$username · $role', style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          if (isBanned)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text('Banned', style: AppTextStyles.caption.copyWith(color: Colors.red)),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textSecondary),
            onSelected: (action) => _handleAction(context, action, user),
            itemBuilder: (_) => [
              PopupMenuItem(value: isBanned ? 'unban' : 'ban', child: Text(isBanned ? 'Unban' : 'Ban')),
              const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: Colors.red))),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleAction(BuildContext context, String action, Map<String, dynamic> user) async {
    final userId = (user['_id'] ?? user['id'])?.toString() ?? '';
    if (action == 'ban' || action == 'unban') {
      await ref.read(banUserProvider.notifier).banUser(userId, isBanned: action == 'ban');
      ref.invalidate(adminUsersProvider);
    } else if (action == 'delete') {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete User'),
          content: Text('Are you sure you want to delete @${user['username']}? This cannot be undone.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (confirm == true) {
        await ref.read(adminRepositoryProvider).deleteUser(userId);
        ref.invalidate(adminUsersProvider);
      }
    }
  }
}
