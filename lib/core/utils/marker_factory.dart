import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../theme/app_theme.dart';

/// Builds the map markers by painting them on a canvas at runtime.
///
/// Drawing them here (instead of shipping PNGs) keeps the marker colours tied
/// to [AppTheme] and gives us crisp icons at any device pixel ratio.
class MarkerFactory {
  const MarkerFactory._();

  static final Map<String, BitmapDescriptor> _cache = {};

  /// The moving car. Google Maps rotates the bitmap for us via
  /// [Marker.rotation], so the icon is drawn pointing north.
  static Future<BitmapDescriptor> car() => _build(
    key: 'car',
    size: 108,
    painter: (canvas, size) {
      final center = Offset(size / 2, size / 2);

      // Soft halo so the car stays visible over dark roads.
      canvas.drawCircle(
        center,
        size / 2,
        Paint()..color = AppTheme.violet.withValues(alpha: 0.18),
      );
      canvas.drawCircle(
        center,
        size * 0.34,
        Paint()..color = AppTheme.violet,
      );
      canvas.drawCircle(
        center,
        size * 0.34,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.045
          ..color = Colors.white,
      );
      _paintIcon(
        canvas,
        Icons.navigation_rounded,
        size * 0.38,
        Colors.white,
        center,
      );
    },
  );

  /// Pickup pin (violet) and drop pin (green).
  static Future<BitmapDescriptor> pickupPin() => _pin(
    key: 'pickup',
    color: AppTheme.violet,
    icon: Icons.person_pin_circle_rounded,
  );

  static Future<BitmapDescriptor> dropPin() => _pin(
    key: 'drop',
    color: AppTheme.success,
    icon: Icons.flag_rounded,
  );

  static Future<BitmapDescriptor> _pin({
    required String key,
    required Color color,
    required IconData icon,
  }) => _build(
    key: key,
    size: 96,
    painter: (canvas, size) {
      final center = Offset(size / 2, size / 2);
      canvas.drawCircle(
        center,
        size * 0.46,
        Paint()..color = color.withValues(alpha: 0.20),
      );
      canvas.drawCircle(center, size * 0.32, Paint()..color = color);
      canvas.drawCircle(
        center,
        size * 0.32,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = size * 0.05
          ..color = Colors.white,
      );
      _paintIcon(canvas, icon, size * 0.34, Colors.white, center);
    },
  );

  static Future<BitmapDescriptor> _build({
    required String key,
    required double size,
    required void Function(Canvas canvas, double size) painter,
  }) async {
    final cached = _cache[key];
    if (cached != null) return cached;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    painter(canvas, size);

    final image = await recorder.endRecording().toImage(
      size.toInt(),
      size.toInt(),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    if (bytes == null) return BitmapDescriptor.defaultMarker;

    final descriptor = BitmapDescriptor.bytes(
      bytes.buffer.asUint8List(),
      imagePixelRatio: 3,
    );
    _cache[key] = descriptor;
    return descriptor;
  }

  /// Renders a Material icon glyph onto the canvas, centred on [center].
  static void _paintIcon(
    Canvas canvas,
    IconData icon,
    double fontSize,
    Color color,
    Offset center,
  ) {
    final painter = TextPainter(textDirection: TextDirection.ltr)
      ..text = TextSpan(
        text: String.fromCharCode(icon.codePoint),
        style: TextStyle(
          fontSize: fontSize,
          fontFamily: icon.fontFamily,
          package: icon.fontPackage,
          color: color,
        ),
      )
      ..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }
}
