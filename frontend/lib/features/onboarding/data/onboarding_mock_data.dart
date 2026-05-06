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

/// Placeholder “default avatars” (emoji on colored tiles — no image assets).
class OnboardingAvatarOption {
  const OnboardingAvatarOption({
    required this.id,
    required this.emoji,
    required this.background,
  });

  final String id;
  final String emoji;
  final Color background;
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
      accent: Color(0xFFFF6B35),
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

  static const List<OnboardingAvatarOption> avatars = [
    OnboardingAvatarOption(
      id: 'av_bull',
      emoji: '🐂',
      background: Color(0xFFFFEDD5),
    ),
    OnboardingAvatarOption(
      id: 'av_fire',
      emoji: '🔥',
      background: Color(0xFFFEE2E2),
    ),
    OnboardingAvatarOption(
      id: 'av_soccer',
      emoji: '⚽',
      background: Color(0xFFD1FAE5),
    ),
    OnboardingAvatarOption(
      id: 'av_basket',
      emoji: '🏀',
      background: Color(0xFFFFEDD5),
    ),
    OnboardingAvatarOption(
      id: 'av_trophy',
      emoji: '🏆',
      background: Color(0xFFFEF3C7),
    ),
    OnboardingAvatarOption(
      id: 'av_medal',
      emoji: '🏅',
      background: Color(0xFFE0E7FF),
    ),
    OnboardingAvatarOption(
      id: 'av_muscle',
      emoji: '💪',
      background: Color(0xFFEDE9FE),
    ),
    OnboardingAvatarOption(
      id: 'av_runner',
      emoji: '🏃',
      background: Color(0xFFCCFBF1),
    ),
    OnboardingAvatarOption(
      id: 'av_wave',
      emoji: '👋',
      background: Color(0xFFFCE7F3),
    ),
  ];
}
