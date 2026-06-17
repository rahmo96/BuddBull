import 'package:flutter/material.dart';

/// Simple mock sport chip for onboarding (no persistence yet).
class OnboardingSportOption {
  const OnboardingSportOption({
    required this.id,
    required this.label,
    required this.emoji,
    required this.accent,
  });

  final String id;
  final String label;
  final String emoji;
  final Color accent;
}

/// Preset avatars bundled under [assets/avatars/].
class OnboardingAvatarOption {
  const OnboardingAvatarOption({
    required this.id,
    required this.assetPath,
  });

  final String id;
  final String assetPath;
}

abstract class OnboardingMockData {
  /// API values for PATCH `sportsInterests[].skillLevel` (matches backend).
  static const List<String> skillLevelsOrdered = [
    'beginner',
    'amateur',
    'intermediate',
    'advanced',
    'professional',
  ];

  static OnboardingSportOption? sportById(String id) {
    for (final s in sports) {
      if (s.id == id) return s;
    }
    return null;
  }

  static OnboardingAvatarOption? avatarById(String id) {
    for (final a in avatars) {
      if (a.id == id) return a;
    }
    return null;
  }

  static const List<OnboardingSportOption> sports = [
    OnboardingSportOption(
      id: 'football',
      label: 'Football',
      emoji: '⚽',
      accent: Color(0xFF10B981),
    ),
    OnboardingSportOption(
      id: 'basketball',
      label: 'Basketball',
      emoji: '🏀',
      accent: Color(0xFF1E3A5F),
    ),
    OnboardingSportOption(
      id: 'tennis',
      label: 'Tennis',
      emoji: '🎾',
      accent: Color(0xFFF59E0B),
    ),
    OnboardingSportOption(
      id: 'volleyball',
      label: 'Volleyball',
      emoji: '🏐',
      accent: Color(0xFF3B82F6),
    ),
    OnboardingSportOption(
      id: 'running',
      label: 'Running',
      emoji: '🏃',
      accent: Color(0xFF8B5CF6),
    ),
    OnboardingSportOption(
      id: 'swimming',
      label: 'Swimming',
      emoji: '🏊',
      accent: Color(0xFF06B6D4),
    ),
    OnboardingSportOption(
      id: 'cycling',
      label: 'Cycling',
      emoji: '🚴',
      accent: Color(0xFFEC4899),
    ),
    OnboardingSportOption(
      id: 'cricket',
      label: 'Cricket',
      emoji: '🏏',
      accent: Color(0xFF84CC16),
    ),
  ];

  static final List<OnboardingAvatarOption> avatars = List.generate(
    35,
    (i) => OnboardingAvatarOption(
      id: 'memo_${i + 1}',
      assetPath: 'assets/avatars/memo_${i + 1}.png',
    ),
  );
}
