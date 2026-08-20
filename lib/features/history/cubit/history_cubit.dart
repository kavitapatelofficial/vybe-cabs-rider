import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/ride_history_entry.dart';
import '../../../data/repositories/ride_repository.dart';

enum HistoryStatus { initial, loading, loaded, failure }

class HistoryState extends Equatable {
  const HistoryState({
    this.status = HistoryStatus.initial,
    this.rides = const [],
    this.errorMessage,
  });

  final HistoryStatus status;
  final List<RideHistoryEntry> rides;
  final String? errorMessage;

  /// Lifetime spend across completed rides, shown in the header chip.
  double get totalSpend => rides
      .where((ride) => !ride.isCancelled)
      .fold(0.0, (sum, ride) => sum + ride.fare);

  int get completedCount => rides.where((ride) => !ride.isCancelled).length;

  @override
  List<Object?> get props => [status, rides, errorMessage];
}

/// A Cubit rather than a full Bloc — this screen only ever loads a list, so
/// events would be ceremony. Still Bloc-family, so the whole app stays
/// consistent.
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({required RideRepository rideRepository})
    : _rideRepository = rideRepository,
      super(const HistoryState());

  final RideRepository _rideRepository;

  Future<void> load() async {
    emit(const HistoryState(status: HistoryStatus.loading));
    try {
      final rides = await _rideRepository.loadHistory();
      emit(HistoryState(status: HistoryStatus.loaded, rides: rides));
    } catch (_) {
      emit(
        const HistoryState(
          status: HistoryStatus.failure,
          errorMessage: 'Could not load your rides. Pull down to retry.',
        ),
      );
    }
  }
}
