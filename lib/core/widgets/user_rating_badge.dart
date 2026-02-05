import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// A compact rating badge widget that displays a user's average rating
/// next to their username. Shows a star icon with the rating value.
class UserRatingBadge extends StatelessWidget {
  final double rating;
  final double fontSize;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? starColor;

  const UserRatingBadge({
    super.key,
    required this.rating,
    this.fontSize = 11,
    this.backgroundColor,
    this.textColor,
    this.starColor,
  });

  @override
  Widget build(BuildContext context) {
    // Don't show badge if rating is 0 or negative
    if (rating <= 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: backgroundColor ?? const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: fontSize + 1,
            color: starColor ?? const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 2),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: textColor ?? const Color(0xFFB45309),
            ),
          ),
        ],
      ),
    );
  }
}

/// A widget that displays a username with an optional rating badge inline.
/// If userId is provided, the widget becomes tappable and navigates to the user's profile.
class UsernameWithRating extends StatelessWidget {
  final String username;
  final double? rating;
  final String? userId;
  final TextStyle? usernameStyle;
  final double ratingFontSize;
  final MainAxisSize mainAxisSize;
  final VoidCallback? onTap;

  const UsernameWithRating({
    super.key,
    required this.username,
    this.rating,
    this.userId,
    this.usernameStyle,
    this.ratingFontSize = 11,
    this.mainAxisSize = MainAxisSize.min,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Row(
      mainAxisSize: mainAxisSize,
      children: [
        Flexible(
          child: Text(
            username,
            style:
                usernameStyle ??
                const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0F172A),
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (rating != null && rating! > 0) ...[
          const SizedBox(width: 6),
          UserRatingBadge(rating: rating!, fontSize: ratingFontSize),
        ],
      ],
    );

    // If userId is provided or onTap is provided, make it tappable
    if (userId != null || onTap != null) {
      return GestureDetector(
        onTap:
            onTap ??
            () {
              if (userId != null) {
                context.push('/user-profile/$userId');
              }
            },
        child: content,
      );
    }

    return content;
  }
}

/// A simple tappable username widget that navigates to user profile
class TappableUsername extends StatelessWidget {
  final String username;
  final String userId;
  final TextStyle? style;
  final double? rating;

  const TappableUsername({
    super.key,
    required this.username,
    required this.userId,
    this.style,
    this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        context.push('/user-profile/$userId');
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Text(
              username,
              style:
                  style ??
                  const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (rating != null && rating! > 0) ...[
            const SizedBox(width: 6),
            UserRatingBadge(rating: rating!),
          ],
        ],
      ),
    );
  }
}
