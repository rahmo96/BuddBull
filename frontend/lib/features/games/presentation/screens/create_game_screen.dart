import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/features/games/data/game_repository.dart';
import 'package:buddbull/features/games/data/models/game_model.dart';
import 'package:buddbull/features/games/providers/game_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';

const _sports = [
  'Football', 'Basketball', 'Tennis', 'Running',
  'Swimming', 'Cycling', 'Volleyball', 'Cricket',
];

const _skillLevels = [
  'any', 'beginner', 'intermediate', 'advanced', 'professional',
];

class CreateGameScreen extends ConsumerStatefulWidget {
  const CreateGameScreen({super.key});

  @override
  ConsumerState<CreateGameScreen> createState() =>
      _CreateGameScreenState();
}

class _CreateGameScreenState extends ConsumerState<CreateGameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _neighborhoodCtrl = TextEditingController();
  final _venueCtrl = TextEditingController();

  String _sport = _sports.first;
  String _skillLevel = 'any';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 18, minute: 0);
  int _durationMinutes = 60;
  int _maxPlayers = 10;
  Timer? _debounce;
  int _autocompleteRequestId = 0;
  bool _isFetchingSuggestions = false;
  bool _isResolvingPlace = false;
  String? _locationError;
  GameLocation? _selectedLocation;
  List<AddressSuggestion> _suggestions = const [];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _neighborhoodCtrl.dispose();
    _venueCtrl.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _onAddressChanged(String value) async {
    _debounce?.cancel();
    if (_selectedLocation != null && _addressCtrl.text.trim() != (_selectedLocation!.formattedAddress ?? '').trim()) {
      setState(() => _selectedLocation = null);
    }

    final query = value.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = const [];
        _isFetchingSuggestions = false;
      });
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final requestId = ++_autocompleteRequestId;
      setState(() => _isFetchingSuggestions = true);
      try {
        final suggestions = await ref.read(gameRepositoryProvider).autocompleteAddress(query);
        if (!mounted || requestId != _autocompleteRequestId) return;
        setState(() => _suggestions = suggestions);
      } catch (_) {
        if (!mounted || requestId != _autocompleteRequestId) return;
        setState(() => _suggestions = const []);
      } finally {
        if (mounted && requestId == _autocompleteRequestId) {
          setState(() => _isFetchingSuggestions = false);
        }
      }
    });
  }

  Future<void> _selectSuggestion(AddressSuggestion suggestion) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _isResolvingPlace = true;
      _locationError = null;
    });
    try {
      final location = await ref.read(gameRepositoryProvider).getPlaceDetails(suggestion.placeId);
      if (!mounted) return;
      _addressCtrl.text = location.formattedAddress ?? suggestion.description;
      _cityCtrl.text = location.city;
      _neighborhoodCtrl.text = location.neighborhood ?? '';
      _venueCtrl.text = location.venueName ?? '';
      setState(() {
        _selectedLocation = location;
        _suggestions = const [];
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _locationError = 'Could not verify this address. Please choose another one.';
      });
      showErrorSnackBar(context, e.toString());
    } finally {
      if (mounted) {
        setState(() => _isResolvingPlace = false);
      }
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.primary),
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
          colorScheme: Theme.of(ctx)
              .colorScheme
              .copyWith(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedLocation == null) {
      setState(() => _locationError = 'Please select a valid address from suggestions.');
      return;
    }

    final scheduledAt = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );

    final payload = {
      'title': _titleCtrl.text.trim(),
      'sport': _sport,
      if (_descCtrl.text.trim().isNotEmpty)
        'description': _descCtrl.text.trim(),
      'scheduledAt': scheduledAt.toIso8601String(),
      'durationMinutes': _durationMinutes,
      'location': {
        'city': _selectedLocation!.city,
        if (_neighborhoodCtrl.text.trim().isNotEmpty)
          'neighborhood': _neighborhoodCtrl.text.trim(),
        if (_venueCtrl.text.trim().isNotEmpty)
          'venueName': _venueCtrl.text.trim(),
        if ((_selectedLocation!.address ?? '').trim().isNotEmpty)
          'address': _selectedLocation!.address,
        if ((_selectedLocation!.formattedAddress ?? '').trim().isNotEmpty)
          'formattedAddress': _selectedLocation!.formattedAddress,
        if ((_selectedLocation!.placeId ?? '').trim().isNotEmpty)
          'placeId': _selectedLocation!.placeId,
        if ((_selectedLocation!.state ?? '').trim().isNotEmpty)
          'state': _selectedLocation!.state,
        if ((_selectedLocation!.country ?? '').trim().isNotEmpty)
          'country': _selectedLocation!.country,
        if ((_selectedLocation!.postalCode ?? '').trim().isNotEmpty)
          'postalCode': _selectedLocation!.postalCode,
        if (_selectedLocation!.coordinates != null)
          'coordinates': _selectedLocation!.coordinates!.toJson(),
      },
      'maxPlayers': _maxPlayers,
      'requiredSkillLevel': _skillLevel,
    };

    final ok = await ref
        .read(createGameProvider.notifier)
        .createGame(payload);
    if (ok && mounted) {
      showSuccessSnackBar(context, 'Game created! 🎉');
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createGameProvider);

    ref.listen(createGameProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnackBar(context, next.error!);
        ref.read(createGameProvider.notifier).clearError();
      }
    });

    return LoadingOverlay(
      isLoading: state.isSubmitting,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(title: const Text('Create Game')),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Sport picker ─────────────────────────────
                const _SectionLabel(label: 'Sport *'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _sports.map((s) {
                    final selected = _sport == s;
                    return GestureDetector(
                      onTap: () => setState(() => _sport = s),
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
                            color: selected
                                ? AppColors.primary
                                : AppColors.grey300,
                          ),
                        ),
                        child: Text(
                          s,
                          style: AppTextStyles.labelMedium.copyWith(
                            color: selected
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),

                // ── Title ────────────────────────────────────
                BbTextField(
                  label: 'Game title *',
                  hint: 'e.g. Sunday 5-a-side',
                  controller: _titleCtrl,
                  prefixIcon: Icons.sports_score_rounded,
                  validator: (v) => (v?.trim().isEmpty ?? true)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),

                // ── Description ──────────────────────────────
                BbTextField(
                  label: 'Description',
                  hint: 'Optional details, rules, what to bring…',
                  controller: _descCtrl,
                  maxLines: 3,
                  minLines: 2,
                ),
                const SizedBox(height: 20),

                // ── Date & time ──────────────────────────────
                const _SectionLabel(label: 'Date & Time *'),
                const SizedBox(height: 8),
                Row(
                  spacing: 10,
                  children: [
                    Expanded(
                      child: _TappableField(
                        icon: Icons.calendar_today_rounded,
                        label: DateFormat('EEE, d MMM y').format(_date),
                        onTap: _pickDate,
                      ),
                    ),
                    Expanded(
                      child: _TappableField(
                        icon: Icons.access_time_rounded,
                        label: _time.format(context),
                        onTap: _pickTime,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ── Duration slider ──────────────────────────
                _SectionLabel(
                    label: 'Duration: ${_durationMinutes ~/ 60}h '
                        '${(_durationMinutes % 60).toString().padLeft(2, '0')}m'),
                Slider(
                  value: _durationMinutes.toDouble(),
                  min: 30,
                  max: 240,
                  divisions: 7,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.grey300,
                  label: '${_durationMinutes}min',
                  onChanged: (v) =>
                      setState(() => _durationMinutes = v.round()),
                ),
                const SizedBox(height: 16),

                // ── Location ─────────────────────────────────
                const _SectionLabel(label: 'Location *'),
                const SizedBox(height: 8),
                BbTextField(
                  label: 'Address *',
                  hint: 'Start typing an address...',
                  controller: _addressCtrl,
                  prefixIcon: Icons.location_on_rounded,
                  onChanged: _onAddressChanged,
                  validator: (v) => _selectedLocation == null
                      ? 'Select a valid address from suggestions'
                      : null,
                ),
                if (_locationError != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _locationError!,
                    style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
                  ),
                ],
                if (_isFetchingSuggestions || _isResolvingPlace) ...[
                  const SizedBox(height: 8),
                  const LinearProgressIndicator(minHeight: 2),
                ],
                if (_suggestions.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.grey200),
                    ),
                    child: Column(
                      children: _suggestions.take(5).map((suggestion) {
                        return ListTile(
                          dense: true,
                          leading: const Icon(Icons.place_outlined, size: 18, color: AppColors.primary),
                          title: Text(
                            suggestion.primaryText ?? suggestion.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: (suggestion.secondaryText ?? '').isEmpty
                              ? null
                              : Text(
                                  suggestion.secondaryText!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                          onTap: () => _selectSuggestion(suggestion),
                        );
                      }).toList(),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                BbTextField(
                  label: 'Neighbourhood',
                  hint: 'e.g. Shoreditch',
                  controller: _neighborhoodCtrl,
                  prefixIcon: Icons.map_rounded,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                BbTextField(
                  label: 'Venue name',
                  hint: 'e.g. Hackney Marshes',
                  controller: _venueCtrl,
                  prefixIcon: Icons.stadium_rounded,
                  readOnly: true,
                ),
                const SizedBox(height: 12),
                BbTextField(
                  label: 'City *',
                  hint: 'e.g. London',
                  controller: _cityCtrl,
                  prefixIcon: Icons.location_city_rounded,
                  readOnly: true,
                ),
                const SizedBox(height: 20),

                // ── Max players ──────────────────────────────
                _SectionLabel(
                    label: 'Max players: $_maxPlayers'),
                Slider(
                  value: _maxPlayers.toDouble(),
                  min: 2,
                  max: 50,
                  divisions: 48,
                  activeColor: AppColors.primary,
                  inactiveColor: AppColors.grey300,
                  label: '$_maxPlayers',
                  onChanged: (v) =>
                      setState(() => _maxPlayers = v.round()),
                ),
                const SizedBox(height: 20),

                // ── Skill level ──────────────────────────────
                const _SectionLabel(label: 'Required skill level'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _skillLevels.map((l) {
                    final selected = _skillLevel == l;
                    final label = l == 'any'
                        ? 'Any level'
                        : l[0].toUpperCase() + l.substring(1);
                    return GestureDetector(
                      onTap: () => setState(() => _skillLevel = l),
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
                            color: selected
                                ? AppColors.primary
                                : AppColors.grey300,
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
                  }).toList(),
                ),
                const SizedBox(height: 32),

                BbButton(
                  label: 'Create Game 🎮',
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
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) =>
      Text(label, style: AppTextStyles.titleSmall);
}

class _TappableField extends StatelessWidget {
  const _TappableField({
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
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.grey100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.grey300),
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(label, style: AppTextStyles.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}
