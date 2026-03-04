import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Emoji mapping for each MeetupType used in venue recommendation UI.
const _sportEmojis = <MeetupType, String>{
  MeetupType.football: '⚽',
  MeetupType.basketball: '🏀',
  MeetupType.volleyball: '🏐',
  MeetupType.tennis: '🎾',
  MeetupType.tableTennis: '🏓',
  MeetupType.badminton: '🏸',
  MeetupType.swimming: '🏊',
  MeetupType.running: '🏃',
  MeetupType.cycling: '🚴',
  MeetupType.hiking: '🥾',
  MeetupType.yoga: '🧘',
  MeetupType.fitness: '💪',
  MeetupType.boxing: '🥊',
  MeetupType.climbing: '🧗',
  MeetupType.skiing: '⛷️',
  MeetupType.other: '🏅',
};

/// Popular sport types shown at the top of the grid.
const _popularTypes = [
  MeetupType.football,
  MeetupType.basketball,
  MeetupType.tennis,
  MeetupType.swimming,
  MeetupType.fitness,
];

/// Displays all [MeetupType] values in a grid layout with emoji + name.
///
/// Popular types are shown first, followed by the remaining types.
/// Supports single selection with visual highlighting.
///
/// Validates: Requirements 2.1, 2.2, 2.3, 2.5
class SportTypeGrid extends StatelessWidget {
  const SportTypeGrid({
    super.key,
    required this.selectedType,
    required this.onTypeSelected,
  });

  /// Currently selected sport type (null if none selected).
  final MeetupType? selectedType;

  /// Callback when a sport type is tapped.
  final ValueChanged<MeetupType> onTypeSelected;

  /// Returns ordered list: popular types first, then remaining types.
  List<MeetupType> get _orderedTypes {
    final remaining = MeetupType.values
        .where((type) => !_popularTypes.contains(type))
        .toList();
    return [..._popularTypes, ...remaining];
  }

  @override
  Widget build(BuildContext context) {
    final types = _orderedTypes;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemCount: types.length,
      itemBuilder: (context, index) {
        final type = types[index];
        final isSelected = type == selectedType;

        return _SportTypeCell(
          type: type,
          emoji: _sportEmojis[type] ?? '🏅',
          isSelected: isSelected,
          onTap: () => onTypeSelected(type),
        );
      },
    );
  }
}

class _SportTypeCell extends StatelessWidget {
  const _SportTypeCell({
    required this.type,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  final MeetupType type;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderLight,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(height: 8),
            Text(
              type.displayName,
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected
                    ? colorScheme.onSurface
                    : AppColors.textMuted,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
