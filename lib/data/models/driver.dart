import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A driver record loaded from `assets/data/drivers.json`.
class Driver extends Equatable {
  const Driver({
    required this.id,
    required this.name,
    required this.photoUrl,
    required this.carModel,
    required this.carColor,
    required this.carNumber,
    required this.rating,
    required this.totalTrips,
    required this.phone,
    required this.approachWaypoints,
  });

  final String id;
  final String name;

  /// Empty in the dummy dataset — the UI falls back to an initials avatar.
  final String photoUrl;
  final String carModel;
  final String carColor;
  final String carNumber;
  final double rating;
  final int totalTrips;
  final String phone;

  /// Hardcoded path the driver drives to reach the pickup point.
  final List<LatLng> approachWaypoints;

  String get carLabel => '$carColor $carModel';

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first._take(2);
    return '${parts.first._take(1)}${parts.last._take(1)}';
  }

  factory Driver.fromJson(Map<String, dynamic> json) {
    return Driver(
      id: json['id'] as String,
      name: json['name'] as String,
      photoUrl: json['photoUrl'] as String? ?? '',
      carModel: json['carModel'] as String,
      carColor: json['carColor'] as String,
      carNumber: json['carNumber'] as String,
      rating: (json['rating'] as num).toDouble(),
      totalTrips: (json['totalTrips'] as num).toInt(),
      phone: json['phone'] as String? ?? '',
      approachWaypoints: (json['approachWaypoints'] as List? ?? [])
          .whereType<List>()
          .map(
            (p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()),
          )
          .toList(growable: false),
    );
  }

  @override
  List<Object?> get props => [id, name, carNumber];
}

extension on String {
  /// First [count] characters, upper-cased — used to build the avatar initials.
  String _take(int count) =>
      length <= count ? toUpperCase() : substring(0, count).toUpperCase();
}
