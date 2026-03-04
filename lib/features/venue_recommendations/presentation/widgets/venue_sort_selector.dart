import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/venue_filter_state.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Compact horizontal row of sort option chips for venue list.
///
/// Provides sorting by:
/// - Rating (Puan) – descending
/// - Distance (Mesafe) – ascending, requires location permission
/// - Review count (Yorum Sayısı) – descending
///
/// When distance sort is selected without location permission,
/// a tooltip message is shown to inform the user.
///
/// Validates: Requirements 9.1, 9.2, 9.3, 9.4, 9.5
class VenueSortSelector extends StatelessWidget {
  const VenueSortSelector({
    super.key,
    required this.currentSort,
    required this.onSortChanged,
    this.hasLocationPermission = false,
  });

  final VenueSortOrder currentSort;
  final ValueChanged<VenueSortOrder> onSortChanged;
  final bool hasLocationPermission;

  static const _sortOptions = <VenueSortOrder, String>{
    VenueSortOrder.rating: 'Puan',
    VenueSortOrder.distance: 'Mesafe',
    VenueSortOrder.reviewCount: 'Yorum Sayısı',
  };

  static const _sortIcons = <VenueSortOrder, IconData>{
    VenueSortOrder.rating: Icons.star_rounded,
    VenueSortOrder.distance: Icons.near_me_rounded,
    VenueSortOrder.reviewCount: Icons.reviews_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'Sırala:',
          style: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _sortOptions.entries.map((entry) {
                final selected = currentSort == entry.key;
                final isDistance = entry.key == VenueSortOrder.distance;
                final disabled = isDistance && !hasLocationPermission;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _SortChip(
                    label: entry.value,
                    icon: _sortIcons[entry.key]!,
                    selected: selected,
                    disabled: disabled,
                    onTap: () => _handleTap(context, entry.key),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTap(BuildContext context, VenueSortOrder order) {
    if (order == VenueSortOrder.distance && !hasLocationPermission) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Mesafeye göre sıralama için konum izni gerekli',
              style: GoogleFonts.lexend(fontSize: 13),
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      return;
    }
    onSortChanged(order);
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = disabled
        ? AppColors.textLight
        : selected
            ? AppColors.primary
            : AppColors.textMuted;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.12)
              : AppColors.tagBackground,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.borderLight,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: effectiveColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: effectiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
