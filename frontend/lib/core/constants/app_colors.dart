import 'package:flutter/material.dart';

/// All brand colours for BuddBull.
/// Use these constants everywhere — never write hex literals in widgets.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────
  static const Color slate = Color(0xFF1A2530);
  static const Color primary = slate;
  static const Color primaryLight = Color(0xFF2A3642);
  static const Color primaryDark = Color(0xFF121A22);

  static const Color mint = Color(0xFF5EEAD4);
  static const Color teal = Color(0xFF14B8A6);
  static const Color secondary = mint;
  static const Color secondaryLight = Color(0xFF99F6E4);
  static const Color secondaryDark = Color(0xFF0D9488);

  // ── Gradient ───────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5EEAD4), Color(0xFF14B8A6), Color(0xFF0D9488)],
    stops: [0.0, 0.55, 1.0],
  );

  static const LinearGradient brandGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF5EEAD4), Color(0xFF14B8A6)],
  );

  // ── Metric pastels ─────────────────────────────────────────────
  static const Color metricStreakBg = Color(0xFFFEE8E8);
  static const Color metricStreakAccent = Color(0xFFDC4C4C);
  static const Color metricRatingBg = Color(0xFFD8F5E8);
  static const Color metricRatingAccent = Color(0xFF059669);
  static const Color metricGamesBg = Color(0xFFE3EBF5);
  static const Color metricGamesAccent = Color(0xFF3B5998);

  // ── Neutral ────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF7F8FA);
  static const Color background = offWhite;
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color border = Color(0xFFE8EAED);
  static const Color chipUnselected = Color(0xFFF0F2F5);

  static const Color grey100 = Color(0xFFF5F6F8);
  static const Color grey200 = Color(0xFFE8EAED);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF243548);
  static const Color grey900 = slate;

  // ── Semantic ───────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color warning = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);

  // ── Text ───────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFF1A2530);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Sport badge colours ────────────────────────────────────────
  static const Color footballBadge = Color(0xFF10B981);
  static const Color basketballBadge = Color(0xFFF97316);
  static const Color tennisBadge = Color(0xFFEAB308);
  static const Color runningBadge = Color(0xFF3B82F6);
  static const Color defaultBadge = Color(0xFF14B8A6);

  // ── Status colours ─────────────────────────────────────────────
  static const Color statusOpen = Color(0xFF10B981);
  static const Color statusFull = Color(0xFFF59E0B);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF6B7280);
  static const Color statusCancelled = Color(0xFFEF4444);

  // ── Layout tokens ──────────────────────────────────────────────
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusXl = 24;

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: slate.withValues(alpha: 0.06),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  AppColors._();
}
