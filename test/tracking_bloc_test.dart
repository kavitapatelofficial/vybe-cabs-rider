import 'package:flutter_test/flutter_test.dart';
import 'package:full_ride_flow_task/data/models/driver.dart';
import 'package:full_ride_flow_task/data/models/place.dart';
import 'package:full_ride_flow_task/data/models/ride_estimate.dart';
import 'package:full_ride_flow_task/features/tracking/bloc/tracking_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  const pickup = Place(
    id: 'pickup',
    name: 'MG Road',
    address: 'Bengaluru',
    position: LatLng(12.9756, 77.6068),
  );

  const destination = Place(
    id: 'dst',
    name: 'Indiranagar',
    address: 'Bengaluru',
    position: LatLng(12.9719, 77.6412),
    distanceKm: 4.9,
    etaMinutes: 18,
    tripWaypoints: [LatLng(12.9756, 77.6068), LatLng(12.9719, 77.6412)],
  );

  const driver = Driver(
    id: 'drv_test',
    name: 'Ramesh Kumar',
    photoUrl: '',
    carModel: 'Dzire',
    carColor: 'White',
    carNumber: 'KA 05 MH 4721',
    rating: 4.8,
    totalTrips: 100,
    phone: '',
    approachWaypoints: [LatLng(12.9832, 77.6141), LatLng(12.9756, 77.6068)],
  );

  const estimate = RideEstimate(
    fare: 213,
    etaMinutes: 18,
    distanceKm: 4.9,
    surgeMultiplier: 1,
  );

  const startEvent = TrackingStarted(
    driver: driver,
    pickup: pickup,
    destination: destination,
    estimate: estimate,
  );

  group('TrackingBloc', () {
    test('starts the driver on the first point of the approach path', () async {
      final bloc = TrackingBloc();
      addTearDown(bloc.close);

      bloc.add(startEvent);
      final state = await bloc.stream.first;

      expect(state.phase, TrackingPhase.driverEnRoute);
      expect(state.carPosition, driver.approachWaypoints.first);
      expect(state.etaSeconds, TrackingBloc.approachEtaSeconds);
      expect(state.progress, 0);
      expect(state.routeAhead, isNotEmpty);
      expect(state.routeBehind, isEmpty);
      expect(state.isMoving, isTrue);
    });

    test('advances the car along the path as the ticker fires', () async {
      final bloc = TrackingBloc();
      addTearDown(bloc.close);

      bloc.add(startEvent);
      // Wait for a handful of animation frames.
      await Future<void>.delayed(TrackingBloc.frameInterval * 6);

      expect(bloc.state.progress, greaterThan(0));
      expect(bloc.state.routeBehind, isNotEmpty);
      expect(
        bloc.state.etaSeconds,
        lessThan(TrackingBloc.approachEtaSeconds),
      );
      expect(bloc.state.carPosition, isNot(driver.approachWaypoints.first));
    });

    test('stops the simulation when the ride is cancelled', () async {
      final bloc = TrackingBloc();
      addTearDown(bloc.close);

      bloc.add(startEvent);
      await bloc.stream.first;

      bloc.add(const TrackingCancelled());
      await bloc.stream.firstWhere(
        (state) => state.phase == TrackingPhase.cancelled,
      );

      final frozen = bloc.state.carPosition;
      await Future<void>.delayed(TrackingBloc.frameInterval * 5);

      expect(bloc.state.phase, TrackingPhase.cancelled);
      expect(bloc.state.isMoving, isFalse);
      expect(bloc.state.carPosition, frozen);
    });
  });
}
