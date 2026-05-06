import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Notifies GoRouter after onboarding preference changes (complete / skip).
final onboardingRedirectListenProvider =
    Provider<OnboardingRedirectListen>((ref) {
  final listenable = OnboardingRedirectListen();
  ref.onDispose(listenable.dispose);
  return listenable;
});

final class OnboardingRedirectListen extends ChangeNotifier {
  void refresh() => notifyListeners();
}
