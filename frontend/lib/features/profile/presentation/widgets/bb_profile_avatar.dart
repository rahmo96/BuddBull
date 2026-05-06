import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/utils/profile_picture_utils.dart';
import 'package:buddbull/features/onboarding/data/onboarding_mock_data.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar from API [profilePicture]: network URL, upload path, preset `avatar:`,
/// or absent (initials gradient).
class BbProfileAvatar extends StatelessWidget {
  const BbProfileAvatar({
    super.key,
    required this.profilePicture,
    required this.initials,
    required this.radius,
  });

  final String? profilePicture;
  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final presetId =
        ProfilePictureUtils.presetAvatarId(profilePicture ?? '');
    if (presetId != null) {
      final preset = OnboardingMockData.avatarById(presetId);
      return CircleAvatar(
        radius: radius,
        backgroundColor: AppColors.grey200,
        child: CircleAvatar(
          radius: radius - 2,
          backgroundColor: preset?.background ?? AppColors.grey100,
          child: Text(
            preset?.emoji ?? '•',
            style: TextStyle(fontSize: radius * 0.95),
          ),
        ),
      );
    }

    final url = ProfilePictureUtils.networkImageUrl(profilePicture);
    if (url != null) {
      return CircleAvatar(
        radius: radius,
        backgroundColor: Colors.white,
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: url,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            placeholder: (_, __) => const Padding(
              padding: EdgeInsets.all(12),
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            errorWidget: (_, __, ___) =>
                _InitialsAvatar(initials: initials, radius: radius),
          ),
        ),
      );
    }

    return _InitialsAvatar(initials: initials, radius: radius);
  }
}

class _InitialsAvatar extends StatelessWidget {
  const _InitialsAvatar({required this.initials, required this.radius});

  final String initials;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.grey200,
      child: Container(
        width: radius * 2,
        height: radius * 2,
        decoration: const BoxDecoration(
          gradient: AppColors.brandGradient,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            initials.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: radius * 0.65,
              fontWeight: FontWeight.w700,
              fontFamily: 'Inter',
            ),
          ),
        ),
      ),
    );
  }
}
