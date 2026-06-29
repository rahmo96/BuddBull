import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/onboarding/data/onboarding_mock_data.dart';
import 'package:buddbull/features/profile/presentation/widgets/bb_profile_avatar.dart';
import 'package:buddbull/features/profile/presentation/widgets/city_autocomplete_field.dart';
import 'package:buddbull/features/profile/presentation/widgets/neighborhood_autocomplete_field.dart';
import 'package:buddbull/features/profile/presentation/widgets/sport_chip.dart';
import 'package:buddbull/features/profile/presentation/widgets/travel_radius_slider.dart';
import 'package:buddbull/features/profile/providers/profile_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/bb_text_field.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:buddbull/shared/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _bioCtrl = TextEditingController();

  /// Validated city name from Google Places (saved to `UserModel.location.city`).
  String? _selectedCity;
  /// Validated neighbourhood name from Google Places (saved to `UserModel.location.neighborhood`).
  String? _selectedNeighborhood;

  int _radiusKm = 10;
  List<SportInterest> _sports = [];
  bool _initialized = false;

  static const List<String> _availableSports = [
    'Football',
    'Basketball',
    'Tennis',
    'Running',
    'Swimming',
    'Cycling',
    'Volleyball',
    'Cricket',
  ];

  static const List<String> _skillLevels = [
    'beginner',
    'amateur',
    'intermediate',
    'advanced',
    'professional',
  ];

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  void _initFrom(UserModel user) {
    if (_initialized) return;
    _initialized = true;
    _firstNameCtrl.text = user.firstName;
    _lastNameCtrl.text = user.lastName;
    _bioCtrl.text = user.bio ?? '';
    _selectedCity = user.location?.city;
    _selectedNeighborhood = user.location?.neighborhood;
    _radiusKm = user.location?.radiusKm ?? 10;
    _sports = List.from(user.sportsInterests);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (image != null) {
      await ref.read(profileProvider.notifier).updateProfilePicture(image);
    }
  }

  Future<void> _setPresetAvatar(String avatarId) async {
    await ref.read(profileProvider.notifier).updateProfile({
      'profilePicture': 'avatar:$avatarId',
    });
  }

  Future<void> _showAvatarOptionsSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ctx.l10n.updateProfilePicture, style: AppTextStyles.titleMedium),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.photo_library_rounded),
                  title: Text(ctx.l10n.uploadFromGallery),
                  onTap: () async {
                    Navigator.pop(ctx);
                    await _pickImage();
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.emoji_emotions_outlined),
                  title: Text(ctx.l10n.choosePresetAvatar),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.45,
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: OnboardingMockData.avatars.length,
                    itemBuilder: (_, i) {
                      final option = OnboardingMockData.avatars[i];
                      return InkWell(
                        borderRadius: BorderRadius.circular(14),
                        onTap: () async {
                          Navigator.pop(ctx);
                          await _setPresetAvatar(option.id);
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.asset(
                            option.assetPath,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final updates = <String, dynamic>{
      'firstName': _firstNameCtrl.text.trim(),
      'lastName': _lastNameCtrl.text.trim(),
      if (_bioCtrl.text.trim().isNotEmpty) 'bio': _bioCtrl.text.trim(),
      'location': {
        if (_selectedCity != null && _selectedCity!.trim().isNotEmpty)
          'city': _selectedCity!.trim(),
        if (_selectedNeighborhood != null &&
            _selectedNeighborhood!.trim().isNotEmpty)
          'neighborhood': _selectedNeighborhood!.trim(),
        'radiusKm': _radiusKm,
      },
      'sportsInterests': _sports.map((s) => s.toJson()).toList(),
    };

    final ok =
        await ref.read(profileProvider.notifier).updateProfile(updates);
    if (ok && mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final profileState = ref.watch(profileProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: BbLoadingIndicator()));
    }
    _initFrom(user);

    ref.listen(profileProvider, (prev, next) {
      if (next.error != null && next.error != prev?.error) {
        showErrorSnackBar(context, next.error!);
        ref.read(profileProvider.notifier).clearError();
      }
      if (next.successMessage != null &&
          next.successMessage != prev?.successMessage) {
        showSuccessSnackBar(context, next.successMessage!);
        ref.read(profileProvider.notifier).clearSuccess();
      }
    });

    return LoadingOverlay(
      isLoading: profileState.isSaving,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: Text(context.l10n.editProfile),
          actions: [
            TextButton(
              onPressed: profileState.isSaving ? null : _save,
              child: Text(context.l10n.saveChanges),
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Avatar ──────────────────────────────────────
                Center(
                  child: Stack(
                    children: [
                      BbProfileAvatar(
                        profilePicture: user.profilePicture,
                        initials:
                            '${user.firstName[0]}${user.lastName[0]}',
                        radius: 52,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _pickImage,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: AppColors.surface, width: 2),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 18, color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _showAvatarOptionsSheet,
                    child: Text(context.l10n.changePhotoOrAvatar),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Name ─────────────────────────────────────────
                _SectionHeader(title: context.l10n.personalInfo),
                const SizedBox(height: 12),
                Row(
                  spacing: 12,
                  children: [
                    Expanded(
                      child: BbTextField(
                        label: context.l10n.firstNameLabel,
                        controller: _firstNameCtrl,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? context.l10n.fieldRequired
                            : null,
                      ),
                    ),
                    Expanded(
                      child: BbTextField(
                        label: context.l10n.lastNameLabel,
                        controller: _lastNameCtrl,
                        validator: (v) => (v?.trim().isEmpty ?? true)
                            ? context.l10n.fieldRequired
                            : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Bio ───────────────────────────────────────────
                BbTextField(
                  label: context.l10n.bioLabel,
                  hint: context.l10n.bioHint,
                  controller: _bioCtrl,
                  maxLines: 3,
                  minLines: 3,
                  maxLength: 200,
                ),
                const SizedBox(height: 28),

                // ── Location ──────────────────────────────────────
                _SectionHeader(title: context.l10n.sectionLocation),
                const SizedBox(height: 12),
                CityAutocompleteField(
                  selectedCity: _selectedCity,
                  label: context.l10n.cityLabel,
                  hint: context.l10n.onboardingLocationCityHint,
                  onCitySelected: (city) => setState(() {
                    _selectedCity = city;
                    _selectedNeighborhood = null;
                  }),
                ),
                const SizedBox(height: 16),
                NeighborhoodAutocompleteField(
                  key: ValueKey(_selectedCity ?? ''),
                  selectedCity: _selectedCity,
                  selectedNeighborhood: _selectedNeighborhood,
                  label: context.l10n.neighborhoodLabel,
                  hint: context.l10n.onboardingLocationNeighborhoodHint,
                  onNeighborhoodSelected: (neighborhood) =>
                      setState(() => _selectedNeighborhood = neighborhood),
                ),
                const SizedBox(height: 16),
                TravelRadiusSlider(
                  value: _radiusKm,
                  onChanged: (v) => setState(() => _radiusKm = v),
                ),
                const SizedBox(height: 28),

                // ── Sports ────────────────────────────────────────
                _SectionHeader(title: context.l10n.sportsInterests),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ..._sports.map(
                      (s) => SportChip(
                        interest: s,
                        onDelete: () =>
                            setState(() => _sports.remove(s)),
                      ),
                    ),
                    _AddSportButton(
                      onAdd: (sport, level) {
                        setState(() {
                          _sports.removeWhere((s) => s.sport == sport);
                          _sports.add(
                            SportInterest(sport: sport, skillLevel: level),
                          );
                        });
                      },
                      sports: _availableSports,
                      skillLevels: _skillLevels,
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // ── Save ──────────────────────────────────────────
                BbButton(
                  label: context.l10n.saveChanges,
                  onPressed: _save,
                  isLoading: profileState.isSaving,
                ),

                const SizedBox(height: 40),

                // ── Danger zone ────────────────────────────────────
                _DangerZone(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(title, style: AppTextStyles.titleMedium);
  }
}

// ── Radius slider ─────────────────────────────────────────────────────────────
// Moved to TravelRadiusSlider widget.

// ── Add sport button ──────────────────────────────────────────────────────────
class _AddSportButton extends StatelessWidget {
  const _AddSportButton({
    required this.onAdd,
    required this.sports,
    required this.skillLevels,
  });

  final void Function(String sport, String level) onAdd;
  final List<String> sports;
  final List<String> skillLevels;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showAddDialog(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.5),
              style: BorderStyle.solid),
          borderRadius: BorderRadius.circular(20),
          color: AppColors.primary.withValues(alpha: 0.05),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.add_rounded, size: 16, color: AppColors.primary),
            const SizedBox(width: 4),
            Text(
              context.l10n.addSport,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    String? selectedSport;
    String selectedLevel = 'beginner';
    final l10n = context.l10n;

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text(l10n.dialogAddSportTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                decoration: InputDecoration(labelText: l10n.sport),
                items: sports
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => selectedSport = v),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedLevel,
                decoration: InputDecoration(labelText: l10n.requiredSkillLevel),
                items: skillLevels
                    .map((s) => DropdownMenuItem(
                          value: s,
                          child: Text(_skillLevelLabel(ctx, s)),
                        ))
                    .toList(),
                onChanged: (v) =>
                    setState(() => selectedLevel = v ?? selectedLevel),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(l10n.cancel),
            ),
            FilledButton(
              onPressed: selectedSport == null
                  ? null
                  : () {
                      onAdd(selectedSport!, selectedLevel);
                      Navigator.pop(ctx);
                    },
              style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary),
              child: Text(l10n.add),
            ),
          ],
        ),
      ),
    );
  }
}

String _skillLevelLabel(BuildContext context, String level) {
  final l10n = context.l10n;
  switch (level) {
    case 'beginner':
      return l10n.beginner;
    case 'amateur':
      return l10n.amateur;
    case 'intermediate':
      return l10n.intermediate;
    case 'advanced':
      return l10n.advanced;
    case 'professional':
      return l10n.professional;
    default:
      return level;
  }
}

// ── Danger zone ───────────────────────────────────────────────────────────────
class _DangerZone extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deleteAccount,
            style: AppTextStyles.titleSmall.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.dialogDeleteAccountBody,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.error,
            ),
          ),
          const SizedBox(height: 12),
          BbButton(
            label: l10n.deleteAccount,
            onPressed: () => _confirmDelete(context, ref),
            variant: BbButtonVariant.danger,
            height: 44,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.dialogDeleteAccountTitle),
        content: Text(l10n.dialogDeleteAccountBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              // Logout — backend soft-deletes the account
              ref.read(authProvider.notifier).logout();
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.deletePermanently),
          ),
        ],
      ),
    );
  }
}
