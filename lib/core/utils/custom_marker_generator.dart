import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/meetup_model.dart';

/// Generates custom sport-specific marker widgets for flutter_map
/// Modern, sportif ve minimal tasarım with zoom-based scaling
class CustomMarkerGenerator {
  /// Base marker size at zoom level 15 (reference point)
  static const double _baseSize = 48.0;

  /// Get marker size based on zoom level
  static Size getSizeForZoom({bool selected = false, double zoom = 15}) {
    // Scale factor: doubles for every 2 zoom levels
    final double scaleFactor = math.pow(2, (zoom - 15) / 2).toDouble();
    final double clampedScale = scaleFactor.clamp(0.5, 2.0);

    final double size = _baseSize * clampedScale * (selected ? 1.15 : 1.0);
    return Size(size.clamp(32, 96), size.clamp(32, 96));
  }

  /// Build marker widget for flutter_map
  static Widget buildMarkerWidget(MeetupType type, {bool selected = false, double zoom = 15}) {
    final size = getSizeForZoom(selected: selected, zoom: zoom);
    final color = getSportColor(type);
    final icon = getSportIcon(type);

    if (selected) {
      // Selected state: filled circle + white border + glow halo
      return SizedBox(
        width: size.width * 1.6,
        height: size.height * 1.6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow halo
            Container(
              width: size.width * 1.5,
              height: size.height * 1.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
              ),
            ),
            // White border ring
            Container(
              width: size.width * 1.05,
              height: size.height * 1.05,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    spreadRadius: 2,
                  ),
                ],
              ),
            ),
            // Filled sport color circle
            Container(
              width: size.width * 0.88,
              height: size.height * 0.88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Icon(
                icon,
                size: size.width * 0.45,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      );
    }

    // Normal (unselected) state: pin marker
    return SizedBox(
      width: size.width,
      height: size.height,
      child: CustomPaint(
        painter: _MarkerPainter(color: color, selected: false),
        child: Center(
          child: Padding(
            padding: EdgeInsets.only(bottom: size.height * 0.15),
            child: Icon(
              icon,
              size: size.width * 0.4,
              color: color,
            ),
          ),
        ),
      ),
    );
  }

  /// Get sport color for external use
  static Color getSportColor(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return const Color(0xFF00C853); // Vivid green
      case MeetupType.basketball:
        return const Color(0xFFFF6D00); // Vibrant orange
      case MeetupType.volleyball:
        return const Color(0xFF651FFF); // Deep purple
      case MeetupType.tennis:
        return const Color(0xFFFFAB00); // Amber
      case MeetupType.tableTennis:
        return const Color(0xFF00BFA5); // Teal accent
      case MeetupType.badminton:
        return const Color(0xFF76FF03); // Light green accent
      case MeetupType.swimming:
        return const Color(0xFF00B8D4); // Cyan accent
      case MeetupType.running:
        return const Color(0xFF2979FF); // Blue accent
      case MeetupType.cycling:
        return const Color(0xFFFF1744); // Red accent
      case MeetupType.hiking:
        return const Color(0xFF6D4C41); // Brown
      case MeetupType.yoga:
        return const Color(0xFFAA00FF); // Purple accent
      case MeetupType.fitness:
        return const Color(0xFFFF3D00); // Deep orange accent
      case MeetupType.boxing:
        return const Color(0xFFD50000); // Red
      case MeetupType.climbing:
        return const Color(0xFF455A64); // Blue grey
      case MeetupType.skiing:
        return const Color(0xFF0091EA); // Light blue accent
      case MeetupType.other:
        return const Color(0xFF64DD17); // Lime accent
    }
  }

  /// Get sport icon for external use
  static IconData getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.volleyball:
        return Icons.sports_volleyball;
      case MeetupType.tennis:
        return Icons.sports_tennis;
      case MeetupType.tableTennis:
        return Icons.sports_tennis;
      case MeetupType.badminton:
        return Icons.sports_tennis;
      case MeetupType.swimming:
        return Icons.pool;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.cycling:
        return Icons.pedal_bike;
      case MeetupType.hiking:
        return Icons.hiking;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.fitness:
        return Icons.fitness_center;
      case MeetupType.boxing:
        return Icons.sports_mma;
      case MeetupType.climbing:
        return Icons.landscape;
      case MeetupType.skiing:
        return Icons.downhill_skiing;
      case MeetupType.other:
        return Icons.sports;
    }
  }
}

/// Custom painter for marker shape
class _MarkerPainter extends CustomPainter {
  final Color color;
  final bool selected;

  _MarkerPainter({required this.color, required this.selected});

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final markerRadius = size.width * 0.38;
    final markerTop = size.height * 0.08;
    final pointerHeight = size.height * 0.22;

    // Draw pulse ring for selected state
    if (selected) {
      final outerRingPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawCircle(
        Offset(centerX, markerTop + markerRadius),
        markerRadius + 5,
        outerRingPaint,
      );

      final middleRingPaint = Paint()
        ..color = color.withValues(alpha: 0.25)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(
        Offset(centerX, markerTop + markerRadius),
        markerRadius + 2,
        middleRingPaint,
      );
    }

    // Soft drop shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: selected ? 0.25 : 0.18)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, selected ? 6 : 4);
    canvas.drawCircle(
      Offset(centerX, markerTop + markerRadius + 2),
      markerRadius + 1,
      shadowPaint,
    );

    // Main circle with gradient
    final gradientPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          _lightenColor(color, selected ? 0.2 : 0.15),
          color,
          _darkenColor(color, selected ? 0.15 : 0.1),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(centerX, markerTop + markerRadius),
        radius: markerRadius,
      ));

    canvas.drawCircle(
      Offset(centerX, markerTop + markerRadius),
      markerRadius,
      gradientPaint,
    );

    // Pointer triangle
    final pointerPath = Path()
      ..moveTo(centerX - 7, markerTop + markerRadius * 2 - 5)
      ..lineTo(centerX + 7, markerTop + markerRadius * 2 - 5)
      ..lineTo(centerX, markerTop + markerRadius * 2 + pointerHeight - 5)
      ..close();
    canvas.drawPath(pointerPath, Paint()..color = color);

    // White inner circle
    canvas.drawCircle(
      Offset(centerX, markerTop + markerRadius),
      markerRadius - 4,
      Paint()..color = Colors.white,
    );

    // Subtle highlight arc
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final highlightRect = Rect.fromCircle(
      center: Offset(centerX, markerTop + markerRadius),
      radius: markerRadius - 2,
    );
    canvas.drawArc(highlightRect, -math.pi * 0.75, math.pi * 0.5, false, highlightPaint);
  }

  Color _lightenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness + amount).clamp(0.0, 1.0)).toColor();
  }

  Color _darkenColor(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0)).toColor();
  }

  @override
  bool shouldRepaint(covariant _MarkerPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.selected != selected;
  }
}
