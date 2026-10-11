import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/constants/log_labels.dart';
import 'package:buddbull/core/constants/sport_labels.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

const _sports = [
  'Football', 'Basketball', 'Tennis', 'Running', // l10n-ignore: API/search value
  'Swimming', 'Cycling', 'Volleyball', 'Cricket', // l10n-ignore: API/search value
];

const _logTypes = ['match', 'training', 'fitness']; // l10n-ignore: API/search value
const _outcomes = ['win', 'loss', 'draw']; // l10n-ignore: API/search value
const _moods = ['great', 'good', 'ok', 'tired', 'injured']; // l10n-ignore: API/search value
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
  String _logType = 'training'; // l10n-ignore: API/search value
  String? _outcome;
  String? _mood;
  DateTime _loggedAt = DateTime.now();
  int? _durationMinutes = 60;
  int _selfRating = 3;
  bool _isPublic = false;

  String _sportToBackend(String sport) => sport.trim().toLowerCase();

  String _moodToBackend(String uiMood) {
    return switch (uiMood) {
      'great' => 'excellent', // l10n-ignore: API/search value
      'good' => 'good', // l10n-ignore: API/search value
      'ok' => 'neutral', // l10n-ignore: API/search value
      'tired' => 'bad', // l10n-ignore: API/search value
      'injured' => 'terrible', // l10n-ignore: API/search value
      _ => 'neutral', // l10n-ignore: API/search value
    };
  }

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

    final backendMood = _mood == null ? null : _moodToBackend(_mood!);
    final selfRating = _selfRating.clamp(1, 5);
    final durationMinutes = _durationMinutes;

    final payload = {
      'sport': _sportToBackend(_sport),
      'type': _logType.trim().toLowerCase(),
      'loggedAt': _loggedAt.toIso8601String(),
      if (_outcome != null && _logType == 'match')
        'matchOutcome': _outcome,
      if (durationMinutes != null) 'durationMinutes': durationMinutes,
      'selfRating': selfRating,
      if (backendMood != null) 'mood': backendMood,
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
        showSuccessSnackBar(context, context.l10n.logFormSessionLogged);
        context.pop();
      }
    }
  }

  void _showPersonalBestDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.logFormPersonalBestTitle),
        content: Text(context.l10n.logFormPersonalBestBody),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text(context.l10n.logFormAwesome),
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
        appBar: AppBar(title: Text(context.l10n.logFormTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sport ─────────────────────────────────────
                _SectionLabel(label: context.l10n.gameFormSportLabel),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sports
                      .map(
                        (s) => _PickerChip(
                          label: sportDisplayName(s, context.l10n),
                          selected: _sport == s,
                          onTap: () =>
                              setState(() => _sport = s),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),

                // ── Log type ───────────────────────────────────
                _SectionLabel(label: context.l10n.logFormSessionType),
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
                        label: logTypeDisplayName(t, context.l10n),
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
                _SectionLabel(label: context.l10n.gameDetailDate),
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
                  _SectionLabel(label: context.l10n.logFormOutcome),
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
                                  outcomeDisplayName(o, context.l10n),
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
                    label: _durationMinutes != null
                        ? context.l10n.logFormDurationWithValue(_durationMinutes!)
                        : context.l10n.logFormDuration),
                Slider(
                  value:
                      (_durationMinutes ?? 60).toDouble(),
                  min: 5,
                  max: 240,
                  divisions: 47,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.grey300,
                  label: context.l10n.commonMinutes(_durationMinutes ?? 60),
                  onChanged: (v) => setState(
                      () => _durationMinutes = v.round()),
                ),
                const SizedBox(height: 16),

                // ── Self rating ────────────────────────────────
                _SectionLabel(
                    label: context.l10n.logFormSelfRating(_selfRating)),
                Slider(
                  value: _selfRating.toDouble(),
                  min: 1,
                  max: 5,
                  divisions: 4,
                  activeColor: _ratingColor(_selfRating),
                  inactiveColor: AppColors.grey300,
                  label: '$_selfRating',
                  onChanged: (v) =>
                      setState(() => _selfRating = v.round()),
                ),
                const SizedBox(height: 20),

                // ── Mood ───────────────────────────────────────
                _SectionLabel(label: context.l10n.logFormFeel),
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
                                  .withValues(alpha: 0.12)
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
                            Text(moodDisplayName(m, context.l10n),
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
                  label: context.l10n.logFormNotes,
                  hint: context.l10n.logFormNotesHint,
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
                      Expanded(
                        child: Text(
                          context.l10n.logFormPublic,
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
                  label: context.l10n.logFormSave,
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
    if (rating >= 5) return AppColors.success;
    if (rating >= 3) return AppColors.primary;
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
              ? AppColors.primary.withValues(alpha: 0.1)
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
