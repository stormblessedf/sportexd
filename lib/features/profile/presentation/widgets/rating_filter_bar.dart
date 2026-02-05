import 'package:flutter/material.dart';

enum RatingFilter {
  mostRecent,
  highest,
  lowest,
}

extension RatingFilterExtension on RatingFilter {
  String get displayName {
    switch (this) {
      case RatingFilter.mostRecent:
        return 'Most Recent';
      case RatingFilter.highest:
        return 'Highest';
      case RatingFilter.lowest:
        return 'Lowest';
    }
  }
}

class RatingFilterBar extends StatelessWidget {
  final RatingFilter currentFilter;
  final Function(RatingFilter) onFilterSelected;

  const RatingFilterBar({
    super.key,
    required this.currentFilter,
    required this.onFilterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: RatingFilter.values.map((filter) {
          final isActive = filter == currentFilter;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(filter.displayName),
              selected: isActive,
              onSelected: (_) => onFilterSelected(filter),
              backgroundColor: Colors.white,
              selectedColor: Theme.of(context).primaryColor.withValues(alpha:0.2),
              checkmarkColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey[700],
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
              side: BorderSide(
                color: isActive
                    ? Theme.of(context).primaryColor
                    : Colors.grey[300]!,
                width: isActive ? 2 : 1,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
