import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage._(),
);

// ── Keys ─────────────────────────────────────────────────────────────────────
abstract class _Keys {
  static const String accessToken = 'bb_access_token';
  static const String refreshToken = 'bb_refresh_token';
  static const String userId = 'bb_user_id';
  static const String onboardingDone = 'bb_onboarding_done';
}

// ── SecureStorage ─────────────────────────────────────────────────────────────
class SecureStorage {
  SecureStorage._();

  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Access token ─────────────────────────────────────────────
  Future<void> saveAccessToken(String token) =>
      _storage.write(key: _Keys.accessToken, value: token);

  Future<String?> getAccessToken() =>
      _storage.read(key: _Keys.accessToken);

  // ── Refresh token ─────────────────────────────────────────────
  Future<void> saveRefreshToken(String token) =>
      _storage.write(key: _Keys.refreshToken, value: token);

  Future<String?> getRefreshToken() =>
      _storage.read(key: _Keys.refreshToken);

  // ── User id ───────────────────────────────────────────────────
  Future<void> saveUserId(String id) =>
      _storage.write(key: _Keys.userId, value: id);

  Future<String?> getUserId() => _storage.read(key: _Keys.userId);

  // ── Onboarding ────────────────────────────────────────────────
  Future<void> setOnboardingDone() =>
      _storage.write(key: _Keys.onboardingDone, value: 'true');

  Future<bool> isOnboardingDone() async {
    final val = await _storage.read(key: _Keys.onboardingDone);
    return val == 'true';
  }

  // ── Clear all ─────────────────────────────────────────────────
  Future<void> clearTokens() async {
    await Future.wait([
      _storage.delete(key: _Keys.accessToken),
      _storage.delete(key: _Keys.refreshToken),
      _storage.delete(key: _Keys.userId),
    ]);
  }

  Future<void> clearAll() => _storage.deleteAll();

  // ── Check auth ────────────────────────────────────────────────
  Future<bool> hasTokens() async {
    final access = await getAccessToken();
    final refresh = await getRefreshToken();
    return access != null && refresh != null;
  }
}
