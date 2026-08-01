import 'package:buddbull/core/location/location_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

Position _pos(double lat, double lng) => Position(
      latitude: lat,
      longitude: lng,
      timestamp: DateTime(2026, 1, 1),
      accuracy: 1,
      altitude: 0,
      altitudeAccuracy: 0,
      heading: 0,
      headingAccuracy: 0,
      speed: 0,
      speedAccuracy: 0,
    );

void main() {
  late DateTime now;
  late int currentCalls;
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    now = DateTime(2026, 8, 2, 12);
    currentCalls = 0;
  });

  LocationService build({
    Future<Position?> Function()? lastKnown,
    Future<Position> Function(LocationSettings settings)? current,
  }) {
    return LocationService(
      prefs: prefs,
      clock: () => now,
      isServiceEnabledFn: () async => true,
      checkPermissionFn: () async => LocationPermission.whileInUse,
      requestPermissionFn: () async => LocationPermission.whileInUse,
      getLastKnownPositionFn: lastKnown ?? () async => null,
      getCurrentPositionFn: current ??
          (settings) async {
            currentCalls++;
            // Simulate a slow GPS fix that search must not await when cached.
            await Future<void>.delayed(const Duration(milliseconds: 50));
            return _pos(32.1, 34.8);
          },
    );
  }

  group('LocationService.getPositionForSearch', () {
    test('returns memory cache immediately and refreshes in background',
        () async {
      final service = build();
      await service.getCurrentPosition();
      expect(currentCalls, 1);

      final started = DateTime.now();
      final position = await service.getPositionForSearch();
      final elapsed = DateTime.now().difference(started);

      expect(position?.latitude, 32.1);
      expect(position?.longitude, 34.8);
      expect(elapsed.inMilliseconds, lessThan(40));

      // Background refresh kicked off.
      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(currentCalls, 2);
    });

    test('uses disk cache across service instances', () async {
      final first = build();
      await first.getCurrentPosition();

      currentCalls = 0;
      final second = build(
        current: (settings) async {
          currentCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _pos(99, 99);
        },
      );

      final started = DateTime.now();
      final position = await second.getPositionForSearch();
      final elapsed = DateTime.now().difference(started);

      expect(position?.latitude, 32.1);
      expect(position?.longitude, 34.8);
      expect(elapsed.inMilliseconds, lessThan(40));

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(currentCalls, 1);
    });

    test('uses last-known when memory and disk are empty', () async {
      final service = build(
        lastKnown: () async => _pos(31.5, 34.5),
        current: (settings) async {
          currentCalls++;
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return _pos(32.1, 34.8);
        },
      );

      final started = DateTime.now();
      final position = await service.getPositionForSearch();
      final elapsed = DateTime.now().difference(started);

      expect(position?.latitude, 31.5);
      expect(position?.longitude, 34.5);
      expect(elapsed.inMilliseconds, lessThan(40));

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(currentCalls, 1);
    });

    test('falls back to fresh GPS when nothing is cached', () async {
      final service = build();

      final position = await service.getPositionForSearch();

      expect(position?.latitude, 32.1);
      expect(currentCalls, 1);
    });

    test('ignores expired memory cache', () async {
      final service = build(
        lastKnown: () async => _pos(31.5, 34.5),
        current: (settings) async {
          currentCalls++;
          return _pos(32.1, 34.8);
        },
      );
      await service.getCurrentPosition();
      expect(currentCalls, 1);

      now = now.add(const Duration(minutes: 6));
      // Also expire disk so last-known is used.
      now = now.add(const Duration(minutes: 60));

      final position = await service.getPositionForSearch();
      expect(position?.latitude, 31.5);
    });
  });
}
