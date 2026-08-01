import 'package:buddbull/core/location/location_service.dart';
import 'package:buddbull/core/storage/shared_preferences_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(prefs: ref.watch(sharedPreferencesProvider)),
);

/// Resolves the viewer's GPS position for this session (stale-while-refresh).
final currentPositionProvider =
    FutureProvider.autoDispose<UserPosition?>((ref) async {
  return ref.watch(locationServiceProvider).getPositionForSearch();
});
