import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';

class ReliabilityTrendChart extends StatelessWidget {
  final double reliabilityScore;

  const ReliabilityTrendChart({
    super.key,
    required this.reliabilityScore,
  });

  Color get _scoreColor {
    if (reliabilityScore > 80) return const Color(0xFF4CAF50);
    if (reliabilityScore >= 50) return Colors.amber;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Güvenilirlik Skoru',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 120,
                    height: 120,
                    child: CircularProgressIndicator(
                      value: reliabilityScore / 100,
                      strokeWidth: 10,
                      backgroundColor: AppTheme.borderLight,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_scoreColor),
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Text(
                    reliabilityScore.toStringAsFixed(0),
                    style: GoogleFonts.lexend(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: _scoreColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
