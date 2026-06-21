import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/reports/data/report_repository.dart';
import 'package:buddbull/features/reports/providers/report_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Runs the full report flow: confirm → form → confirm → submit.
Future<void> showReportFlow(
  BuildContext context,
  WidgetRef ref, {
  required ReportTargetType targetType,
  required String targetId,
  String? targetLabel,
}) async {
  final targetName = targetLabel ??
      (targetType == ReportTargetType.user ? 'this user' : 'this game');

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Confirm Report'),
      content: Text(
        'Are you sure you want to report $targetName? '
        'False reports may result in action against your account.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Continue', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;

  final formResult = await showModalBottomSheet<Map<String, String>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => const _ReportFormSheet(),
  );
  if (formResult == null || !context.mounted) return;

  final submitConfirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Submit Report?'),
      content: Text(
        'Your report titled "${formResult['title']}" will be sent to admins for review.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Go Back'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Submit', style: TextStyle(color: AppColors.error)),
        ),
      ],
    ),
  );
  if (submitConfirmed != true || !context.mounted) return;

  final success = await ref.read(submitReportProvider.notifier).submit(
        targetType: targetType,
        reportedUserId:
            targetType == ReportTargetType.user ? targetId : null,
        reportedGameId:
            targetType == ReportTargetType.game ? targetId : null,
        title: formResult['title']!,
        reason: formResult['reason']!,
      );

  if (!context.mounted) return;
  if (success) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Report submitted. Admins will review it shortly.'),
        backgroundColor: AppColors.success,
      ),
    );
  } else {
    final error = ref.read(submitReportProvider).error ?? 'Failed to submit report';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error), backgroundColor: AppColors.error),
    );
  }
}

class _ReportFormSheet extends StatefulWidget {
  const _ReportFormSheet();

  @override
  State<_ReportFormSheet> createState() => _ReportFormSheetState();
}

class _ReportFormSheetState extends State<_ReportFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _reasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + bottomInset),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text('Report Details', style: AppTextStyles.titleMedium),
            const SizedBox(height: 16),
            BbTextField(
              label: 'Title',
              controller: _titleCtrl,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
            const SizedBox(height: 12),
            BbTextField(
              label: 'Reason',
              controller: _reasonCtrl,
              maxLines: 4,
              minLines: 3,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Reason is required' : null,
            ),
            const SizedBox(height: 20),
            BbButton(
              label: 'Continue',
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                Navigator.pop(context, {
                  'title': _titleCtrl.text.trim(),
                  'reason': _reasonCtrl.text.trim(),
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Red report button for profile and game screens.
class ReportActionButton extends ConsumerWidget {
  const ReportActionButton({
    super.key,
    required this.targetType,
    required this.targetId,
    this.targetLabel,
    this.label = 'Report User',
  });

  final ReportTargetType targetType;
  final String targetId;
  final String? targetLabel;
  final String label;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return OutlinedButton.icon(
      onPressed: () => showReportFlow(
        context,
        ref,
        targetType: targetType,
        targetId: targetId,
        targetLabel: targetLabel,
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.error,
        side: const BorderSide(color: AppColors.error),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
      icon: const Icon(Icons.warning_amber_rounded, color: AppColors.error),
      label: Text(
        label,
        style: AppTextStyles.labelLarge.copyWith(
          color: AppColors.error,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
