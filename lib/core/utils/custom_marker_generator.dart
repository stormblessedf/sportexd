import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/meetup_model.dart';

/// Generates custom sport-specific markers for Google Maps
class CustomMarkerGenerator {
  static final Map<MeetupType, BitmapDescriptor> _cachedMarkers = {};
  static bool _initialized = false;

  /// Initialize all markers (call this once when the app starts or before using markers)
  static Future<void> initialize() async {
    if (_initialized) return;

    for (final type in MeetupType.values) {
      _cachedMarkers[type] = await _createMarkerIcon(type);
    }
    _initialized = true;
  }

  /// Get the marker for a specific sport type
  static BitmapDescriptor getMarker(MeetupType type) {
    if (!_initialized || !_cachedMarkers.containsKey(type)) {
      // Return default marker if not initialized
      return BitmapDescriptor.defaultMarkerWithHue(_getDefaultHue(type));
    }
    return _cachedMarkers[type]!;
  }

  /// Check if markers are initialized
  static bool get isInitialized => _initialized;

  /// Create a custom marker icon for a sport type
  static Future<BitmapDescriptor> _createMarkerIcon(MeetupType type) async {
    final pictureRecorder = ui.PictureRecorder();
    final canvas = Canvas(pictureRecorder);
    const size = Size(80, 100);

    final paint = Paint();
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

    // Get colors and icon for this sport type
    final sportColor = _getSportColor(type);
    final iconData = _getSportIcon(type);

    // Draw shadow
    final shadowPath = Path()
      ..moveTo(size.width / 2, size.height - 5)
      ..lineTo(size.width / 2 - 8, size.height - 25)
      ..lineTo(size.width / 2 + 8, size.height - 25)
      ..close();
    canvas.drawPath(shadowPath, shadowPaint);

    // Draw pin shape (teardrop)
    final pinPath = Path();
    const pinWidth = 56.0;
    const pinHeight = 70.0;
    const pinTop = 10.0;
    final centerX = size.width / 2;

    // Create teardrop shape
    pinPath.moveTo(centerX, pinTop + pinHeight);
    pinPath.quadraticBezierTo(
      centerX - pinWidth / 2 - 5,
      pinTop + pinHeight / 2,
      centerX - pinWidth / 2,
      pinTop + pinWidth / 2,
    );
    pinPath.arcToPoint(
      Offset(centerX + pinWidth / 2, pinTop + pinWidth / 2),
      radius: Radius.circular(pinWidth / 2),
      clockwise: true,
    );
    pinPath.quadraticBezierTo(
      centerX + pinWidth / 2 + 5,
      pinTop + pinHeight / 2,
      centerX,
      pinTop + pinHeight,
    );
    pinPath.close();

    // Draw pin background
    paint.color = sportColor;
    canvas.drawPath(pinPath, paint);

    // Draw white inner circle
    paint.color = Colors.white;
    canvas.drawCircle(
      Offset(centerX, pinTop + pinWidth / 2),
      pinWidth / 2 - 6,
      paint,
    );

    // Draw icon
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    textPainter.text = TextSpan(
      text: String.fromCharCode(iconData.codePoint),
      style: TextStyle(
        fontSize: 26,
        fontFamily: iconData.fontFamily,
        package: iconData.fontPackage,
        color: sportColor,
      ),
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        centerX - textPainter.width / 2,
        pinTop + pinWidth / 2 - textPainter.height / 2,
      ),
    );

    final picture = pictureRecorder.endRecording();
    final image = await picture.toImage(size.width.toInt(), size.height.toInt());
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);

    if (byteData == null) {
      return BitmapDescriptor.defaultMarkerWithHue(_getDefaultHue(type));
    }

    return BitmapDescriptor.bytes(byteData.buffer.asUint8List());
  }

  /// Get the color for each sport type
  static Color _getSportColor(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return const Color(0xFF13EC5B); // App green
      case MeetupType.basketball:
        return const Color(0xFFFF6B35); // Orange
      case MeetupType.tennis:
        return const Color(0xFFFFD93D); // Yellow
      case MeetupType.yoga:
        return const Color(0xFF9B59B6); // Purple
      case MeetupType.running:
        return const Color(0xFF3498DB); // Blue
      case MeetupType.other:
        return const Color(0xFFE74C3C); // Red
    }
  }

  /// Get the icon for each sport type
  static IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.tennis:
        return Icons.sports_tennis;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.other:
        return Icons.sports;
    }
  }

  /// Get default hue as fallback
  static double _getDefaultHue(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return BitmapDescriptor.hueGreen;
      case MeetupType.basketball:
        return BitmapDescriptor.hueOrange;
      case MeetupType.tennis:
        return BitmapDescriptor.hueYellow;
      case MeetupType.yoga:
        return BitmapDescriptor.hueViolet;
      case MeetupType.running:
        return BitmapDescriptor.hueBlue;
      case MeetupType.other:
        return BitmapDescriptor.hueRed;
    }
  }
}
