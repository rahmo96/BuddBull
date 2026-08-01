import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LocationAccessStatus {
  granted,
  denied,
  deniedForever,
  serviceDisabled,
}

class UserPosition {
  const UserPosition({
    required this.latitude,
    required this.longitude,
  });

  final double latitude;
  final double longitude;
}

/// Wraps [geolocator] for on-device GPS used in nearby game discovery.
///
/// [getPositionForSearch] prefers a recent cache / last-known fix so nearby
/// game fetches are not blocked on a fresh GPS lock (up to 15s).
class LocationService {
  LocationService({
    SharedPreferences? prefs,
    DateTime Function()? clock,
    Future<bool> Function()? isServiceEnabledFn,
    Future<LocationPermission> Function()? checkPermissionFn,
    Future<LocationPermission> Function()? requestPermissionFn,
    Future<Position?> Function()? getLastKnownPositionFn,
    Future<Position> Function(LocationSettings settings)? getCurrentPositionFn,
  })  : _prefs = prefs,
        _clock = clock ?? DateTime.now,
        _isServiceEnabledFn =
            isServiceEnabledFn ?? Geolocator.isLocationServiceEnabled,
        _checkPermissionFn = checkPermissionFn ?? Geolocator.checkPermission,
        _requestPermissionFn =
            requestPermissionFn ?? Geolocator.requestPermission,
        _getLastKnownPositionFn =
            getLastKnownPositionFn ?? Geolocator.getLastKnownPosition,
        _getCurrentPositionFn = getCurrentPositionFn ??
            ((settings) => Geolocator.getCurrentPosition(
                  locationSettings: settings,
                ));

  static const memoryMaxAge = Duration(minutes: 5);
  static const diskMaxAge = Duration(minutes: 60);

  static const _prefsLatKey = 'location_cache_lat';
  static const _prefsLngKey = 'location_cache_lng';
  static const _prefsAtKey = 'location_cache_at_ms';

  final SharedPreferences? _prefs;
  final DateTime Function() _clock;
  final Future<bool> Function() _isServiceEnabledFn;
  final Future<LocationPermission> Function() _checkPermissionFn;
  final Future<LocationPermission> Function() _requestPermissionFn;
  final Future<Position?> Function() _getLastKnownPositionFn;
  final Future<Position> Function(LocationSettings settings)
      _getCurrentPositionFn;

  UserPosition? _cached;
  DateTime? _cachedAt;
  bool _refreshing = false;

  Future<bool> isServiceEnabled() => _isServiceEnabledFn();

  Future<LocationAccessStatus> requestPermission() async {
    var permission = await _checkPermissionFn();
    if (permission == LocationPermission.denied) {
      permission = await _requestPermissionFn();
    }

    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationAccessStatus.granted;
      case LocationPermission.deniedForever:
        return LocationAccessStatus.deniedForever;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationAccessStatus.denied;
    }
  }

  /// Blocking fresh GPS fix. Updates the in-memory / disk cache on success.
  Future<UserPosition?> getCurrentPosition() async {
    final status = await requestPermission();
    if (status != LocationAccessStatus.granted) return null;

    if (!await isServiceEnabled()) return null;

    final position = await _getCurrentPositionFn(
      const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return _store(
      UserPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      ),
    );
  }

  /// Fast path for nearby search: memory → disk → last-known → fresh GPS.
  ///
  /// When a usable cache/last-known exists, returns immediately and refreshes
  /// the fix in the background for the next call.
  Future<UserPosition?> getPositionForSearch({
    Duration maxAge = memoryMaxAge,
  }) async {
    final status = await requestPermission();
    if (status != LocationAccessStatus.granted) return null;

    if (!await isServiceEnabled()) return null;

    final memory = _readMemory(maxAge: maxAge);
    if (memory != null) {
      _refreshInBackground();
      return memory;
    }

    final disk = _readDisk(maxAge: diskMaxAge);
    if (disk != null) {
      _cached = disk.position;
      _cachedAt = disk.cachedAt;
      _refreshInBackground();
      return disk.position;
    }

    final lastKnown = await _getLastKnownPositionFn();
    if (lastKnown != null) {
      final stored = _store(
        UserPosition(
          latitude: lastKnown.latitude,
          longitude: lastKnown.longitude,
        ),
      );
      _refreshInBackground();
      return stored;
    }

    return getCurrentPosition();
  }

  UserPosition? _readMemory({required Duration maxAge}) {
    final cached = _cached;
    final at = _cachedAt;
    if (cached == null || at == null) return null;
    if (_clock().difference(at) > maxAge) return null;
    return cached;
  }

  ({UserPosition position, DateTime cachedAt})? _readDisk({
    required Duration maxAge,
  }) {
    final prefs = _prefs;
    if (prefs == null) return null;

    final lat = prefs.getDouble(_prefsLatKey);
    final lng = prefs.getDouble(_prefsLngKey);
    final atMs = prefs.getInt(_prefsAtKey);
    if (lat == null || lng == null || atMs == null) return null;

    final cachedAt = DateTime.fromMillisecondsSinceEpoch(atMs);
    if (_clock().difference(cachedAt) > maxAge) return null;

    return (
      position: UserPosition(latitude: lat, longitude: lng),
      cachedAt: cachedAt,
    );
  }

  UserPosition _store(UserPosition position) {
    _cached = position;
    _cachedAt = _clock();
    final prefs = _prefs;
    if (prefs != null) {
      // Fire-and-forget persistence; search must not wait on disk I/O.
      prefs.setDouble(_prefsLatKey, position.latitude);
      prefs.setDouble(_prefsLngKey, position.longitude);
      prefs.setInt(_prefsAtKey, _cachedAt!.millisecondsSinceEpoch);
    }
    return position;
  }

  void _refreshInBackground() {
    if (_refreshing) return;
    _refreshing = true;
    getCurrentPosition().whenComplete(() {
      _refreshing = false;
    });
  }
}
