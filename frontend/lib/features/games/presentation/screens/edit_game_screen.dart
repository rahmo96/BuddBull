import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/date_format_utils.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
class EditGameScreen extends ConsumerStatefulWidget {
  const EditGameScreen({super.key, required this.gameId});
  final String gameId;

  @override
  ConsumerState<EditGameScreen> createState() => _EditGameScreenState();
}

class _EditGameScreenState extends ConsumerState<EditGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();

  String _sport = 'football';
  String _skillLevel = 'any';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _durationMinutes = 60;
  int _maxPlayers = 10;
  GameLocation? _locationMetadata;

  bool _isSubmitting = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _venueCtrl.dispose();
    super.dispose();
  }

  void _hydrateFromGame(GameModel g) {
    _titleCtrl.text = g.title;
    _descCtrl.text = g.description ?? '';
    _sport = g.sport;
    _skillLevel = g.requiredSkillLevel;
    final dt = g.scheduledAt;
    _date = DateTime(dt.year, dt.month, dt.day);
    _time = TimeOfDay(hour: dt.hour, minute: dt.minute);
    _durationMinutes = g.durationMinutes;
    _maxPlayers = g.maxPlayers;
    _addressCtrl.text = g.location.formattedAddress ?? g.location.address ?? '';
    _cityCtrl.text = g.location.city;
    _neighborhoodCtrl.text = g.location.neighborhood ?? '';
    _venueCtrl.text = g.location.venueName ?? '';
    _locationMetadata = g.location;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx).colorScheme.copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final updates = <String, dynamic>{
      'title': _titleCtrl.text.trim(),
      'sport': _sport,
      if (_descCtrl.text.trim().isNotEmpty) 'description': _descCtrl.text.trim(),
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationMinutes': _durationMinutes,
      'location': {
        'city': _cityCtrl.text.trim(),
        if (_neighborhoodCtrl.text.trim().isNotEmpty) 'neighborhood': _neighborhoodCtrl.text.trim(),
        if (_venueCtrl.text.trim().isNotEmpty) 'venueName': _venueCtrl.text.trim(),
        if (_addressCtrl.text.trim().isNotEmpty) 'formattedAddress': _addressCtrl.text.trim(),
        if (((_locationMetadata?.address) ?? '').trim().isNotEmpty) 'address': _locationMetadata?.address,
        if (((_locationMetadata?.placeId) ?? '').trim().isNotEmpty) 'placeId': _locationMetadata?.placeId,
        if (((_locationMetadata?.state) ?? '').trim().isNotEmpty) 'state': _locationMetadata?.state,
        if (((_locationMetadata?.country) ?? '').trim().isNotEmpty) 'country': _locationMetadata?.country,
        if (((_locationMetadata?.postalCode) ?? '').trim().isNotEmpty) 'postalCode': _locationMetadata?.postalCode,
        if (_locationMetadata?.coordinates != null) 'coordinates': _locationMetadata!.coordinates!.toJson(),
      },
      'maxPlayers': _maxPlayers,
      'requiredSkillLevel': _skillLevel,
    };

    setState(() => _isSubmitting = true);
    try {
      final repo = ref.read(gameRepositoryProvider);
      await repo.updateGame(widget.gameId, updates);
      ref.invalidate(gameDetailProvider(widget.gameId));
      ref.invalidate(myGamesProvider);
      ref.invalidate(calendarGamesProvider);
      if (!mounted) return;
      showSuccessSnackBar(context, context.l10n.gameUpdatedSuccess);
      context.pop();
    } catch (e) {
      if (!mounted) return;
      showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final gameAsync = ref.watch(gameDetailProvider(widget.gameId));

    return LoadingOverlay(
      isLoading: _isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: Text(l10n.editGameTitle)),
        body: gameAsync.when(
          loading: () => const Center(child: BbLoadingIndicator()),
          error: (e, _) => ErrorView(message: e.toString()),
          data: (game) {
            // One-time hydrate when first loaded
            final alreadyHydrated = _titleCtrl.text.isNotEmpty;
            if (!alreadyHydrated) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                setState(() => _hydrateFromGame(game));
              });
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.sectionDetails, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    BbTextField(
                      label: l10n.editTitleLabel,
                      hint: l10n.gameTitleHint,
                      controller: _titleCtrl,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? l10n.gameTitleRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    BbTextField(
                      label: l10n.descriptionLabel,
                      hint: l10n.optionalHint,
                      controller: _descCtrl,
                      maxLines: 3,
                      minLines: 2,
                    ),
                    const SizedBox(height: 16),

                    Text(l10n.sectionSchedule, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.calendar_today_rounded,
                            label: AppDateFormat.mediumDate(context, _date),
                            onTap: _pickDate,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _PickerTile(
                            icon: Icons.schedule_rounded,
                            label: _time.format(context),
                            onTap: _pickTime,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    Text(
                      l10n.durationMinutesOnly(_durationMinutes),
                      style: AppTextStyles.bodyMedium,
                    ),
                    Slider(
                      value: _durationMinutes.toDouble(),
                      min: 15,
                      max: 240,
                      divisions: 45,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.grey300,
                      label: l10n.sliderMinutesLabel(_durationMinutes),
                      onChanged: (v) => setState(() => _durationMinutes = v.round()),
                    ),
                    const SizedBox(height: 16),

                    Text(
                      l10n.maxPlayersLabel(_maxPlayers),
                      style: AppTextStyles.bodyMedium,
                    ),
                    Slider(
                      value: _maxPlayers.toDouble(),
                      min: 2,
                      max: 50,
                      divisions: 48,
                      activeColor: AppColors.primary,
                      inactiveColor: AppColors.grey300,
                      label: '$_maxPlayers',
                      onChanged: (v) => setState(() => _maxPlayers = v.round()),
                    ),
                    const SizedBox(height: 16),

                    Text(l10n.sectionLocation, style: AppTextStyles.titleMedium),
                    const SizedBox(height: 12),
                    BbTextField(
                      label: l10n.addressLabel,
                      hint: l10n.addressSelectedHint,
                      controller: _addressCtrl,
                      readOnly: true,
                    ),
                    const SizedBox(height: 12),
                    BbTextField(
                      label: l10n.cityRequiredLabel,
                      hint: l10n.cityLabel,
                      controller: _cityCtrl,
                      validator: (v) => (v?.trim().isEmpty ?? true)
                          ? l10n.cityRequiredError
                          : null,
                    ),
                    const SizedBox(height: 12),
                    BbTextField(
                      label: l10n.neighborhoodLabel,
                      hint: l10n.optionalHint,
                      controller: _neighborhoodCtrl,
                    ),
                    const SizedBox(height: 12),
                    BbTextField(
                      label: l10n.venueShortLabel,
                      hint: l10n.optionalHint,
                      controller: _venueCtrl,
                    ),
                    const SizedBox(height: 24),

                    BbButton(
                      label: l10n.saveChanges,
                      onPressed: _submit,
                      isLoading: _isSubmitting,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
          ],
        ),
      ),
    );
  }
}
