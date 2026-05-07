import 'package:buddbull/core/network/api_endpoints.dart';

/// BuddBull stores `profilePicture` as an https URL, a relative upload path
/// (`profiles/...`), or a preset token `avatar:<id>` from onboarding.
abstract class ProfilePictureUtils {
  static const String avatarPrefix = 'avatar:';
  static const String diceBearPrefix = 'dicebear:';

  static bool isPresetToken(String? stored) =>
      stored != null && stored.startsWith(avatarPrefix);

  static bool isDiceBearToken(String? stored) =>
      stored != null && stored.startsWith(diceBearPrefix);

  static String? presetAvatarId(String stored) {
    if (!isPresetToken(stored)) return null;
    return stored.substring(avatarPrefix.length);
  }

  /// Stored token format: `dicebear:<style>:<seed>`
  static String? diceBearUrl(String? stored) {
    if (!isDiceBearToken(stored)) return null;
    final raw = stored!.substring(diceBearPrefix.length);
    final splitIdx = raw.indexOf(':');
    if (splitIdx <= 0 || splitIdx >= raw.length - 1) return null;
    final style = Uri.encodeComponent(raw.substring(0, splitIdx));
    final seed = Uri.encodeComponent(raw.substring(splitIdx + 1));
    return 'https://api.dicebear.com/9.x/$style/svg?seed=$seed';
  }

  /// Resolves a value suitable for [CachedNetworkImage]; returns null for
  /// presets and empty input.
  static String? networkImageUrl(String? stored) {
    if (stored == null || stored.isEmpty) return null;
    if (isPresetToken(stored)) return null;
    if (isDiceBearToken(stored)) return diceBearUrl(stored);
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
