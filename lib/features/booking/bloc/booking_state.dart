part of 'booking_bloc.dart';

enum BookingStatus {
  initial,

  /// Fetching dummy places + GPS fix.
  loading,

  /// Map is up; rider may or may not have picked a destination yet.
  ready,

  /// Simulated dispatch is running (3-5s).
  searchingDriver,

  /// A driver came back from the dummy dataset — hand off to tracking.
  driverAssigned,
  failure,
}

class BookingState extends Equatable {
  const BookingState({
    this.status = BookingStatus.initial,
    this.pickup,
    this.riderPosition,
    this.isLiveLocation = false,
    this.destinations = const [],
    this.selectedDestination,
    this.estimate,
    this.driver,
    this.errorMessage,
  });

  final BookingStatus status;

  /// Pickup place from the dummy dataset (name + address shown in the UI).
  final Place? pickup;

  /// Where the map actually centres — the device GPS fix when we have one,
  /// otherwise the dummy pickup coordinates.
  final LatLng? riderPosition;
  final bool isLiveLocation;

  final List<Place> destinations;
  final Place? selectedDestination;
  final RideEstimate? estimate;
  final Driver? driver;
  final String? errorMessage;

  bool get hasDestination => selectedDestination != null;
  bool get canBook => hasDestination && status == BookingStatus.ready;

  BookingState copyWith({
    BookingStatus? status,
    Place? pickup,
    LatLng? riderPosition,
    bool? isLiveLocation,
    List<Place>? destinations,
    Place? selectedDestination,
    RideEstimate? estimate,
    Driver? driver,
    String? errorMessage,
    bool clearDestination = false,
    bool clearDriver = false,
    bool clearError = false,
  }) {
    return BookingState(
      status: status ?? this.status,
      pickup: pickup ?? this.pickup,
      riderPosition: riderPosition ?? this.riderPosition,
      isLiveLocation: isLiveLocation ?? this.isLiveLocation,
      destinations: destinations ?? this.destinations,
      selectedDestination: clearDestination
          ? null
          : (selectedDestination ?? this.selectedDestination),
      estimate: clearDestination ? null : (estimate ?? this.estimate),
      driver: clearDriver ? null : (driver ?? this.driver),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }

  @override
  List<Object?> get props => [
    status,
    pickup,
    riderPosition,
    isLiveLocation,
    destinations,
    selectedDestination,
    estimate,
    driver,
    errorMessage,
  ];
}
