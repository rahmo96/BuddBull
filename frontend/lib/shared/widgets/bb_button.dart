import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:flutter/material.dart';

enum BbButtonVariant { primary, secondary, outlined, ghost, danger }

/// The main BuddBull button. Handles loading state and all variants.
class BbButton extends StatelessWidget {
  const BbButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BbButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 14,
  });

  final String label;
  final VoidCallback? onPressed;
  final BbButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double? width;
  final double height;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final effectiveOnPressed = isLoading ? null : onPressed;

    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: switch (variant) {
        BbButtonVariant.primary => _PrimaryButton(
            label: label,
            onPressed: effectiveOnPressed,
            isLoading: isLoading,
            icon: icon,
            borderRadius: borderRadius,
          ),
        BbButtonVariant.secondary => _SecondaryButton(
            label: label,
            onPressed: effectiveOnPressed,
            isLoading: isLoading,
            icon: icon,
            borderRadius: borderRadius,
          ),
        BbButtonVariant.outlined => _OutlinedButton(
            label: label,
            onPressed: effectiveOnPressed,
            isLoading: isLoading,
            icon: icon,
            borderRadius: borderRadius,
          ),
        BbButtonVariant.ghost => _GhostButton(
            label: label,
            onPressed: effectiveOnPressed,
            isLoading: isLoading,
            icon: icon,
            borderRadius: borderRadius,
          ),
        BbButtonVariant.danger => _DangerButton(
            label: label,
            onPressed: effectiveOnPressed,
            isLoading: isLoading,
            icon: icon,
            borderRadius: borderRadius,
          ),
      },
    );
  }
}

// ── Gradient primary button ───────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.borderRadius,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: isDisabled
            ? null
            : AppColors.brandGradient,
        color: isDisabled ? AppColors.grey300 : null,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isDisabled
            ? null
            : [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: Colors.white24,
          highlightColor: Colors.white12,
          child: Center(child: _ButtonContent(
            label: label,
            isLoading: isLoading,
            color: isDisabled ? AppColors.grey500 : AppColors.white,
            icon: icon,
          )),
        ),
      ),
    );
  }
}

// ── Secondary (gold) button ───────────────────────────────────────────────────
class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.borderRadius,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 20) : const SizedBox.shrink(),
      label: _ButtonContent(
        label: label,
        isLoading: isLoading,
        color: AppColors.grey900,
        icon: null,
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.grey900,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ── Outlined button ───────────────────────────────────────────────────────────
class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.borderRadius,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        color: AppColors.primary,
        icon: icon,
      ),
    );
  }
}

// ── Ghost button ──────────────────────────────────────────────────────────────
class _GhostButton extends StatelessWidget {
  const _GhostButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.borderRadius,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        color: AppColors.primary,
        icon: icon,
      ),
    );
  }
}

// ── Danger button ─────────────────────────────────────────────────────────────
class _DangerButton extends StatelessWidget {
  const _DangerButton({
    required this.label,
    required this.onPressed,
    required this.isLoading,
    required this.borderRadius,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final double borderRadius;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.error,
        foregroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      child: _ButtonContent(
        label: label,
        isLoading: isLoading,
        color: AppColors.white,
        icon: icon,
      ),
    );
  }
}

// ── Button content ────────────────────────────────────────────────────────────
class _ButtonContent extends StatelessWidget {
  const _ButtonContent({
    required this.label,
    required this.isLoading,
    required this.color,
    this.icon,
  });

  final String label;
  final bool isLoading;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 22,
        width: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(label, style: AppTextStyles.button.copyWith(color: color)),
        ],
      );
    }

    return Text(label, style: AppTextStyles.button.copyWith(color: color));
  }
}
