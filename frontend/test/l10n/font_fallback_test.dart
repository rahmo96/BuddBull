import 'dart:io';

import 'package:buddbull/core/constants/app_text_styles.dart';
import 'package:buddbull/core/theme/app_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  test('no hardcoded Inter style lacks a Heebo fallback', () {
    final literal = RegExp(r'''fontFamily:\s*['"]Inter['"]''');
    final offenders = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        if (!literal.hasMatch(lines[i])) continue;
        final next = lines.skip(i + 1).take(2).join('\n');
        if (!next.contains('fontFamilyFallback')) {
          offenders.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(offenders, isEmpty, reason: offenders.join('\n'));
  });

  test('AppTheme.light text theme falls back to Heebo', () {
    expect(
      AppTheme.light.textTheme.bodyMedium!.fontFamilyFallback,
      contains('Heebo'),
    );
  });
}
