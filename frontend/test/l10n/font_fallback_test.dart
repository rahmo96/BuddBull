import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every AppTextStyles style falls back to Heebo for Hebrew glyphs', () {
    final styles = {
      'displayLarge': AppTextStyles.displayLarge,
      'displayMedium': AppTextStyles.displayMedium,
      'headlineLarge': AppTextStyles.headlineLarge,
      'headlineMedium': AppTextStyles.headlineMedium,
      'headlineSmall': AppTextStyles.headlineSmall,
      'titleLarge': AppTextStyles.titleLarge,
      'titleMedium': AppTextStyles.titleMedium,
      'titleSmall': AppTextStyles.titleSmall,
      'bodyLarge': AppTextStyles.bodyLarge,
      'bodyMedium': AppTextStyles.bodyMedium,
      'bodySmall': AppTextStyles.bodySmall,
      'labelLarge': AppTextStyles.labelLarge,
      'labelMedium': AppTextStyles.labelMedium,
      'labelSmall': AppTextStyles.labelSmall,
      'button': AppTextStyles.button,
      'caption': AppTextStyles.caption,
      'overline': AppTextStyles.overline,
    };
    styles.forEach((name, s) {
      expect(s.fontFamilyFallback, contains('Heebo'), reason: name);
    });
  });
}
