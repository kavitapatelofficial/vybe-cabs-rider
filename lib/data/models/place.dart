import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// A pickup or drop location coming from the local dummy dataset.
///
/// Swapping this app onto a real places API later only means changing the
/// factory below (and the repository that calls it) — nothing in the UI or the
/// blocs reads raw JSON.
class Place extends Equatable {
  const Place({
    required this.id,
    required this.name,
    required this.address,
    required this.position,
    this.distanceKm = 0,
    this.etaMinutes = 0,
    this.tripWaypoints = const [],
  });

  final String id;
  final String name;
  final String address;
  final LatLng position;

  /// Dummy trip metrics — only populated for drop destinations.
  final double distanceKm;
  final int etaMinutes;

  /// Hardcoded route from the pickup point to this destination, used to
  /// animate the car marker during the trip leg.
  final List<LatLng> tripWaypoints;

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'] as String,
      name: json['name'] as String,
      address: json['address'] as String,
      position: LatLng(
        (json['lat'] as num).toDouble(),
        (json['lng'] as num).toDouble(),
      ),
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 0,
      etaMinutes: (json['etaMinutes'] as num?)?.toInt() ?? 0,
      tripWaypoints: _parseWaypoints(json['tripWaypoints']),
    );
  }

  static List<LatLng> _parseWaypoints(Object? raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<List>()
        .map((p) => LatLng((p[0] as num).toDouble(), (p[1] as num).toDouble()))
        .toList(growable: false);
  }

  @override
  List<Object?> get props => [id, name, address, position];
}
