import 'package:buddbull/core/location/location_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final locationServiceProvider = Provider<LocationService>(
  (ref) => LocationService(),
);

/// Resolves the viewer's current GPS position for this session.
final currentPositionProvider =
    FutureProvider.autoDispose<UserPosition?>((ref) async {
  return ref.watch(locationServiceProvider).getCurrentPosition();
});
