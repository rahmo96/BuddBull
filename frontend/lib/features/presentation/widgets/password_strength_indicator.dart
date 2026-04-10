import 'package:flutter/material.dart';
import 'package:buddbull/core/constants/app_colors.dart';
import 'package:buddbull/core/constants/app_text_styles.dart';

/// Displays a 4-segment strength bar and a label beneath the password field.
class PasswordStrengthIndicator extends StatelessWidget {
  const PasswordStrengthIndicator({super.key, required this.password});
  final String password;

  @override
  Widget build(BuildContext context) {
    final strength = _evaluate(password);
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

  _Strength _evaluate(String pwd) {
    int score = 0;
    if (pwd.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(pwd)) score++;
    if (RegExp(r'[0-9]').hasMatch(pwd)) score++;
    if (RegExp(r'[!@#\$%^&*(),.?":{}|<>]').hasMatch(pwd)) score++;

    return switch (score) {
      <= 1 => const _Strength(1, AppColors.error, 'Weak'),
      2 => const _Strength(2, AppColors.warning, 'Fair'),
      3 => const _Strength(3, AppColors.secondary, 'Good'),
      _ => const _Strength(4, AppColors.success, 'Strong'),
    };
  }
}

class _Strength {
  const _Strength(this.segments, this.color, this.label);
  final int segments;
  final Color color;
  final String label;
}
