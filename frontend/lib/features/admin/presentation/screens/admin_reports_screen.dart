import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/admin/providers/admin_provider.dart';
import 'package:buddbull/features/reports/data/report_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  String? _status;
  String? _targetType;
  String _sort = '-createdAt';

  @override
  Widget build(BuildContext context) {
    final params = AdminReportsParams(
      status: _status,
      targetType: _targetType,
      sort: _sort,
    );
    final reportsAsync = ref.watch(adminReportsProvider(params));

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Row(
            children: [
              _FilterChip(
                label: 'All',
                selected: _status == null,
                onSelected: () => setState(() => _status = null),
              ),
              _FilterChip(
                label: 'Open',
                selected: _status == 'open',
                onSelected: () => setState(() => _status = 'open'),
              ),
              _FilterChip(
                label: 'In Progress',
                selected: _status == 'in_progress',
                onSelected: () => setState(() => _status = 'in_progress'),
              ),
              _FilterChip(
                label: 'Closed',
                selected: _status == 'closed',
                onSelected: () => setState(() => _status = 'closed'),
              ),
              const SizedBox(width: 8),
              _FilterChip(
                label: 'Users',
                selected: _targetType == 'user',
                onSelected: () => setState(() => _targetType = 'user'),
              ),
              _FilterChip(
                label: 'Games',
                selected: _targetType == 'game',
                onSelected: () => setState(() => _targetType = 'game'),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: 'Sort by date',
                onPressed: () => setState(
                  () => _sort = _sort == '-createdAt' ? 'createdAt' : '-createdAt',
                ),
                icon: Icon(
                  _sort == '-createdAt'
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: reportsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Failed to load reports: $e')),
            data: (data) {
              final reports = (data['reports'] as List? ?? [])
                  .whereType<Map<String, dynamic>>()
                  .map(ReportModel.fromJson)
                  .toList();
              if (reports.isEmpty) {
                return const Center(child: Text('No reports found'));
              }
              return RefreshIndicator(
                onRefresh: () => ref.refresh(adminReportsProvider(params).future),
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: reports.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ReportRow(
                    report: reports[i],
                    onTap: () => _openDetail(reports[i], params),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openDetail(ReportModel report, AdminReportsParams params) async {
    final notesCtrl = TextEditingController(text: report.adminNotes ?? '');
    var status = report.status;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                20 + MediaQuery.viewInsetsOf(ctx).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(report.title, style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'Reporter: @${report.reporterUsername ?? 'unknown'}',
                    style: AppTextStyles.bodySmall,
                  ),
                  Text(
                    report.targetType == 'user'
                        ? 'Reported user: @${report.reportedUsername ?? 'unknown'}'
                        : 'Reported game: ${report.reportedGameTitle ?? 'unknown'}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Text(report.reason, style: AppTextStyles.bodyMedium),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'open', child: Text('Open')),
                      DropdownMenuItem(
                        value: 'in_progress',
                        child: Text('In Progress'),
                      ),
                      DropdownMenuItem(value: 'closed', child: Text('Closed')),
                    ],
                    onChanged: (v) {
                      if (v != null) setModalState(() => status = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Admin notes',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: () async {
                      await ref.read(adminRepositoryProvider).updateReport(
                            report.id,
                            status: status,
                            adminNotes: notesCtrl.text.trim(),
                          );
                      ref.invalidate(adminReportsProvider(params));
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
    notesCtrl.dispose();
  }
}

class _ReportRow extends StatelessWidget {
  const _ReportRow({required this.report, required this.onTap});
  final ReportModel report;
  final VoidCallback onTap;

  Color _statusColor(String status) => switch (status) {
        'open' => AppColors.warning,
        'in_progress' => AppColors.info,
        'closed' => AppColors.success,
        _ => AppColors.textSecondary,
      };

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      report.title,
                      style: AppTextStyles.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(report.status).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      report.status.replaceAll('_', ' '),
                      style: AppTextStyles.caption.copyWith(
                        color: _statusColor(report.status),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '@${report.reporterUsername ?? '?'} · ${report.targetType}',
                style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
              ),
              Text(
                report.reason,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
      ),
    );
  }
}
