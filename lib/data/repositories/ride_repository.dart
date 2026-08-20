import 'dart:convert';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;

import '../models/driver.dart';
import '../models/place.dart';
import '../models/ride_history_entry.dart';

/// Serves every non-auth piece of data in the app from local JSON assets.
///
/// This is the single seam where the dummy data lives. Pointing the app at a
/// real backend means reimplementing these four methods against HTTP — no
/// caller changes, because they all return domain models already.
class RideRepository {
  RideRepository({Random? random}) : _random = random ?? Random();

  static const String _placesAsset = 'assets/data/places.json';
  static const String _driversAsset = 'assets/data/drivers.json';
  static const String _historyAsset = 'assets/data/ride_history.json';

  final Random _random;

  Map<String, dynamic>? _placesCache;
  List<Driver>? _driversCache;

  /// The rider's default pickup point, used whenever GPS is unavailable.
  Future<Place> loadPickup() async {
    final data = await _places();
    return Place.fromJson(data['pickup'] as Map<String, dynamic>);
  }

  /// The hardcoded "Where to?" suggestions.
  Future<List<Place>> loadDestinations() async {
    final data = await _places();
    return (data['destinations'] as List)
        .cast<Map<String, dynamic>>()
        .map(Place.fromJson)
        .toList(growable: false);
  }

  Future<List<Driver>> loadDrivers() async {
    if (_driversCache != null) return _driversCache!;
    final raw = await rootBundle.loadString(_driversAsset);
    _driversCache = (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(Driver.fromJson)
        .toList(growable: false);
    return _driversCache!;
  }

  /// Simulates dispatch: waits 3-5 seconds, then assigns a random driver.
  Future<Driver> findDriver() async {
    final drivers = await loadDrivers();
    final searchSeconds = 3 + _random.nextInt(3); // 3, 4 or 5 seconds
    await Future<void>.delayed(Duration(seconds: searchSeconds));
    return drivers[_random.nextInt(drivers.length)];
  }

  Future<List<RideHistoryEntry>> loadHistory() async {
    final raw = await rootBundle.loadString(_historyAsset);
    final entries = (jsonDecode(raw) as List)
        .cast<Map<String, dynamic>>()
        .map(RideHistoryEntry.fromJson)
        .toList();
    entries.sort((a, b) => b.date.compareTo(a.date)); // newest first
    return List.unmodifiable(entries);
  }

  Future<Map<String, dynamic>> _places() async {
    if (_placesCache != null) return _placesCache!;
    final raw = await rootBundle.loadString(_placesAsset);
    _placesCache = jsonDecode(raw) as Map<String, dynamic>;
    return _placesCache!;
  }
}
