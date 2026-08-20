import 'package:flutter/services.dart' show rootBundle;

/// Loads (once) the dark Google Maps style so the map matches the app theme.
class MapStyle {
  const MapStyle._();

  static const String _asset = 'assets/map_style_dark.json';
  static String? _cached;

  static Future<String?> dark() async {
    if (_cached != null) return _cached;
    try {
      _cached = await rootBundle.loadString(_asset);
    } catch (_) {
      _cached = null; // Fall back to the default Google styling.
    }
    return _cached;
  }
}
