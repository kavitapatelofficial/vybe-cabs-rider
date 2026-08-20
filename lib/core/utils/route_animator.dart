import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Turns a coarse, hardcoded list of lat-lng waypoints into a dense list of
/// points so the car marker glides instead of teleporting between corners.
///
/// The dummy routes in `assets/data/*.json` only store the shape of the road;
/// this class fills in the in-between frames.
class RouteAnimator {
  const RouteAnimator._();

  /// Interpolates [waypoints] so that consecutive points are at most roughly
  /// [stepMeters] apart. Returns the original list if it is too short to
  /// interpolate.
  static List<LatLng> densify(
    List<LatLng> waypoints, {
    double stepMeters = 40,
  }) {
    if (waypoints.length < 2) return List.of(waypoints);

    final dense = <LatLng>[waypoints.first];
    for (var i = 0; i < waypoints.length - 1; i++) {
      final start = waypoints[i];
      final end = waypoints[i + 1];
      final segmentMeters = distanceBetween(start, end);
      final steps = math.max(1, (segmentMeters / stepMeters).ceil());

      for (var step = 1; step <= steps; step++) {
        final t = step / steps;
        dense.add(
          LatLng(
            start.latitude + (end.latitude - start.latitude) * t,
            start.longitude + (end.longitude - start.longitude) * t,
          ),
        );
      }
    }
    return dense;
  }

  /// Resamples [waypoints] into exactly [frames] points spaced evenly by
  /// distance along the route.
  ///
  /// Driving the animation off a fixed frame count (rather than a fixed step
  /// size) keeps every leg the same wall-clock length regardless of how long
  /// the route is, and keeps the car moving at a constant speed instead of
  /// speeding up wherever the hardcoded waypoints happen to sit closer.
  static List<LatLng> resample(List<LatLng> waypoints, int frames) {
    if (waypoints.length < 2 || frames < 2) return List.of(waypoints);

    // Cumulative distance at each original waypoint.
    final cumulative = <double>[0];
    for (var i = 0; i < waypoints.length - 1; i++) {
      cumulative.add(
        cumulative.last + distanceBetween(waypoints[i], waypoints[i + 1]),
      );
    }
    final total = cumulative.last;
    if (total == 0) return List.filled(frames, waypoints.first);

    final sampled = <LatLng>[];
    var segment = 0;
    for (var frame = 0; frame < frames; frame++) {
      final target = total * (frame / (frames - 1));
      while (segment < cumulative.length - 2 &&
          cumulative[segment + 1] < target) {
        segment++;
      }
      final segmentStart = cumulative[segment];
      final segmentLength = cumulative[segment + 1] - segmentStart;
      final t = segmentLength == 0 ? 0.0 : (target - segmentStart) / segmentLength;
      final a = waypoints[segment];
      final b = waypoints[segment + 1];
      sampled.add(
        LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        ),
      );
    }
    return sampled;
  }

  /// Great-circle distance in metres (haversine).
  static double distanceBetween(LatLng a, LatLng b) {
    const earthRadius = 6371000.0;
    final dLat = _toRadians(b.latitude - a.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);

    final h =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.sin(dLng / 2) * math.sin(dLng / 2) * math.cos(lat1) * math.cos(lat2);
    return 2 * earthRadius * math.asin(math.min(1, math.sqrt(h)));
  }

  /// Total length of a path in metres.
  static double pathLength(List<LatLng> path) {
    var total = 0.0;
    for (var i = 0; i < path.length - 1; i++) {
      total += distanceBetween(path[i], path[i + 1]);
    }
    return total;
  }

  /// Compass bearing from [a] to [b] in degrees, used to rotate the car marker
  /// so it always points the way it is driving.
  static double bearing(LatLng a, LatLng b) {
    final lat1 = _toRadians(a.latitude);
    final lat2 = _toRadians(b.latitude);
    final dLng = _toRadians(b.longitude - a.longitude);

    final y = math.sin(dLng) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);
    final degrees = math.atan2(y, x) * 180 / math.pi;
    return (degrees + 360) % 360;
  }

  /// Camera bounds that comfortably fit every point in [points].
  static LatLngBounds boundsOf(List<LatLng> points) {
    assert(points.isNotEmpty, 'boundsOf requires at least one point');
    var minLat = points.first.latitude;
    var maxLat = points.first.latitude;
    var minLng = points.first.longitude;
    var maxLng = points.first.longitude;

    for (final p in points) {
      minLat = math.min(minLat, p.latitude);
      maxLat = math.max(maxLat, p.latitude);
      minLng = math.min(minLng, p.longitude);
      maxLng = math.max(maxLng, p.longitude);
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
  }

  static double _toRadians(double degrees) => degrees * math.pi / 180;
}
