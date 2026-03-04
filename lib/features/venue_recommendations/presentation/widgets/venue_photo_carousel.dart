import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Sport emoji mapping for placeholder when no photos are available.
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

/// Horizontal photo carousel with page indicator dots.
///
/// Shows venue photos in a swipeable [PageView]. While a photo loads,
/// a blurred grey placeholder is displayed. When [photoUrls] is empty,
/// a sport-type emoji placeholder is shown instead.
///
/// Validates: Requirements 6.2, 19.5
class VenuePhotoCarousel extends StatefulWidget {
  const VenuePhotoCarousel({
    super.key,
    required this.photoUrls,
    this.sportType,
    this.height = 250,
    this.borderRadius,
  });

  final List<String> photoUrls;
  final MeetupType? sportType;
  final double height;

  /// Optional border radius. Defaults to rounded top corners (16).
  final BorderRadius? borderRadius;

  @override
  State<VenuePhotoCarousel> createState() => _VenuePhotoCarouselState();
}

class _VenuePhotoCarouselState extends State<VenuePhotoCarousel> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final radius = widget.borderRadius ??
        const BorderRadius.vertical(top: Radius.circular(16));

    return ClipRRect(
      borderRadius: radius,
      child: SizedBox(
        height: widget.height,
        child: widget.photoUrls.isEmpty
            ? _buildPlaceholder()
            : _buildCarousel(),
      ),
    );
  }

  Widget _buildCarousel() {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.photoUrls.length,
          onPageChanged: (index) => setState(() => _currentPage = index),
          itemBuilder: (context, index) => _PhotoItem(
            url: widget.photoUrls[index],
          ),
        ),
        if (widget.photoUrls.length > 1)
          Positioned(
            bottom: 12,
            child: _PageIndicator(
              count: widget.photoUrls.length,
              current: _currentPage,
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    final emoji = _sportEmojis[widget.sportType] ?? '🏅';
    return Container(
      color: AppColors.tagBackground,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 56)),
            const SizedBox(height: 8),
            Text(
              'Fotoğraf yok',
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


/// Single photo item with a blur/grey loading placeholder.
class _PhotoItem extends StatelessWidget {
  const _PhotoItem({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      url,
      fit: BoxFit.cover,
      width: double.infinity,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return _LoadingPlaceholder(
          progress: loadingProgress.expectedTotalBytes != null
              ? loadingProgress.cumulativeBytesLoaded /
                  loadingProgress.expectedTotalBytes!
              : null,
        );
      },
      errorBuilder: (_, _, _) => Container(
        color: AppColors.tagBackground,
        child: const Center(
          child: Icon(
            Icons.broken_image_rounded,
            size: 40,
            color: AppColors.textLight,
          ),
        ),
      ),
    );
  }
}

/// Blurred grey placeholder shown while a photo is loading.
class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder({this.progress});

  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.borderLight,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 2.5,
            color: AppColors.primary,
            backgroundColor: AppColors.textLight.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }
}

/// Row of dots indicating the current page in the carousel.
class _PageIndicator extends StatelessWidget {
  const _PageIndicator({required this.count, required this.current});

  final int count;
  final int current;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(count, (index) {
          final isActive = index == current;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            width: isActive ? 8 : 6,
            height: isActive ? 8 : 6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive ? AppColors.primary : AppColors.textLight,
            ),
          );
        }),
      ),
    );
  }
}
