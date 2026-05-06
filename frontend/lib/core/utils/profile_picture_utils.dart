import 'package:buddbull/core/network/api_endpoints.dart';

/// BuddBull stores `profilePicture` as an https URL, a relative upload path
/// (`profiles/...`), or a preset token `avatar:<id>` from onboarding.
abstract class ProfilePictureUtils {
  static const String avatarPrefix = 'avatar:';

  static bool isPresetToken(String? stored) =>
      stored != null && stored.startsWith(avatarPrefix);

  static String? presetAvatarId(String stored) {
    if (!isPresetToken(stored)) return null;
    return stored.substring(avatarPrefix.length);
  }

  /// Resolves a value suitable for [CachedNetworkImage]; returns null for
  /// presets and empty input.
  static String? networkImageUrl(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (isPresetToken(stored)) return null;
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      return stored;
    }
    final origin =
        ApiEndpoints.baseUrl.replaceAll(RegExp(r'/api/v1/?$'), '').trimRight();
    if (origin.endsWith('/')) {
      final o = origin.substring(0, origin.length - 1);
      final path = stored.startsWith('/') ? stored.substring(1) : stored;
      return '$o/uploads/$path';
    }
    final path = stored.startsWith('/') ? stored.substring(1) : stored;
    return '$origin/uploads/$path';
  }
}
