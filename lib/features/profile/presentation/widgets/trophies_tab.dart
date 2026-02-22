import 'package:flutter/material.dart' hide Badge;
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/models/trophy_definition.dart';
import 'package:sporsal/features/profile/presentation/widgets/trophy_card.dart';
import 'package:sporsal/theme/app_theme.dart';

class TrophiesTab extends StatelessWidget {
  final List<Badge> earnedBadges;
  final List<TrophyDefinition> allTrophies;
  final Function(TrophyDefinition) onTrophyTap;

  const TrophiesTab({
    super.key,
    required this.earnedBadges,
    required this.allTrophies,
    required this.onTrophyTap,
  });

  @override
  Widget build(BuildContext context) {
    final earnedIds = earnedBadges.map((b) => b.id).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kazanılan Rozetler',
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.85,
          ),
          itemCount: allTrophies.length,
          itemBuilder: (context, index) {
            final trophy = allTrophies[index];
            final isEarned = earnedIds.contains(trophy.id);
            return TrophyCard(
              emoji: trophy.emoji,
              name: trophy.name,
              description: trophy.description,
              isEarned: isEarned,
              onTap: isEarned ? () => onTrophyTap(trophy) : null,
            );
          },
        ),
      ],
    );
  }
}
