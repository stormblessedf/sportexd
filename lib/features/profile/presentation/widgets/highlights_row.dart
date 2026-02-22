import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/theme/app_theme.dart';

enum HighlightType { badges, certificates, statistics, achievements, upcoming }

class HighlightsRow extends StatelessWidget {
  final bool isOwnProfile;
  final Function(HighlightType) onTap;

  const HighlightsRow({
    super.key,
    required this.isOwnProfile,
    required this.onTap,
  });

  static const _allHighlights = [
    (emoji: '🏆', label: 'Rozetler', type: HighlightType.badges),
    (emoji: '📜', label: 'Sertifika', type: HighlightType.certificates),
    (emoji: '📊', label: 'İstatistik', type: HighlightType.statistics),
    (emoji: '🏅', label: 'Başarılar', type: HighlightType.achievements),
    (emoji: '📅', label: 'Yaklaşan', type: HighlightType.upcoming),
  ];

  @override
  Widget build(BuildContext context) {
    final highlights = isOwnProfile
        ? _allHighlights
        : _allHighlights
            .where((h) => h.type != HighlightType.upcoming)
            .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: highlights.map((h) {
          return Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => onTap(h.type),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.primary,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primary.withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: Text(h.emoji, style: const TextStyle(fontSize: 20)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    h.label,
                    style: GoogleFonts.lexend(
                      fontSize: 9,
                      color: AppTheme.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
