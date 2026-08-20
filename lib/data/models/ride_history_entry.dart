import 'package:equatable/equatable.dart';

enum RideStatus { completed, cancelled }

/// One row in the Ride History screen, loaded from
/// `assets/data/ride_history.json`.
class RideHistoryEntry extends Equatable {
  const RideHistoryEntry({
    required this.id,
    required this.date,
    required this.pickup,
    required this.drop,
    required this.fare,
    required this.distanceKm,
    required this.status,
    required this.driverName,
    required this.carNumber,
    required this.rating,
  });

  final String id;
  final DateTime date;
  final String pickup;
  final String drop;
  final double fare;
  final double distanceKm;
  final RideStatus status;
  final String driverName;
  final String carNumber;
  final int rating;

  bool get isCancelled => status == RideStatus.cancelled;

  factory RideHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RideHistoryEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['dateIso'] as String),
      pickup: json['pickup'] as String,
      drop: json['drop'] as String,
      fare: (json['fare'] as num).toDouble(),
      distanceKm: (json['distanceKm'] as num).toDouble(),
      status: json['status'] == 'cancelled'
          ? RideStatus.cancelled
          : RideStatus.completed,
      driverName: json['driverName'] as String,
      carNumber: json['carNumber'] as String,
      rating: (json['rating'] as num?)?.toInt() ?? 0,
    );
  }

  @override
  List<Object?> get props => [id];
}
