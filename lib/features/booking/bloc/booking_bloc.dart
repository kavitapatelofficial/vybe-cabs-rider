import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../data/models/driver.dart';
import '../../../data/models/place.dart';
import '../../../data/models/ride_estimate.dart';
import '../../../data/repositories/location_repository.dart';
import '../../../data/repositories/ride_repository.dart';

part 'booking_event.dart';
part 'booking_state.dart';

/// Drives the Home screen and the Finding Driver screen: which places exist,
/// what the rider picked, the dummy quote, and the simulated dispatch.
class BookingBloc extends Bloc<BookingEvent, BookingState> {
  BookingBloc({
    required RideRepository rideRepository,
    required LocationRepository locationRepository,
    FareCalculator fareCalculator = const FareCalculator(),
  }) : _rideRepository = rideRepository,
       _locationRepository = locationRepository,
       _fareCalculator = fareCalculator,
       super(const BookingState()) {
    on<BookingStarted>(_onStarted);
    on<BookingDestinationSelected>(_onDestinationSelected);
    on<BookingDestinationCleared>(_onDestinationCleared);
    on<BookingRideRequested>(_onRideRequested);
    on<BookingSearchCancelled>(_onSearchCancelled);
    on<BookingReset>(_onReset);
  }

  final RideRepository _rideRepository;
  final LocationRepository _locationRepository;
  final FareCalculator _fareCalculator;

  Future<void> _onStarted(
    BookingStarted event,
    Emitter<BookingState> emit,
  ) async {
    emit(state.copyWith(status: BookingStatus.loading, clearError: true));
    try {
      final pickup = await _rideRepository.loadPickup();
      final destinations = await _rideRepository.loadDestinations();

      // Ask for GPS, but never block the booking flow on it.
      final location = await _locationRepository.currentPosition(
        fallback: pickup.position,
      );

      emit(
        state.copyWith(
          status: BookingStatus.ready,
          pickup: pickup,
          riderPosition: location.position,
          isLiveLocation: location.isLive,
          destinations: destinations,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BookingStatus.failure,
          errorMessage: 'Could not load locations. Pull down to retry.',
        ),
      );
    }
  }

  void _onDestinationSelected(
    BookingDestinationSelected event,
    Emitter<BookingState> emit,
  ) {
    emit(
      state.copyWith(
        status: BookingStatus.ready,
        selectedDestination: event.destination,
        estimate: _fareCalculator.quote(event.destination),
        clearDriver: true,
        clearError: true,
      ),
    );
  }

  void _onDestinationCleared(
    BookingDestinationCleared event,
    Emitter<BookingState> emit,
  ) {
    emit(
      state.copyWith(
        status: BookingStatus.ready,
        clearDestination: true,
        clearDriver: true,
      ),
    );
  }

  Future<void> _onRideRequested(
    BookingRideRequested event,
    Emitter<BookingState> emit,
  ) async {
    if (!state.hasDestination) return;

    emit(
      state.copyWith(
        status: BookingStatus.searchingDriver,
        clearDriver: true,
        clearError: true,
      ),
    );
    try {
      final driver = await _rideRepository.findDriver();
      // The rider may have cancelled while dispatch was running.
      if (state.status != BookingStatus.searchingDriver) return;
      emit(
        state.copyWith(status: BookingStatus.driverAssigned, driver: driver),
      );
    } catch (_) {
      emit(
        state.copyWith(
          status: BookingStatus.ready,
          errorMessage: 'No drivers available right now. Please try again.',
        ),
      );
    }
  }

  void _onSearchCancelled(
    BookingSearchCancelled event,
    Emitter<BookingState> emit,
  ) {
    emit(state.copyWith(status: BookingStatus.ready, clearDriver: true));
  }

  void _onReset(BookingReset event, Emitter<BookingState> emit) {
    emit(
      state.copyWith(
        status: BookingStatus.ready,
        clearDestination: true,
        clearDriver: true,
        clearError: true,
      ),
    );
  }
}
