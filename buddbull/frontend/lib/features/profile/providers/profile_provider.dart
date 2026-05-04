import 'package:buddbull/features/auth/data/models/user_model.dart';
import 'package:buddbull/features/auth/providers/auth_provider.dart';
import 'package:buddbull/features/profile/data/user_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

// ── State ─────────────────────────────────────────────────────────────────────
class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.successMessage,
  });

  final bool isLoading;
  final bool isSaving;
  final String? error;
  final String? successMessage;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    bool clearError = false,
    String? successMessage,
    bool clearSuccess = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: clearError ? null : error ?? this.error,
      successMessage:
          clearSuccess ? null : successMessage ?? this.successMessage,
    );
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────
final profileProvider =
    StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  return ProfileNotifier(
    ref.watch(userRepositoryProvider),
    ref,
  );
});

// ── Public profile provider (other users) ────────────────────────────────────
final publicProfileProvider =
    FutureProvider.family<UserModel, String>((ref, userId) {
  return ref.watch(userRepositoryProvider).getUserProfile(userId);
});

// ── Notifier ─────────────────────────────────────────────────────────────────
class ProfileNotifier extends StateNotifier<ProfileState> {
  ProfileNotifier(this._repo, this._ref) : super(const ProfileState());

  final UserRepository _repo;
  final Ref _ref;

  // ── Refresh current user ──────────────────────────────────────
  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.getMe();
      _ref.read(authProvider.notifier).updateUser(user);
      state = state.copyWith(isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _msg(e),
      );
    }
  }

  // ── Update profile fields ─────────────────────────────────────
  Future<bool> updateProfile(Map<String, dynamic> updates) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final user = await _repo.updateMe(updates);
      _ref.read(authProvider.notifier).updateUser(user);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Profile updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
      return false;
    }
  }

  // ── Update profile picture ────────────────────────────────────
  Future<void> updateProfilePicture(XFile image) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final user = await _repo.updateProfilePicture(image);
      _ref.read(authProvider.notifier).updateUser(user);
      state = state.copyWith(
        isSaving: false,
        successMessage: 'Profile picture updated.',
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _msg(e));
    }
  }

  // ── Follow / unfollow ─────────────────────────────────────────
  Future<void> followUser(String id) async {
    try {
      await _repo.followUser(id);
    } catch (e) {
      state = state.copyWith(error: _msg(e));
    }
  }

  Future<void> unfollowUser(String id) async {
    try {
      await _repo.unfollowUser(id);
    } catch (e) {
      state = state.copyWith(error: _msg(e));
    }
  }

  // ── Clear messages ────────────────────────────────────────────
  void clearError() => state = state.copyWith(clearError: true);
  void clearSuccess() => state = state.copyWith(clearSuccess: true);

  String _msg(Object e) {
    final raw = e.toString();
    final match = RegExp(r'\): (.+)$').firstMatch(raw);
    return match?.group(1) ?? raw;
  }
}
