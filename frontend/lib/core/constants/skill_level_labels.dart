import 'package:buddbull/core/constants/app_strings.dart';

/// Maps API / DB skill values to localized display strings.
String skillLevelDisplayName(String apiValue) {
  return switch (apiValue) {
    'beginner' => AppStrings.beginner,
    'amateur' => AppStrings.amateur,
    'intermediate' => AppStrings.intermediate,
    'advanced' => AppStrings.advanced,
    'professional' => AppStrings.professional,
    _ => apiValue,
  };
}
