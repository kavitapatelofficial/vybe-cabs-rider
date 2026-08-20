part of 'tracking_bloc.dart';

/// The ride lifecycle the tracking screen walks through end to end.
enum TrackingPhase {
  idle,

  /// Car is driving along the approach path toward the pickup pin.
  driverEnRoute,

  /// Car reached the pickup — a short "Driver has arrived" beat.
  driverArrived,

  /// Car is driving the pickup -> drop path.
  onTrip,
  tripCompleted,
  cancelled,
}

class TrackingState extends Equatable {
  const TrackingState({
    this.phase = TrackingPhase.idle,
    this.driver,
    this.pickup,
    this.destination,
    this.estimate,
    this.carPosition,
    this.carBearing = 0,
    this.routeAhead = const [],
    this.routeBehind = const [],
    this.etaSeconds = 0,
    this.progress = 0,
  });

  final TrackingPhase phase;
  final Driver? driver;
  final Place? pickup;
  final Place? destination;
  final RideEstimate? estimate;

  /// Where the car marker sits this frame, and which way it points.
  final LatLng? carPosition;
  final double carBearing;

  /// The leg split at the car: [routeBehind] is covered, [routeAhead] is not.
  /// Drawing both lets the polyline dim behind the car as it drives.
  final List<LatLng> routeAhead;
  final List<LatLng> routeBehind;

  /// Countdown shown on the driver card, in seconds.
  final int etaSeconds;

  /// 0..1 through the current leg.
  final double progress;

  bool get isMoving =>
      phase == TrackingPhase.driverEnRoute || phase == TrackingPhase.onTrip;

  bool get isFinished =>
      phase == TrackingPhase.tripCompleted || phase == TrackingPhase.cancelled;

  /// Headline copy for the status banner.
  String get headline => switch (phase) {
    TrackingPhase.idle => 'Getting things ready…',
    TrackingPhase.driverEnRoute => 'Driver is on the way',
    TrackingPhase.driverArrived => 'Your driver has arrived',
    TrackingPhase.onTrip => 'On trip to destination',
    TrackingPhase.tripCompleted => 'Trip completed',
    TrackingPhase.cancelled => 'Ride cancelled',
  };

  String get subline => switch (phase) {
    TrackingPhase.driverEnRoute => 'Arriving at your pickup point',
    TrackingPhase.driverArrived => 'Please head to the pickup point',
    TrackingPhase.onTrip => destination?.name ?? '',
    TrackingPhase.tripCompleted => 'Hope you enjoyed the ride',
    _ => '',
  };

  TrackingState copyWith({
    TrackingPhase? phase,
    Driver? driver,
    Place? pickup,
    Place? destination,
    RideEstimate? estimate,
    LatLng? carPosition,
    double? carBearing,
    List<LatLng>? routeAhead,
    List<LatLng>? routeBehind,
    int? etaSeconds,
    double? progress,
  }) {
    return TrackingState(
      phase: phase ?? this.phase,
      driver: driver ?? this.driver,
      pickup: pickup ?? this.pickup,
      destination: destination ?? this.destination,
      estimate: estimate ?? this.estimate,
      carPosition: carPosition ?? this.carPosition,
      carBearing: carBearing ?? this.carBearing,
      routeAhead: routeAhead ?? this.routeAhead,
      routeBehind: routeBehind ?? this.routeBehind,
      etaSeconds: etaSeconds ?? this.etaSeconds,
      progress: progress ?? this.progress,
    );
  }

  @override
  List<Object?> get props => [
    phase,
    driver,
    pickup,
    destination,
    estimate,
    carPosition,
    carBearing,
    routeAhead.length,
    routeBehind.length,
    etaSeconds,
    progress,
  ];
}
