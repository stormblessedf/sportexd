import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';

class CounterWidget extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback? onTap;

  const CounterWidget({
    super.key,
    required this.value,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.lexend(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.lexend(
              fontSize: 9,
              color: AppTheme.textMuted,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}
