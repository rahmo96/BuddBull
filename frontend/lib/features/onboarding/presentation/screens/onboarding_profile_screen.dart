import 'dart:io' show File;

import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_strings.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/router/app_router.dart';
import 'package:buddbull/features/onboarding/data/onboarding_mock_data.dart';
import 'package:buddbull/features/onboarding/onboarding_completion.dart';
import 'package:buddbull/features/onboarding/presentation/widgets/onboarding_progress_header.dart';
import 'package:buddbull/features/onboarding/providers/onboarding_draft_provider.dart';
import 'package:buddbull/shared/widgets/bb_button.dart';
import 'package:buddbull/shared/widgets/error_view.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

/// Second onboarding step: device photo upload or preset emoji avatars.
class OnboardingProfileScreen extends ConsumerStatefulWidget {
  const OnboardingProfileScreen({super.key});

  @override
  ConsumerState<OnboardingProfileScreen> createState() =>
      _OnboardingProfileScreenState();
}

class _OnboardingProfileScreenState
    extends ConsumerState<OnboardingProfileScreen> {
  bool _busy = false;

  Future<void> _pickGallery() async {
    setState(() => _busy = true);
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 88,
      );
      ref
          .read(onboardingDraftProvider.notifier)
          .setPickedImagePath(file?.path);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _finish(BuildContext context) async {
    setState(() => _busy = true);
    try {
      await submitOnboardingToBackend(ref, savePresetAvatar: true);
      await completePostSignupOnboarding(ref);
      if (context.mounted) context.go(Routes.home);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _skipToHome(BuildContext context) async {
    setState(() => _busy = true);
    try {
      await submitOnboardingToBackend(ref, savePresetAvatar: false);
      await completePostSignupOnboarding(ref);
      if (context.mounted) context.go(Routes.home);
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, e.toString());
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(onboardingDraftProvider);
    final width = MediaQuery.sizeOf(context).width;

    final avatarPick =
        OnboardingMockData.avatarById(draft.avatarId ?? '');

    final Widget avatarChild;
    if (!kIsWeb &&
        draft.usesCustomPhoto &&
        draft.pickedImagePath != null) {
      avatarChild = ClipOval(
        child: Image.file(
          File(draft.pickedImagePath!),
          fit: BoxFit.cover,
          width: 120,
          height: 120,
        ),
      );
    } else {
      avatarChild = Text(
        avatarPick?.emoji ?? '🙂',
        style: const TextStyle(fontSize: 52),
      );
    }

    final bgForPreview = avatarPick?.background;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: width > 600 ? 560 : double.infinity),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OnboardingProgressHeader(step: 2, totalSteps: 2),
                  Text(
                    AppStrings.onboardingProfileTitle,
                    style: AppTextStyles.headlineMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    AppStrings.onboardingProfileSubtitle,
                    style: AppTextStyles.bodyLarge.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Container(
                      width: 128,
                      height: 128,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: bgForPreview ?? AppColors.grey100,
                        border: Border.all(
                          color: AppColors.grey300,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      clipBehavior: Clip.antiAlias,
                      child: avatarChild,
                    ),
                  ),
                  const SizedBox(height: 24),
                  BbButton(
                    label: AppStrings.onboardingUploadPhoto,
                    variant: BbButtonVariant.outlined,
                    icon: Icons.photo_library_rounded,
                    height: 50,
                    isLoading: _busy,
                    onPressed: _busy ? null : _pickGallery,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    AppStrings.onboardingOrPickAvatar,
                    style: AppTextStyles.titleSmall.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 1,
                    ),
                    itemCount: OnboardingMockData.avatars.length,
                    itemBuilder: (_, i) {
                      final a = OnboardingMockData.avatars[i];
                      final picked = draft.avatarId == a.id &&
                          !draft.usesCustomPhoto;
                      return _AvatarTile(
                        key: ValueKey<String>('onboarding_avatar_${a.id}'),
                        option: a,
                        selected: picked,
                        onTap: () => ref
                            .read(onboardingDraftProvider.notifier)
                            .selectAvatar(a.id),
                      );
                    },
                  ),
                  const SizedBox(height: 36),
                  Row(
                    children: [
                      Expanded(
                        child: BbButton(
                          label: AppStrings.onboardingSkip,
                          onPressed: () => _skipToHome(context),
                          variant: BbButtonVariant.outlined,
                          height: 50,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: BbButton(
                          label: AppStrings.onboardingFinish,
                          onPressed: () => _finish(context),
                          height: 50,
                          isLoading: _busy,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AvatarTile extends StatelessWidget {
  const _AvatarTile({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final OnboardingAvatarOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          decoration: BoxDecoration(
            color: option.background,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? AppColors.primary : Colors.transparent,
              width: selected ? 3 : 0,
            ),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Text(option.emoji, style: const TextStyle(fontSize: 32)),
        ),
      ),
    );
  }
}
