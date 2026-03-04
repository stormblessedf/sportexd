import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Sport emoji mapping for placeholder thumbnails when no photo is available.
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

/// Venue card widget displaying venue summary info in a horizontal layout.
///
/// Shows venue photo (or sport-type placeholder), name, address,
/// rating with stars, review count, distance, open/closed status,
/// and a favorite heart icon.
///
/// Matches the [SkeletonVenueCard] layout: leading 80×80 image + info column.
///
/// Validates: Requirements 5.1, 5.2, 5.3, 5.4, 5.5, 5.6
class VenueCard extends StatelessWidget {
  const VenueCard({
    super.key,
    required this.venue,
    this.distanceKm,
    this.isFavorite = false,
    required this.onTap,
    this.onFavoriteTap,
  });

  final VenueModel venue;
  final double? distanceKm;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback? onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildThumbnail(),
            const SizedBox(width: 12),
            Expanded(child: _buildInfoColumn()),
            if (onFavoriteTap != null) _buildFavoriteButton(),
          ],
        ),
      ),
    );
  }

  /// Leading 80×80 rounded image or sport-type emoji placeholder.
  ///
  /// Uses [frameBuilder] for a smooth fade-in animation when the image loads,
  /// and [loadingBuilder] to show a grey shimmer placeholder while loading.
  /// Flutter's Image.network uses the browser cache on web automatically.
  ///
  /// Validates: Requirements 19.2, 19.3, 19.5
  Widget _buildThumbnail() {
    if (venue.photoUrls.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          venue.photoUrls.first,
          width: 80,
          height: 80,
          fit: BoxFit.cover,
          frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
            if (wasSynchronouslyLoaded) return child;
            return AnimatedOpacity(
              opacity: frame == null ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: child,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.borderLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AppColors.primary,
                  ),
                ),
              ),
            );
          },
          errorBuilder: (_, _, _) => _buildPlaceholder(),
        ),
      );
    }
    return _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    final emoji = _sportEmojis[venue.sportType] ?? '🏅';
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: AppColors.tagBackground,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Text(emoji, style: const TextStyle(fontSize: 32)),
      ),
    );
  }

  /// Info column: name, address, rating row, distance + open/closed row.
  Widget _buildInfoColumn() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Venue name
        Text(
          venue.name,
          style: GoogleFonts.lexend(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Address
        Text(
          venue.address,
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: AppColors.textMuted,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 6),
        // Rating + review count
        _buildRatingRow(),
        const SizedBox(height: 6),
        // Distance + open/closed status
        _buildBottomRow(),
      ],
    );
  }

  Widget _buildRatingRow() {
    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 16, color: Colors.amber),
        const SizedBox(width: 2),
        Text(
          venue.rating.toStringAsFixed(1),
          style: GoogleFonts.lexend(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${venue.userRatingCount} yorum)',
          style: GoogleFonts.lexend(
            fontSize: 11,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomRow() {
    return Row(
      children: [
        // Distance info
        if (distanceKm != null) ...[
          const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
          const SizedBox(width: 2),
          Text(
            _formatDistance(distanceKm!),
            style: GoogleFonts.lexend(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(width: 8),
        ],
        // Open/closed chip
        _buildStatusChip(),
      ],
    );
  }

  Widget _buildStatusChip() {
    final isOpen = venue.isOpen;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isOpen ? 'Açık' : 'Kapalı',
        style: GoogleFonts.lexend(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  /// Favorite heart icon button in the top-right area.
  Widget _buildFavoriteButton() {
    return GestureDetector(
      onTap: onFavoriteTap,
      child: Padding(
        padding: const EdgeInsets.only(left: 4),
        child: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 22,
          color: isFavorite ? AppColors.error : AppColors.textLight,
        ),
      ),
    );
  }

  /// Formats distance: under 1 km → meters, otherwise km with 1 decimal.
  static String _formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }
}
