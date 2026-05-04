import 'package:flutter/material.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';

const _sports = [
  'Football', 'Basketball', 'Tennis', 'Running',
  'Swimming', 'Cycling', 'Volleyball', 'Cricket',
];

const _skillLevels = [
  'any', 'beginner', 'intermediate', 'advanced', 'professional',
];

/// Bottom sheet for filtering the games list.
class GameFilterSheet extends StatefulWidget {
  const GameFilterSheet({super.key, required this.params});
  final GameSearchParams params;

  @override
  State<GameFilterSheet> createState() => _GameFilterSheetState();
}

class _GameFilterSheetState extends State<GameFilterSheet> {
  late String? _sport;
  late String? _skillLevel;
  late TextEditingController _cityCtrl;

  @override
  void initState() {
    super.initState();
    _sport = widget.params.sport;
    _skillLevel = widget.params.skillLevel;
    _cityCtrl =
        TextEditingController(text: widget.params.city ?? '');
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 12,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ─────────────────────────────────────────
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grey300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Filter Games', style: AppTextStyles.headlineSmall),
                TextButton(
                  onPressed: () => setState(() {
                    _sport = null;
                    _skillLevel = null;
                    _cityCtrl.clear();
                  }),
                  child: const Text('Clear all'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // ── Sport picker ────────────────────────────────────
            const Text('Sport', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._sports.map((s) => _FilterChip(
                      label: s,
                      selected: _sport == s,
                      onTap: () =>
                          setState(() => _sport = _sport == s ? null : s),
                    )),
              ],
            ),
            const SizedBox(height: 20),

            // ── City ────────────────────────────────────────────
            BbTextField(
              label: 'City',
              hint: 'e.g. London',
              controller: _cityCtrl,
              prefixIcon: Icons.location_city_rounded,
            ),
            const SizedBox(height: 20),

            // ── Skill level ─────────────────────────────────────
            const Text('Required skill level', style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skillLevels.map((l) {
                final label = l == 'any'
                    ? 'Any level'
                    : l[0].toUpperCase() + l.substring(1);
                return _FilterChip(
                  label: label,
                  selected: (_skillLevel == null && l == 'any') ||
                      _skillLevel == l,
                  onTap: () => setState(
                      () => _skillLevel = l == 'any' ? null : l),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // ── Apply ───────────────────────────────────────────
            BbButton(
              label: 'Apply Filters',
              onPressed: () {
                Navigator.pop(
                  context,
                  GameSearchParams(
                    sport: _sport,
                    city: _cityCtrl.text.trim().isEmpty
                        ? null
                        : _cityCtrl.text.trim(),
                    skillLevel: _skillLevel,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
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
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary
              : AppColors.grey100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.grey300,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: selected ? Colors.white : AppColors.textPrimary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}
