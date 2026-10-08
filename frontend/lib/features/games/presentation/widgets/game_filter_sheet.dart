import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/constants/skill_level_labels.dart';
import 'package:buddbull/core/constants/sport_labels.dart';
import 'package:buddbull/core/location/location_provider.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

const _sports = [
  'Football', 'Basketball', 'Tennis', 'Running', // l10n-ignore: API/search value
  'Swimming', 'Cycling', 'Volleyball', 'Cricket', // l10n-ignore: API/search value
];

const _skillLevels = [
  'any', 'beginner', 'intermediate', 'advanced', 'professional', // l10n-ignore: API/search value
];

/// Bottom sheet for filtering the games list.
class GameFilterSheet extends ConsumerStatefulWidget {
  const GameFilterSheet({super.key, required this.params});
  final GameSearchParams params;

  @override
  ConsumerState<GameFilterSheet> createState() => _GameFilterSheetState();
}

class _GameFilterSheetState extends ConsumerState<GameFilterSheet> {
  late String? _sport;
  late String? _skillLevel;
  late bool _nearMe;
  late TextEditingController _cityCtrl;
  bool _isResolvingLocation = false;

  @override
  void initState() {
    super.initState();
    _sport = widget.params.sport;
    _skillLevel = widget.params.skillLevel;
    _nearMe = widget.params.nearMe;
    _cityCtrl =
        TextEditingController(text: widget.params.city ?? '');
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    if (_nearMe) {
      setState(() => _isResolvingLocation = true);
      final position =
          await ref.read(locationServiceProvider).getPositionForSearch();
      if (!mounted) return;
      setState(() => _isResolvingLocation = false);

      if (position == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.commonLocationPermissionDenied)),
        );
        return;
      }

      final radiusKm =
          ref.read(currentUserProvider)?.location?.radiusKm ?? 10;

      Navigator.pop(
        context,
        GameSearchParams(
          sport: _sport,
          skillLevel: _skillLevel,
          lat: position.latitude,
          lng: position.longitude,
          radiusKm: radiusKm,
          sortBy: 'distance', // l10n-ignore: API/search value
        ),
      );
      return;
    }

    Navigator.pop(
      context,
      GameSearchParams(
        sport: _sport,
        city: _cityCtrl.text.trim().isEmpty ? null : _cityCtrl.text.trim(),
        skillLevel: _skillLevel,
        sortBy: 'scheduledAt', // l10n-ignore: API/search value
      ),
    );
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
                Text(context.l10n.gamesFilterTitle, style: AppTextStyles.headlineSmall),
                TextButton(
                  onPressed: () => setState(() {
                    _sport = null;
                    _skillLevel = null;
                    _nearMe = false;
                    _cityCtrl.clear();
                  }),
                  child: Text(context.l10n.commonClearAll),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(context.l10n.commonSport, style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ..._sports.map((s) => _FilterChip(
                      label: sportDisplayName(s, context.l10n),
                      selected: _sport == s,
                      onTap: () =>
                          setState(() => _sport = _sport == s ? null : s),
                    )),
              ],
            ),
            const SizedBox(height: 20),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(context.l10n.gamesFilterNearMe, style: AppTextStyles.labelLarge),
              subtitle: Text(
                context.l10n.gamesFilterNearMeHint,
                style: AppTextStyles.bodySmall,
              ),
              value: _nearMe,
              activeThumbColor: AppColors.primary,
              onChanged: (value) => setState(() {
                _nearMe = value;
                if (value) _cityCtrl.clear();
              }),
            ),
            if (!_nearMe) ...[
              const SizedBox(height: 8),
              BbTextField(
                label: context.l10n.profileCityLabel,
                hint: context.l10n.gamesFilterCityHint,
                controller: _cityCtrl,
                prefixIcon: Icons.location_city_rounded,
              ),
            ],
            const SizedBox(height: 20),
            Text(context.l10n.gamesFilterSkillTitle, style: AppTextStyles.labelLarge),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _skillLevels.map((l) {
                final label = skillLevelDisplayName(l, context.l10n);
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
            BbButton(
              label: _isResolvingLocation
                  ? context.l10n.gamesFilterGettingLocation
                  : context.l10n.gamesFilterApply,
              onPressed: _isResolvingLocation ? null : _apply,
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
