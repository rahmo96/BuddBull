import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/l10n/l10n.dart';
import 'package:flutter/material.dart';

/// Displays a 4-segment strength bar and a label beneath the password field.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = _evaluate(password, context.l10n);
    if (password.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            spacing: 4,
            children: List.generate(
              4,
              (i) => Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 4,
                  decoration: BoxDecoration(
                    color: i < strength.segments
                        ? strength.color
                        : AppColors.grey300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            strength.label,
            style: AppTextStyles.labelSmall.copyWith(color: strength.color),
          ),
        ],
      ),
    );
  }

  _Strength _evaluate(String pwd, AppLocalizations l10n) {
    int score = 0;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd)) score++;

    return switch (score) {
      <= 1 => _Strength(1, AppColors.error, l10n.authPasswordWeak),
      2 => _Strength(2, AppColors.warning, l10n.authPasswordFair),
      3 => _Strength(3, AppColors.secondary, l10n.authPasswordGood),
      _ => _Strength(4, AppColors.success, l10n.authPasswordStrong),
    };
  }
}

class _Strength {
  const _Strength(this.segments, this.color, this.label);
  final int segments;
  final Color color;
  final String label;
}
