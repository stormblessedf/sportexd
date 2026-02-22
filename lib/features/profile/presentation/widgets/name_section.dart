import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/features/profile/presentation/widgets/sport_tags_row.dart';
import 'package:sporsal/theme/app_theme.dart';

class NameSection extends StatelessWidget {
  final UserModel user;

  const NameSection({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final hasAge = user.age != null;
    final nameText = hasAge ? '${user.username}, ${user.age}' : user.username;
    final hasBio = user.bio != null && user.bio!.isNotEmpty;
    final hasLocation = user.location != null && user.location!.isNotEmpty;
    final hasSports =
        user.interestedSports != null && user.interestedSports!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          nameText,
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        if (hasBio) ...[
          const SizedBox(height: 4),
          Text(
            user.bio!,
            style: GoogleFonts.lexend(
              fontSize: 12.5,
              color: AppTheme.textMuted,
              height: 1.5,
            ),
          ),
        ],
        if (hasLocation) ...[
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on, size: 14, color: AppTheme.primary),
              const SizedBox(width: 2),
              Text(
                user.location!,
                style: GoogleFonts.lexend(
                  fontSize: 11,
                  color: AppTheme.textLight,
                ),
              ),
            ],
          ),
        ],
        if (hasSports) ...[
          const SizedBox(height: 6),
          SportTagsRow(sports: user.interestedSports!),
        ],
      ],
    );
  }
}
