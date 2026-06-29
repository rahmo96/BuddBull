import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/date_format_utils.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/performance/providers/performance_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
  int _selfRating = 3;
  bool _isPublic = false;

  String _sportToBackend(String sport) => sport.trim().toLowerCase();

  String _moodToBackend(String uiMood) {
    return switch (uiMood) {
      'great' => 'excellent',
      'good' => 'good',
      'ok' => 'neutral',
      'tired' => 'bad',
      'injured' => 'terrible',
      _ => 'neutral',
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
        showSuccessSnackBar(context, context.l10n.sessionLoggedSuccess);
        context.pop();
      }
    }
  }

  void _showPersonalBestDialog() {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.newPersonalBestTitle),
        content: Text(l10n.newPersonalBestBody),
        actions: [
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.pop();
            },
            style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary),
            child: Text(l10n.awesome),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
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
        appBar: AppBar(title: Text(l10n.logSessionTitle)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sport ─────────────────────────────────────
                _SectionLabel(label: l10n.sportRequired),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sports
                      .map(
                        (s) => _PickerChip(
                          label: _sportDisplayName(context, s),
                          selected: _sport == s,
                          onTap: () =>
                              setState(() => _sport = s),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 20),

                // ── Log type ───────────────────────────────────
                _SectionLabel(label: l10n.sessionType),
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
                        label: _logTypeLabel(context, t),
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
                _SectionLabel(label: l10n.infoLabelDate),
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
                          AppDateFormat.mediumDate(context, _loggedAt),
                          style: AppTextStyles.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Outcome (match only) ───────────────────────
                if (_logType == 'match') ...[
                  _SectionLabel(label: l10n.outcome),
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
                                  _outcomeLabel(context, o),
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
                        ? l10n.durationWithMinutes(_durationMinutes!)
                        : l10n.infoLabelDuration),
                Slider(
                  value:
                      (_durationMinutes ?? 60).toDouble(),
                  min: 5,
                  max: 240,
                  divisions: 47,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.grey300,
                  label: l10n.sliderMinutesLabel(_durationMinutes ?? 60),
                  onChanged: (v) => setState(
                      () => _durationMinutes = v.round()),
                ),
                const SizedBox(height: 16),

                // ── Self rating ────────────────────────────────
                _SectionLabel(
                    label: l10n.howDidYouPerform(_selfRating)),
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
                _SectionLabel(label: l10n.howDidYouFeel),
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
                            Text(
                              _moodLabel(context, m),
                              style: AppTextStyles
                                  .labelSmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Notes ──────────────────────────────────────
                BbTextField(
                  label: l10n.notes,
                  hint: l10n.notesHint,
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
                          l10n.makeLogPublic,
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
                  label: l10n.saveSession,
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

String _sportDisplayName(BuildContext context, String sport) {
  final l10n = context.l10n;
  return switch (sport) {
    'Football' => l10n.sportFootball,
    'Basketball' => l10n.sportBasketball,
    'Tennis' => l10n.sportTennis,
    'Running' => l10n.sportRunning,
    'Swimming' => l10n.sportSwimming,
    'Cycling' => l10n.sportCycling,
    'Volleyball' => l10n.sportVolleyball,
    'Cricket' => l10n.sportCricket,
    _ => sport,
  };
}

String _logTypeLabel(BuildContext context, String type) {
  final l10n = context.l10n;
  return switch (type) {
    'match' => l10n.logTypeMatch,
    'training' => l10n.logTypeTraining,
    'fitness' => l10n.logTypeFitness,
    _ => type,
  };
}

String _outcomeLabel(BuildContext context, String outcome) {
  final l10n = context.l10n;
  return switch (outcome) {
    'win' => l10n.outcomeWin,
    'loss' => l10n.outcomeLoss,
    'draw' => l10n.outcomeDraw,
    _ => outcome,
  };
}

String _moodLabel(BuildContext context, String mood) {
  final l10n = context.l10n;
  return switch (mood) {
    'great' => l10n.moodGreat,
    'good' => l10n.moodGood,
    'ok' => l10n.moodOk,
    'tired' => l10n.moodTired,
    'injured' => l10n.moodInjured,
    _ => mood,
  };
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
