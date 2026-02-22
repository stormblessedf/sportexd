import 'package:flutter/material.dart';
import '../../domain/models/models.dart';

/// Bağlantı kalitesi göstergesi
class ConnectionIndicator extends StatelessWidget {
  final ConnectionQuality quality;

  const ConnectionIndicator({
    super.key,
    required this.quality,
  });

  Color get _color {
    switch (quality) {
      case ConnectionQuality.excellent:
        return Colors.green;
      case ConnectionQuality.good:
        return Colors.lightGreen;
      case ConnectionQuality.fair:
        return Colors.orange;
      case ConnectionQuality.poor:
        return Colors.red;
    }
  }

  int get _bars {
    switch (quality) {
      case ConnectionQuality.excellent:
        return 4;
      case ConnectionQuality.good:
        return 3;
      case ConnectionQuality.fair:
        return 2;
      case ConnectionQuality.poor:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Bağlantı: ${quality.displayName}',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(4, (index) {
          final isActive = index < _bars;
          final height = 6.0 + (index * 4);
          return Padding(
            padding: const EdgeInsets.only(left: 2),
            child: Container(
              width: 4,
              height: height,
              decoration: BoxDecoration(
                color: isActive ? _color : Colors.white30,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }
}
