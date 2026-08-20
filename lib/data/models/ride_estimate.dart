import 'package:equatable/equatable.dart';

import 'place.dart';

/// Dummy fare + ETA quote produced by [FareCalculator].
class RideEstimate extends Equatable {
  const RideEstimate({
    required this.fare,
    required this.etaMinutes,
    required this.distanceKm,
    required this.surgeMultiplier,
  });

  final double fare;
  final int etaMinutes;
  final double distanceKm;
  final double surgeMultiplier;

  bool get isSurging => surgeMultiplier > 1.05;

  /// Itemised receipt whose lines always sum back to [fare].
  FareBreakdown get breakdown => FareBreakdown(
    base: FareCalculator.baseFare,
    distance: FareCalculator.perKm * distanceKm,
    time: FareCalculator.perMinute * etaMinutes,
    total: fare,
  );

  @override
  List<Object?> get props => [fare, etaMinutes, distanceKm, surgeMultiplier];
}

/// Deterministic base fare with a small random surge on top, so the quote
/// looks alive without needing a pricing API.
///
/// fare = baseFare + (perKm * distance) + (perMinute * eta), all multiplied by
/// a surge factor between 1.0x and 1.3x.
class FareCalculator {
  const FareCalculator({this.random});

  static const double baseFare = 32;
  static const double perKm = 14.5;
  static const double perMinute = 1.8;

  final double Function()? random;

  RideEstimate quote(Place destination) {
    final roll = random?.call() ?? _seededRoll(destination.id);
    final surge = 1.0 + (roll * 0.3);
    final raw =
        baseFare +
        (perKm * destination.distanceKm) +
        (perMinute * destination.etaMinutes);
    return RideEstimate(
      fare: (raw * surge).roundToDouble(),
      etaMinutes: destination.etaMinutes,
      distanceKm: destination.distanceKm,
      surgeMultiplier: double.parse(surge.toStringAsFixed(2)),
    );
  }

  /// Stable per-destination roll so re-tapping the same place does not make the
  /// price jump around while the user is looking at it.
  double _seededRoll(String id) => (id.hashCode.abs() % 100) / 100;
}

/// The components behind a quoted [RideEstimate], used by the trip receipt.
class FareBreakdown {
  const FareBreakdown({
    required this.base,
    required this.distance,
    required this.time,
    required this.total,
  });

  final double base;
  final double distance;
  final double time;
  final double total;

  /// Whatever the surge multiplier added on top of the three base components.
  double get surge {
    final beforeSurge = base + distance + time;
    final difference = total - beforeSurge;
    return difference > 0 ? difference : 0;
  }
}
