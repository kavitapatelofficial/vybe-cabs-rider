import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:full_ride_flow_task/data/repositories/ride_repository.dart';

void main() {
  // rootBundle needs a binding before it can read the bundled JSON assets.
  TestWidgetsFlutterBinding.ensureInitialized();

  late RideRepository repository;

  setUp(() => repository = RideRepository(random: Random(7)));

  group('RideRepository', () {
    test('loads the pickup point', () async {
      final pickup = await repository.loadPickup();
      expect(pickup.name, isNotEmpty);
      expect(pickup.position.latitude, isNot(0));
    });

    test('loads the hardcoded destinations with trip routes', () async {
      final destinations = await repository.loadDestinations();

      expect(destinations.length, greaterThanOrEqualTo(4));
      for (final destination in destinations) {
        expect(destination.distanceKm, greaterThan(0));
        expect(destination.etaMinutes, greaterThan(0));
        expect(
          destination.tripWaypoints.length,
          greaterThan(1),
          reason: '${destination.name} needs a path to animate along',
        );
      }
    });

    test('loads drivers that each have an approach path', () async {
      final drivers = await repository.loadDrivers();

      expect(drivers, isNotEmpty);
      for (final driver in drivers) {
        expect(driver.carNumber, isNotEmpty);
        expect(driver.rating, inInclusiveRange(0, 5));
        expect(driver.approachWaypoints.length, greaterThan(1));
        expect(driver.initials.length, inInclusiveRange(1, 2));
      }
    });

    test('returns ride history newest first', () async {
      final rides = await repository.loadHistory();

      expect(rides.length, greaterThanOrEqualTo(5));
      for (var i = 0; i < rides.length - 1; i++) {
        expect(
          rides[i].date.isAfter(rides[i + 1].date),
          isTrue,
          reason: 'history must be sorted newest first',
        );
      }
    });

    test('findDriver takes 3-5 seconds and returns a known driver', () async {
      final drivers = await repository.loadDrivers();
      final stopwatch = Stopwatch()..start();

      final driver = await repository.findDriver();
      stopwatch.stop();

      expect(drivers.map((d) => d.id), contains(driver.id));
      expect(stopwatch.elapsed.inSeconds, inInclusiveRange(3, 5));
    }, timeout: const Timeout(Duration(seconds: 15)));
  });
}
