import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/utils/route_animator.dart';
import '../../../data/models/driver.dart';
import '../../../data/models/place.dart';
import '../../../data/models/ride_estimate.dart';

part 'tracking_event.dart';
part 'tracking_state.dart';

/// Runs the whole simulated ride: driver approach -> arrival -> trip -> done.
///
/// A [Timer.periodic] advances one frame at a time along a pre-resampled list
/// of lat-lngs, so the marker moves at a constant speed and each leg always
/// takes the same wall-clock time no matter how long the dummy route is.
class TrackingBloc extends Bloc<TrackingEvent, TrackingState> {
  TrackingBloc() : super(const TrackingState()) {
    on<TrackingStarted>(_onStarted);
    on<TrackingTicked>(_onTicked);
    on<TrackingCancelled>(_onCancelled);
  }

  /// Wall-clock length of each leg of the simulation — tuned so the whole
  /// flow fits comfortably inside a short demo video.
  static const Duration approachDuration = Duration(seconds: 15);
  static const Duration tripDuration = Duration(seconds: 22);

  /// How long the "Driver has arrived" beat holds before the trip starts.
  static const Duration arrivedPause = Duration(seconds: 4);

  /// ~12 fps: smooth on screen without flooding the map with marker updates.
  static const Duration frameInterval = Duration(milliseconds: 80);

  /// Plausible real-world ETA for the approach leg, counted down on the card.
  static const int approachEtaSeconds = 240;

  Timer? _ticker;
  List<LatLng> _frames = const [];
  int _frameIndex = 0;
  int _legEtaSeconds = 0;

  Future<void> _onStarted(
    TrackingStarted event,
    Emitter<TrackingState> emit,
  ) async {
    _startLeg(
      waypoints: event.driver.approachWaypoints.isNotEmpty
          ? event.driver.approachWaypoints
          : [event.pickup.position, event.pickup.position],
      duration: approachDuration,
      etaSeconds: approachEtaSeconds,
    );

    emit(
      state.copyWith(
        phase: TrackingPhase.driverEnRoute,
        driver: event.driver,
        pickup: event.pickup,
        destination: event.destination,
        estimate: event.estimate,
        carPosition: _frames.first,
        carBearing: _bearingAt(0),
        routeAhead: _frames,
        routeBehind: const [],
        etaSeconds: approachEtaSeconds,
        progress: 0,
      ),
    );
  }

  Future<void> _onTicked(
    TrackingTicked event,
    Emitter<TrackingState> emit,
  ) async {
    if (!state.isMoving || _frames.isEmpty) return;

    if (_frameIndex < _frames.length - 1) {
      _frameIndex++;
      emit(_frameState());
      return;
    }

    // Reached the end of the current leg.
    _stopTicker();

    if (state.phase == TrackingPhase.driverEnRoute) {
      emit(
        state.copyWith(
          phase: TrackingPhase.driverArrived,
          carPosition: state.pickup?.position ?? _frames.last,
          etaSeconds: 0,
          progress: 1,
          routeAhead: const [],
          routeBehind: _frames,
        ),
      );

      await Future<void>.delayed(arrivedPause);
      if (isClosed || state.phase != TrackingPhase.driverArrived) return;

      // Trip leg: pickup -> drop, along the destination's hardcoded waypoints.
      final destination = state.destination;
      final pickup = state.pickup;
      if (destination == null || pickup == null) return;

      final tripWaypoints = destination.tripWaypoints.isNotEmpty
          ? destination.tripWaypoints
          : [pickup.position, destination.position];

      _startLeg(
        waypoints: tripWaypoints,
        duration: tripDuration,
        etaSeconds: (state.estimate?.etaMinutes ?? destination.etaMinutes) * 60,
      );

      emit(
        state.copyWith(
          phase: TrackingPhase.onTrip,
          carPosition: _frames.first,
          carBearing: _bearingAt(0),
          routeAhead: _frames,
          routeBehind: const [],
          etaSeconds: _legEtaSeconds,
          progress: 0,
        ),
      );
      return;
    }

    if (state.phase == TrackingPhase.onTrip) {
      emit(
        state.copyWith(
          phase: TrackingPhase.tripCompleted,
          carPosition: state.destination?.position ?? _frames.last,
          etaSeconds: 0,
          progress: 1,
          routeAhead: const [],
          routeBehind: _frames,
        ),
      );
    }
  }

  void _onCancelled(TrackingCancelled event, Emitter<TrackingState> emit) {
    _stopTicker();
    emit(state.copyWith(phase: TrackingPhase.cancelled));
  }

  /// Resamples the hardcoded waypoints into one point per frame and starts the
  /// ticker for this leg.
  void _startLeg({
    required List<LatLng> waypoints,
    required Duration duration,
    required int etaSeconds,
  }) {
    final frameCount =
        (duration.inMilliseconds / frameInterval.inMilliseconds).round();
    _frames = RouteAnimator.resample(waypoints, frameCount);
    _frameIndex = 0;
    _legEtaSeconds = etaSeconds;

    _stopTicker();
    _ticker = Timer.periodic(frameInterval, (_) {
      if (isClosed) return;
      add(const TrackingTicked());
    });
  }

  TrackingState _frameState() {
    final progress = _frames.length < 2
        ? 1.0
        : _frameIndex / (_frames.length - 1);
    return state.copyWith(
      carPosition: _frames[_frameIndex],
      carBearing: _bearingAt(_frameIndex),
      routeBehind: _frames.sublist(0, _frameIndex + 1),
      routeAhead: _frames.sublist(_frameIndex),
      progress: progress,
      etaSeconds: ((1 - progress) * _legEtaSeconds).round(),
    );
  }

  /// Bearing from the previous frame to this one, so the car icon faces the
  /// direction of travel. Holds the last bearing on the very first frame.
  double _bearingAt(int index) {
    if (_frames.length < 2) return state.carBearing;
    if (index == 0) return RouteAnimator.bearing(_frames[0], _frames[1]);
    return RouteAnimator.bearing(_frames[index - 1], _frames[index]);
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() {
    _stopTicker();
    return super.close();
  }
}
