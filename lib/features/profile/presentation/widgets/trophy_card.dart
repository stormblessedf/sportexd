import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';

class TrophyCard extends StatelessWidget {
  final String emoji;
  final String name;
  final String description;
  final bool isEarned;
  final VoidCallback? onTap;

  const TrophyCard({
    super.key,
    required this.emoji,
    required this.name,
    required this.description,
    required this.isEarned,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isEarned ? onTap : null,
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isEarned
                ? const Color.fromRGBO(255, 193, 7, 0.04)
                : AppTheme.surfaceLight,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEarned
                  ? const Color.fromRGBO(255, 193, 7, 0.3)
                  : AppTheme.borderLight,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              isEarned
                  ? Text(emoji, style: const TextStyle(fontSize: 32))
                  : ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child:
                          Text(emoji, style: const TextStyle(fontSize: 32)),
                    ),
              const SizedBox(height: 6),
              Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexend(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lexend(
                  fontSize: 8,
                  color: AppTheme.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
