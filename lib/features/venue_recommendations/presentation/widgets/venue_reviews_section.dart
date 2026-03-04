import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Displays venue reviews sorted by date with author name, star rating, and text.
///
/// Shows a section header with overall rating summary and a list of review cards
/// separated by subtle dividers. Empty state shows "Henüz yorum yok".
///
/// Validates: Requirements 6.6, 6.7
class VenueReviewsSection extends StatelessWidget {
  const VenueReviewsSection({
    super.key,
    required this.reviews,
    required this.overallRating,
    required this.totalReviewCount,
  });

  /// List of reviews (already sorted by the API).
  final List<VenueReview> reviews;

  /// Venue's overall rating for the header display.
  final double overallRating;

  /// Total review count for the header display.
  final int totalReviewCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          _buildEmpty()
        else
          _buildReviewsList(),
      ],
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20,
          color: AppColors.textDark,
        ),
        const SizedBox(width: 8),
        Text(
          'Yorumlar',
          style: GoogleFonts.lexend(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 12),
        if (totalReviewCount > 0) ...[
          const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
          const SizedBox(width: 4),
          Text(
            '${overallRating.toStringAsFixed(1)}/5',
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($totalReviewCount yorum)',
            style: GoogleFonts.lexend(
              fontSize: 13,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Henüz yorum yok',
        style: GoogleFonts.lexend(
          fontSize: 13,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  Widget _buildReviewsList() {
    return Column(
      children: [
        for (int i = 0; i < reviews.length; i++) ...[
          _ReviewCard(review: reviews[i]),
          if (i < reviews.length - 1)
            const Divider(color: AppColors.borderLight, height: 1),
        ],
      ],
    );
  }
}

/// A single review card showing author, rating, and text.
class _ReviewCard extends StatefulWidget {
  const _ReviewCard({required this.review});

  final VenueReview review;

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAuthorRow(),
          const SizedBox(height: 6),
          _buildStarRating(),
          if (widget.review.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildReviewText(),
          ],
        ],
      ),
    );
  }

  Widget _buildAuthorRow() {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.review.authorName.isNotEmpty
                ? widget.review.authorName
                : 'Anonim',
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark,
            ),
          ),
        ),
        if (widget.review.relativeTime.isNotEmpty)
          Text(
            widget.review.relativeTime,
            style: GoogleFonts.lexend(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
      ],
    );
  }

  Widget _buildStarRating() {
    final fullStars = widget.review.rating.floor();
    final hasHalfStar =
        (widget.review.rating - fullStars) >= 0.5;
    final emptyStars = 5 - fullStars - (hasHalfStar ? 1 : 0);

    return Row(
      children: [
        for (int i = 0; i < fullStars; i++)
          const Icon(Icons.star_rounded, size: 16, color: AppColors.warning),
        if (hasHalfStar)
          const Icon(Icons.star_half_rounded, size: 16, color: AppColors.warning),
        for (int i = 0; i < emptyStars; i++)
          Icon(Icons.star_outline_rounded,
              size: 16, color: AppColors.textLight),
      ],
    );
  }

  Widget _buildReviewText() {
    if (_expanded) {
      return GestureDetector(
        onTap: () => setState(() => _expanded = false),
        child: Text(
          widget.review.text,
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final textSpan = TextSpan(
          text: widget.review.text,
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: AppColors.textMuted,
            height: 1.5,
          ),
        );

        final textPainter = TextPainter(
          text: textSpan,
          maxLines: 3,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: constraints.maxWidth);

        final isOverflowing = textPainter.didExceedMaxLines;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.review.text,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppColors.textMuted,
                height: 1.5,
              ),
            ),
            if (isOverflowing)
              GestureDetector(
                onTap: () => setState(() => _expanded = true),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'Devamını oku',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
