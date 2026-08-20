import 'package:flutter_test/flutter_test.dart';
import 'package:full_ride_flow_task/data/models/place.dart';
import 'package:full_ride_flow_task/data/models/ride_estimate.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  const destination = Place(
    id: 'dst_test',
    name: 'Test Drop',
    address: 'Somewhere',
    position: LatLng(12.9, 77.6),
    distanceKm: 10,
    etaMinutes: 20,
  );

  group('FareCalculator', () {
    test('quotes the same fare for the same destination', () {
      const calculator = FareCalculator();
      expect(calculator.quote(destination).fare,
          calculator.quote(destination).fare);
    });

    test('keeps the surge multiplier between 1.0x and 1.3x', () {
      final lowSurge = const FareCalculator(random: _zero).quote(destination);
      final highSurge = const FareCalculator(random: _one).quote(destination);

      expect(lowSurge.surgeMultiplier, 1.0);
      expect(highSurge.surgeMultiplier, 1.3);
      expect(highSurge.fare, greaterThan(lowSurge.fare));
    });

    test('applies base + distance + time with no surge', () {
      final estimate = const FareCalculator(random: _zero).quote(destination);

      // 32 + (14.5 * 10) + (1.8 * 20) = 213
      expect(estimate.fare, 213);
      expect(estimate.isSurging, isFalse);
      expect(estimate.etaMinutes, 20);
    });

    test('breakdown lines add up to the quoted total', () {
      final estimate = const FareCalculator(random: _one).quote(destination);
      final breakdown = estimate.breakdown;
      final sum =
          breakdown.base + breakdown.distance + breakdown.time + breakdown.surge;

      expect(sum, closeTo(estimate.fare, 0.01));
      expect(breakdown.surge, greaterThan(0));
    });
  });
}

double _zero() => 0;
double _one() => 1;
