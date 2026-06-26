import 'package:geolocator/geolocator.dart';

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
class LocationService {
  Future<bool> isServiceEnabled() => Geolocator.isLocationServiceEnabled();

  Future<LocationAccessStatus> requestPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
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

  Future<UserPosition?> getCurrentPosition() async {
    final status = await requestPermission();
    if (status != LocationAccessStatus.granted) return null;

    if (!await isServiceEnabled()) return null;

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 15),
      ),
    );

    return UserPosition(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }
}
