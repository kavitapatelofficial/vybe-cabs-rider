import 'package:flutter_test/flutter_test.dart';
import 'package:full_ride_flow_task/core/utils/route_animator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  const start = LatLng(12.9756, 77.6068);
  const middle = LatLng(12.9800, 77.6068);
  const end = LatLng(12.9800, 77.6200);

  group('RouteAnimator.resample', () {
    test('returns exactly the requested number of frames', () {
      final frames = RouteAnimator.resample([start, middle, end], 60);
      expect(frames.length, 60);
    });

    test('keeps the original endpoints', () {
      final frames = RouteAnimator.resample([start, middle, end], 40);
      expect(frames.first.latitude, closeTo(start.latitude, 1e-9));
      expect(frames.last.longitude, closeTo(end.longitude, 1e-9));
    });

    test('spaces frames evenly along a straight leg', () {
      // A single segment, so consecutive frames cannot cut a corner — the
      // straight-line gap and the along-path gap are the same thing here.
      final frames = RouteAnimator.resample([start, end], 30);
      final gaps = [
        for (var i = 0; i < frames.length - 1; i++)
          RouteAnimator.distanceBetween(frames[i], frames[i + 1]),
      ];
      final average = gaps.reduce((a, b) => a + b) / gaps.length;

      for (final gap in gaps) {
        expect(gap, closeTo(average, average * 0.05));
      }
    });

    test('keeps every frame on the route when it bends', () {
      final frames = RouteAnimator.resample([start, middle, end], 30);
      final travelled = RouteAnimator.pathLength(frames);
      final routeLength = RouteAnimator.pathLength([start, middle, end]);

      // Frames cut the corner slightly, so the sampled path is never longer
      // than the route it was taken from.
      expect(travelled, lessThanOrEqualTo(routeLength));
      expect(travelled, greaterThan(routeLength * 0.95));
    });

    test('passes short paths through untouched', () {
      expect(RouteAnimator.resample([start], 20), [start]);
    });
  });

  group('RouteAnimator.bearing', () {
    test('reports roughly north when heading north', () {
      expect(RouteAnimator.bearing(start, middle), closeTo(0, 1));
    });

    test('reports roughly east when heading east', () {
      expect(RouteAnimator.bearing(middle, end), closeTo(90, 1));
    });
  });

  group('RouteAnimator.boundsOf', () {
    test('covers every point', () {
      final bounds = RouteAnimator.boundsOf([start, middle, end]);
      expect(bounds.contains(start), isTrue);
      expect(bounds.contains(middle), isTrue);
      expect(bounds.contains(end), isTrue);
    });
  });

  group('RouteAnimator.densify', () {
    test('adds intermediate points without moving the endpoints', () {
      final dense = RouteAnimator.densify([start, end], stepMeters: 50);
      expect(dense.length, greaterThan(2));
      expect(dense.first, start);
      expect(dense.last.latitude, closeTo(end.latitude, 1e-9));
    });
  });
}
