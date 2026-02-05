import 'package:flutter/material.dart';

class StarRatingSelector extends StatelessWidget {
  final int? selectedRating;
  final Function(int) onRatingSelected;

  const StarRatingSelector({
    super.key,
    required this.selectedRating,
    required this.onRatingSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final starValue = index + 1;
        final isSelected = selectedRating != null && starValue <= selectedRating!;

        return GestureDetector(
          onTap: () => onRatingSelected(starValue),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Icon(
              isSelected ? Icons.star : Icons.star_border,
              size: 48,
              color: isSelected
                  ? Colors.amber
                  : Colors.grey[400],
            ),
          ),
        );
      }),
    );
  }
}
