part of 'booking_bloc.dart';

sealed class BookingEvent extends Equatable {
  const BookingEvent();

  @override
  List<Object?> get props => const [];
}

/// Loads the dummy places and resolves the rider's GPS position.
class BookingStarted extends BookingEvent {
  const BookingStarted();
}

class BookingDestinationSelected extends BookingEvent {
  const BookingDestinationSelected(this.destination);

  final Place destination;

  @override
  List<Object?> get props => [destination];
}

class BookingDestinationCleared extends BookingEvent {
  const BookingDestinationCleared();
}

/// "Book Ride" — kicks off the simulated driver search.
class BookingRideRequested extends BookingEvent {
  const BookingRideRequested();
}

/// Rider backed out of the Finding Driver screen.
class BookingSearchCancelled extends BookingEvent {
  const BookingSearchCancelled();
}

/// Back to a clean Home screen after a completed trip.
class BookingReset extends BookingEvent {
  const BookingReset();
}
