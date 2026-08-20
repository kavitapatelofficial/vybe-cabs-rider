import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Result of asking the device where it is.
class LocationResult {
  const LocationResult({required this.position, required this.isLive});

  final LatLng position;

  /// False when we fell back to the dummy pickup because GPS was unavailable
  /// or the permission was declined — the UI surfaces this to the rider.
  final bool isLive;
}

/// Wraps geolocator so the booking bloc never deals with permission enums.
class LocationRepository {
  const LocationRepository();

  /// Asks for permission and returns the device position, falling back to
  /// [fallback] if location services are off or permission is denied. The
  /// booking flow must keep working on an emulator with no GPS fix.
  Future<LocationResult> currentPosition({required LatLng fallback}) async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        return LocationResult(position: fallback, isLive: false);
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return LocationResult(position: fallback, isLive: false);
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      return LocationResult(
        position: LatLng(position.latitude, position.longitude),
        isLive: true,
      );
    } catch (_) {
      // Timeouts, emulators without a fix, platform errors — all non-fatal.
      return LocationResult(position: fallback, isLive: false);
    }
  }
}
