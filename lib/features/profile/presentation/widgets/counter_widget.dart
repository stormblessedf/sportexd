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
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.black12,
            width: 0.5,
          ),
        ),
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
      ),
    );
  }
}
