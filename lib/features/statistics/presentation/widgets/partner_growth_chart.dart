import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';

class PartnerGrowthChart extends StatelessWidget {
  final int partnerCount;

  const PartnerGrowthChart({
    super.key,
    required this.partnerCount,
  });

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
            'Partner Sayısı',
            style: GoogleFonts.lexend(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: partnerCount > 0
                ? Column(
                    children: [
                      const Icon(Icons.people, size: 40, color: AppTheme.primary),
                      const SizedBox(height: 8),
                      Text(
                        '$partnerCount',
                        style: GoogleFonts.lexend(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ],
                  )
                : Column(
                    children: [
                      const Icon(Icons.people_outline, size: 40, color: AppTheme.textLight),
                      const SizedBox(height: 8),
                      Text(
                        'Henüz partner yok',
                        style: GoogleFonts.lexend(
                          fontSize: 13,
                          color: AppTheme.textLight,
                        ),
                      ),
                    ],
                  ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
