import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';

const _sports = [
  'Football', 'Basketball', 'Tennis', 'Running',
  'Swimming', 'Cycling', 'Volleyball', 'Cricket',
];

const _logTypes = ['match', 'training', 'fitness'];
const _outcomes = ['win', 'loss', 'draw'];
const _moods = ['great', 'good', 'ok', 'tired', 'injured'];
const _moodEmojis = {'great': '😄', 'good': '🙂', 'ok': '😐', 'tired': '😴', 'injured': '🤕'};

class CreateLogScreen extends ConsumerStatefulWidget {
  const CreateLogScreen({super.key});

  @override
  ConsumerState<CreateLogScreen> createState() =>
      _CreateLogScreenState();
}

class _CreateLogScreenState
    extends ConsumerState<CreateLogScreen> {
  final _formKey = GlobalKey<FormState>();
  final _notesCtrl = TextEditingController();

  String _sport = _sports.first;
  String _logType = 'training';
  String? _outcome;
  String? _mood;
  DateTime _loggedAt = DateTime.now();
  int? _durationMinutes = 60;
  int _selfRating = 7;
  bool _isPublic = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _loggedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _loggedAt = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final payload = {
      'sport': _sport,
      'type': _logType,
      'loggedAt': _loggedAt.toIso8601String(),
      if (_outcome != null && _logType == 'match')
        'matchOutcome': _outcome,
      if (_durationMinutes != null)
        'durationMinutes': _durationMinutes,
      'selfRating': _selfRating,
      if (_mood != null) 'mood': _mood,
      if (_notesCtrl.text.trim().isNotEmpty)
        'notes': _notesCtrl.text.trim(),
      'isPublic': _isPublic,
    };

    final ok =
        await ref.read(createLogProvider.notifier).createLog(payload);
    if (!mounted) return;

    if (ok) {
      final logState = ref.read(createLogProvider);
      if (logState.hasPersonalBests) {
        _showPersonalBestDialog();
      } else {
        showSuccessSnackBar(context, 'Session logged! 💪');
        context.pop();
      }
    }
  }

  void _showPersonalBestDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('🏅 New Personal Best!'),
        content: const Text(
          'You beat your previous record! '
          'Keep it up! 🎉',
        ),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: const Text('Awesome!'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createLogProvider);

    ref.listen(createLogProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnackBar(context, next.error!);
        ref.read(createLogProvider.notifier).clearError();
      }
    });

    return LoadingOverlay(
      isLoading: state.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Log a Session')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sport ─────────────────────────────────────
                const _SectionLabel(label: 'Sport *'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sports
                      .map(
                        (s) => _PickerChip(
                          label: s,
                          selected: _sport == s,
                          onTap: () =>
                              setState(() => _sport = s),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),

                // ── Log type ───────────────────────────────────
                const _SectionLabel(label: 'Session type *'),
                const SizedBox(height: 8),
                Row(
                  spacing: 10,
                  children: _logTypes.map((t) {
                    final icons = {
                      'match': Icons.sports_score_rounded,
                      'training': Icons.fitness_center_rounded,
                      'fitness': Icons.directions_run_rounded,
                    };
                    return Expanded(
                      child: _TypeCard(
                        icon: icons[t]!,
                        label: t[0].toUpperCase() + t.substring(1),
                        selected: _logType == t,
                        onTap: () => setState(() {
                          _logType = t;
                          if (t != 'match') _outcome = null;
                        }),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Date ───────────────────────────────────────
                const _SectionLabel(label: 'Date'),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.grey100,
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: AppColors.grey300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today_rounded,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Text(
                          DateFormat('EEE, d MMM y')
                              .format(_loggedAt),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Outcome (match only) ───────────────────────
                if (_logType == 'match') ...[
                  const _SectionLabel(label: 'Outcome'),
                  const SizedBox(height: 8),
                  Row(
                    spacing: 10,
                    children: _outcomes.map((o) {
                      final emojis = {
                        'win': '🏆',
                        'loss': '❌',
                        'draw': '🤝',
                      };
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(
                              () => _outcome =
                                  _outcome == o ? null : o),
                          child: AnimatedContainer(
                            duration:
                                const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                vertical: 12),
                            decoration: BoxDecoration(
                              color: _outcome == o
                                  ? AppColors.primary
                                  : AppColors.grey100,
                              borderRadius:
                                  BorderRadius.circular(12),
                              border: Border.all(
                                color: _outcome == o
                                    ? AppColors.primary
                                    : AppColors.grey300,
                              ),
                            ),
                            child: Column(
                              children: [
                                Text(emojis[o]!,
                                    style: const TextStyle(
                                        fontSize: 22)),
                                const SizedBox(height: 4),
                                Text(
                                  o[0].toUpperCase() +
                                      o.substring(1),
                                  style: AppTextStyles.labelMedium
                                      .copyWith(
                                    color: _outcome == o
                                        ? Colors.white
                                        : AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Duration ───────────────────────────────────
                _SectionLabel(
                    label:
                        'Duration${_durationMinutes != null ? ': ${_durationMinutes}min' : ''}'),
                Slider(
                  value:
                      (_durationMinutes ?? 60).toDouble(),
                  min: 5,
                  max: 240,
                  divisions: 47,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.grey300,
                  label: '$_durationMinutes min',
                  onChanged: (v) => setState(
                      () => _durationMinutes = v.round()),
                ),
                const SizedBox(height: 16),

                // ── Self rating ────────────────────────────────
                _SectionLabel(
                    label: 'How did you perform? $_selfRating/10'),
                Slider(
                  value: _selfRating.toDouble(),
                  min: 1,
                  max: 10,
                  divisions: 9,
                  activeColor: _ratingColor(_selfRating),
                  inactiveColor: AppColors.grey300,
                  label: '$_selfRating',
                  onChanged: (v) =>
                      setState(() => _selfRating = v.round()),
                ),
                const SizedBox(height: 20),

                // ── Mood ───────────────────────────────────────
                const _SectionLabel(label: 'How did you feel?'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: _moods.map((m) {
                    return GestureDetector(
                      onTap: () => setState(
                          () => _mood = _mood == m ? null : m),
                      child: AnimatedContainer(
                        duration:
                            const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _mood == m
                              ? AppColors.primary
                                  .withOpacity(0.12)
                              : AppColors.grey100,
                          borderRadius:
                              BorderRadius.circular(12),
                          border: Border.all(
                            color: _mood == m
                                ? AppColors.primary
                                : AppColors.grey300,
                            width: _mood == m ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(_moodEmojis[m]!,
                                style: const TextStyle(
                                    fontSize: 22)),
                            const SizedBox(height: 2),
                            Text(m,
                                style: AppTextStyles
                                    .labelSmall),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Notes ──────────────────────────────────────
                BbTextField(
                  label: 'Notes',
                  hint: 'What went well? What to improve?',
                  controller: _notesCtrl,
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 16),

                // ── Public toggle ──────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: AppColors.grey300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.public_rounded,
                          size: 18,
                          color: AppColors.textSecondary),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Make this log public',
                          style: AppTextStyles.bodyMedium,
                        ),
                      ),
                      Switch(
                        value: _isPublic,
                        onChanged: (v) =>
                            setState(() => _isPublic = v),
                        activeThumbColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                BbButton(
                  label: 'Save Session 💪',
                  onPressed: _submit,
                  isLoading: state.isSubmitting,
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _ratingColor(int rating) {
    if (rating >= 8) return AppColors.success;
    if (rating >= 5) return AppColors.primary;
    return AppColors.error;
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: AppTextStyles.titleSmall);
}

class _PickerChip extends StatelessWidget {
  const _PickerChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                selected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected
                ? Colors.white
                : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.1)
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? AppColors.primary : AppColors.grey300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 24,
              color: selected
                  ? AppColors.primary
                  : AppColors.grey500,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: selected
                    ? AppColors.primary
                    : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
