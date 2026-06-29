import 'package:buddbull/core/locale/l10n_extension.dart';
import 'package:flutter/widgets.dart';

/// Maps API / DB skill values to localized display strings.
String skillLevelDisplayName(BuildContext context, String apiValue) {
  final l10n = context.l10n;
  return switch (apiValue) {
    'beginner' => l10n.beginner,
    'amateur' => l10n.amateur,
    'intermediate' => l10n.intermediate,
    'advanced' => l10n.advanced,
    'professional' => l10n.professional,
    _ => apiValue,
  };
}
