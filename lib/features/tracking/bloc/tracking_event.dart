part of 'tracking_bloc.dart';

sealed class TrackingEvent extends Equatable {
  const TrackingEvent();

  @override
  List<Object?> get props => const [];
}

/// Begins the simulation: driver drives their hardcoded approach path to the
/// pickup point.
class TrackingStarted extends TrackingEvent {
  const TrackingStarted({
    required this.driver,
    required this.pickup,
    required this.destination,
    required this.estimate,
  });

  final Driver driver;
  final Place pickup;
  final Place destination;
  final RideEstimate estimate;

  @override
  List<Object?> get props => [driver, pickup, destination, estimate];
}

/// One animation frame — emitted by the internal ticker.
class TrackingTicked extends TrackingEvent {
  const TrackingTicked();
}

/// Rider cancelled before the trip began.
class TrackingCancelled extends TrackingEvent {
  const TrackingCancelled();
}
