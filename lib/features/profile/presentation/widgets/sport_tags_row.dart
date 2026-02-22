import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/theme/app_theme.dart';

class SportTagsRow extends StatelessWidget {
  final List<SportType> sports;

  const SportTagsRow({super.key, required this.sports});

  @override
  Widget build(BuildContext context) {
    if (sports.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: sports.map((sport) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${sport.emoji} ${sport.displayName}',
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0A8F35),
            ),
          ),
        );
      }).toList(),
    );
  }
}
