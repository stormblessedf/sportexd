import 'package:flutter/material.dart';
import '../../../../core/models/filter_state.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../theme/app_theme.dart';

class QuickFilterChips extends StatelessWidget {
  final FilterState filterState;
  final bool hasLocationPermission;
  final VoidCallback onTodayTap;
  final VoidCallback onThisWeekTap;
  final VoidCallback onNearMeTap;
  final ValueChanged<MeetupType> onSportTypeTap;
  final VoidCallback onClearFilters;

  const QuickFilterChips({
    super.key,
    required this.filterState,
    required this.hasLocationPermission,
    required this.onTodayTap,
    required this.onThisWeekTap,
    required this.onNearMeTap,
    required this.onSportTypeTap,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          // Clear filters chip (only show when filters are active)
          if (filterState.hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _QuickChip(
                label: 'Temizle',
                icon: Icons.clear,
                isActive: false,
                isDestructive: true,
                onTap: onClearFilters,
              ),
            ),

          // Date filters
          _QuickChip(
            label: 'Bugün',
            icon: Icons.today,
            isActive: filterState.dateRange.type == DateRangeType.today,
            onTap: onTodayTap,
          ),
          const SizedBox(width: 8),

          _QuickChip(
            label: 'Bu Hafta',
            icon: Icons.date_range,
            isActive: filterState.dateRange.type == DateRangeType.thisWeek,
            onTap: onThisWeekTap,
          ),
          const SizedBox(width: 8),

          // Location filter
          _QuickChip(
            label: 'Yakınımda',
            icon: Icons.near_me,
            isActive: filterState.distance != null,
            showLocationIcon: !hasLocationPermission,
            onTap: onNearMeTap,
          ),
          const SizedBox(width: 8),

          // Divider
          Container(
            width: 1,
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
            color: AppTheme.borderLight,
          ),
          const SizedBox(width: 8),

          // Sport type chips
          ...MeetupType.values.map((type) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _QuickChip(
                  label: type.displayName,
                  icon: _getSportIcon(type),
                  isActive: filterState.sportTypes.contains(type),
                  onTap: () => onSportTypeTap(type),
                ),
              )),
        ],
      ),
    );
  }

  IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.volleyball:
        return Icons.sports_volleyball;
      case MeetupType.tennis:
        return Icons.sports_tennis;
      case MeetupType.tableTennis:
        return Icons.sports_cricket;
      case MeetupType.badminton:
        return Icons.sports_tennis;
      case MeetupType.swimming:
        return Icons.pool;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.cycling:
        return Icons.directions_bike;
      case MeetupType.hiking:
        return Icons.hiking;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.fitness:
        return Icons.fitness_center;
      case MeetupType.boxing:
        return Icons.sports_mma;
      case MeetupType.climbing:
        return Icons.terrain;
      case MeetupType.skiing:
        return Icons.downhill_skiing;
      case MeetupType.other:
        return Icons.sports;
    }
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final bool isDestructive;
  final bool showLocationIcon;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.icon,
    required this.isActive,
    this.isDestructive = false,
    this.showLocationIcon = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isDestructive
        ? Colors.red.withValues(alpha:0.1)
        : isActive
            ? AppTheme.primary.withValues(alpha:0.15)
            : AppTheme.surfaceLight;

    final foregroundColor = isDestructive
        ? Colors.red
        : isActive
            ? AppTheme.primary
            : AppTheme.textMuted;

    final borderColor = isDestructive
        ? Colors.red.withValues(alpha:0.3)
        : isActive
            ? AppTheme.primary.withValues(alpha:0.3)
            : AppTheme.borderLight;

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: foregroundColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: foregroundColor,
                ),
              ),
              if (showLocationIcon) ...[
                const SizedBox(width: 4),
                Icon(
                  Icons.location_off,
                  size: 12,
                  color: Colors.orange,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
