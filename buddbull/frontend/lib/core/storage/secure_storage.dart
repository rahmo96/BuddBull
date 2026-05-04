import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// ── Provider ─────────────────────────────────────────────────────────────────
final secureStorageProvider = Provider<SecureStorage>(
  (_) => SecureStorage._(),
);

// ── Keys ─────────────────────────────────────────────────────────────────────
abstract class _Keys {
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

  // ── Onboarding ────────────────────────────────────────────────
  Future<void> setOnboardingDone() =>
      _storage.write(key: _Keys.onboardingDone, value: 'true');

  Future<bool> isOnboardingDone() async {
    final val = await _storage.read(key: _Keys.onboardingDone);
    return val == 'true';
  }

  Future<void> clearAll() => _storage.deleteAll();
}
