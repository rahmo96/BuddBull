import 'package:flutter/material.dart';

/// All brand colours for BuddBull.
/// Use these constants everywhere — never write hex literals in widgets.
abstract class AppColors {
  // ── Brand ──────────────────────────────────────────────────────
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8C5E);
  static const Color primaryDark = Color(0xFFCC5528);

  static const Color secondary = Color(0xFFF7C948);
  static const Color secondaryLight = Color(0xFFFAD775);
  static const Color secondaryDark = Color(0xFFC9A230);

  // ── Gradient ───────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient brandGradientVertical = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [primary, Color(0xFFFF9A5E)],
  );

  // ── Neutral ────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF4F7F9);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF0F2F5);
  static const Color border = Color(0xFFE5E7EB);

  static const Color grey100 = Color(0xFFF9FAFB);
  static const Color grey200 = Color(0xFFF3F4F6);
  static const Color grey300 = Color(0xFFE5E7EB);
  static const Color grey400 = Color(0xFFD1D5DB);
  static const Color grey500 = Color(0xFF9CA3AF);
  static const Color grey600 = Color(0xFF6B7280);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey900 = Color(0xFF111827);

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
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textDisabled = Color(0xFF9CA3AF);
  static const Color textOnPrimary = Color(0xFFFFFFFF);
  static const Color textOnDark = Color(0xFFFFFFFF);

  // ── Sport badge colours ────────────────────────────────────────
  static const Color footballBadge = Color(0xFF10B981);
  static const Color basketballBadge = Color(0xFFFF6B35);
  static const Color tennisBadge = Color(0xFFF59E0B);
  static const Color runningBadge = Color(0xFF3B82F6);
  static const Color defaultBadge = Color(0xFF8B5CF6);

  // ── Status colours ─────────────────────────────────────────────
  static const Color statusOpen = Color(0xFF10B981);
  static const Color statusFull = Color(0xFFF59E0B);
  static const Color statusInProgress = Color(0xFF3B82F6);
  static const Color statusCompleted = Color(0xFF6B7280);
  static const Color statusCancelled = Color(0xFFEF4444);

  AppColors._();
}
