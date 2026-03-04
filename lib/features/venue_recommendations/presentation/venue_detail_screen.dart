import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/core/services/places_service.dart';
import 'package:sporsal/core/services/venue_recommendation_service.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_photo_carousel.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_reviews_section.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_working_hours.dart';
import 'package:sporsal/theme/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

/// Full-screen venue detail page showing photos, info, hours, reviews, and map.
///
/// Fetches full details via [VenueRecommendationService.getVenueDetails].
/// If [initialVenue] is provided, it is displayed immediately while the
/// full details load in the background.
///
/// Validates: Requirements 6.1, 6.2, 6.3, 6.4, 6.5, 6.6, 6.7, 6.8, 6.9, 6.10, 17.2
class VenueDetailScreen extends StatefulWidget {
  const VenueDetailScreen({
    super.key,
    required this.placeId,
    this.sportType,
    this.initialVenue,
    this.distanceKm,
  });

  final String placeId;
  final MeetupType? sportType;

  /// Optional: pass initial venue data for instant display while full details load.
  final VenueModel? initialVenue;

  /// Optional: pre-calculated distance from user to venue in km.
  final double? distanceKm;

  @override
  State<VenueDetailScreen> createState() => _VenueDetailScreenState();
}

class _VenueDetailScreenState extends State<VenueDetailScreen>
    with SingleTickerProviderStateMixin {
  late final VenueRecommendationService _venueService;

  VenueModel? _venue;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';

  // Shimmer animation
  late final AnimationController _shimmerController;
  late final Animation<double> _shimmerAnimation;

  @override
  void initState() {
    super.initState();
    _venue = widget.initialVenue;
    _venueService = VenueRecommendationService(PlacesService());

    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    _fetchDetails();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final venue = await _venueService.getVenueDetails(widget.placeId);
      if (!mounted) return;

      if (venue == null) {
        setState(() {
          _isLoading = false;
          _hasError = _venue == null; // error only if no initial data
        });
        return;
      }

      setState(() {
        _venue = VenueModel(
          placeId: venue.placeId,
          name: venue.name,
          address: venue.address,
          latitude: venue.latitude,
          longitude: venue.longitude,
          rating: venue.rating,
          userRatingCount: venue.userRatingCount,
          priceLevel: venue.priceLevel,
          isOpen: venue.isOpen,
          weekdayHours: venue.weekdayHours,
          phoneNumber: venue.phoneNumber,
          photoUrls: venue.photoUrls,
          reviews: venue.reviews,
          sportType: venue.sportType ?? widget.sportType,
        );
        _isLoading = false;
      });
    } on VenueException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = _venue == null;
        _errorMessage = e.userMessage;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = _venue == null;
        _errorMessage = 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
      });
    }
  }

  // ---------------------------------------------------------------------------
  // Price level display
  // ---------------------------------------------------------------------------

  String _priceLevelText(int level) {
    switch (level) {
      case 0:
        return 'Ücretsiz';
      case 1:
        return '₺';
      case 2:
        return '₺₺';
      case 3:
        return '₺₺₺';
      case 4:
        return '₺₺₺₺';
      default:
        return '';
    }
  }

  // ---------------------------------------------------------------------------
  // External app launchers
  // ---------------------------------------------------------------------------

  Future<void> _openMaps() async {
    final venue = _venue;
    if (venue == null) return;
    final url = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${venue.latitude},${venue.longitude}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone() async {
    final phone = _venue?.phoneNumber;
    if (phone == null || phone.isEmpty) return;
    final url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    // Full loading state (no initial venue)
    if (_venue == null && _isLoading) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        body: _buildShimmerLoading(),
      );
    }

    // Error state (no data at all)
    if (_venue == null && _hasError) {
      return Scaffold(
        backgroundColor: AppColors.backgroundLight,
        appBar: AppBar(
          backgroundColor: AppColors.surfaceLight,
          elevation: 0,
          leading: const BackButton(color: AppColors.textDark),
        ),
        body: _buildErrorState(),
      );
    }

    final venue = _venue!;
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(venue),
          SliverToBoxAdapter(child: _buildContent(venue)),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sliver app bar with photo carousel
  // ---------------------------------------------------------------------------

  Widget _buildSliverAppBar(VenueModel venue) {
    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: AppColors.surfaceLight,
      leading: _buildBackButton(),
      flexibleSpace: FlexibleSpaceBar(
        background: VenuePhotoCarousel(
          photoUrls: venue.photoUrls,
          sportType: venue.sportType ?? widget.sportType,
          height: 250,
          borderRadius: BorderRadius.zero,
        ),
      ),
    );
  }

  Widget _buildBackButton() {
    return Padding(
      padding: const EdgeInsets.all(4),
      child: CircleAvatar(
        backgroundColor: Colors.black.withValues(alpha: 0.35),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Main content
  // ---------------------------------------------------------------------------

  Widget _buildContent(VenueModel venue) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Venue name
          Text(
            venue.name,
            style: GoogleFonts.lexend(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),

          // Address
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.location_on_outlined,
                  size: 18, color: AppColors.textMuted),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  venue.address,
                  style: GoogleFonts.lexend(
                    fontSize: 13,
                    color: AppColors.textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Distance info
          if (widget.distanceKm != null)
            _buildDistanceRow(widget.distanceKm!)
          else
            _buildNoLocationHint(),
          const SizedBox(height: 12),

          // Rating row + price level
          _buildRatingRow(venue),
          const SizedBox(height: 12),

          // Open/closed badge
          _buildOpenClosedBadge(venue.isOpen),
          const SizedBox(height: 16),

          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 16),

          // Working hours
          VenueWorkingHours(
            weekdayHours: venue.weekdayHours,
            isOpen: venue.isOpen,
          ),
          const SizedBox(height: 16),

          const Divider(color: AppColors.borderLight, height: 1),
          const SizedBox(height: 16),

          // Reviews
          VenueReviewsSection(
            reviews: venue.reviews,
            overallRating: venue.rating,
            totalReviewCount: venue.userRatingCount,
          ),
          const SizedBox(height: 16),

          // Phone number (if available)
          if (venue.phoneNumber.isNotEmpty) ...[
            _buildPhoneRow(venue.phoneNumber),
            const SizedBox(height: 16),
          ],

          // Map preview
          _buildMapPreview(venue),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Distance display
  // ---------------------------------------------------------------------------

  /// Formats distance: under 1 km → meters, otherwise km with 1 decimal.
  static String _formatDistance(double km) {
    if (km < 1.0) {
      return '${(km * 1000).round()} m';
    }
    return '${km.toStringAsFixed(1)} km';
  }

  /// Distance row with location icon. Validates: Requirement 13.2, 13.3
  Widget _buildDistanceRow(double distanceKm) {
    return Row(
      children: [
        Icon(
          Icons.near_me_outlined,
          size: 16,
          color: AppColors.primary.withValues(alpha: 0.8),
        ),
        const SizedBox(width: 6),
        Text(
          _formatDistance(distanceKm),
          style: GoogleFonts.lexend(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  /// Subtle hint when location permission is not available.
  /// Validates: Requirement 13.4
  Widget _buildNoLocationHint() {
    return Row(
      children: [
        Icon(
          Icons.location_off_outlined,
          size: 16,
          color: AppColors.warning.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 6),
        Text(
          'Konum izni gerekli',
          style: GoogleFonts.lexend(
            fontSize: 12,
            color: AppColors.textLight,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Rating row
  // ---------------------------------------------------------------------------

  Widget _buildRatingRow(VenueModel venue) {
    final priceText = _priceLevelText(venue.priceLevel);

    return Row(
      children: [
        const Icon(Icons.star_rounded, size: 20, color: AppColors.warning),
        const SizedBox(width: 4),
        Text(
          venue.rating.toStringAsFixed(1),
          style: GoogleFonts.lexend(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          '(${venue.userRatingCount} yorum)',
          style: GoogleFonts.lexend(
            fontSize: 13,
            color: AppColors.textMuted,
          ),
        ),
        if (priceText.isNotEmpty) ...[
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.tagBackground,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              priceText,
              style: GoogleFonts.lexend(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Open/closed badge
  // ---------------------------------------------------------------------------

  Widget _buildOpenClosedBadge(bool isOpen) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: isOpen
            ? AppColors.success.withValues(alpha: 0.12)
            : AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        isOpen ? 'Şu an açık' : 'Şu an kapalı',
        style: GoogleFonts.lexend(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isOpen ? AppColors.success : AppColors.error,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Phone row
  // ---------------------------------------------------------------------------

  Widget _buildPhoneRow(String phone) {
    return GestureDetector(
      onTap: _callPhone,
      child: Row(
        children: [
          const Icon(Icons.phone_outlined, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Text(
            phone,
            style: GoogleFonts.lexend(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Map preview
  // ---------------------------------------------------------------------------

  Widget _buildMapPreview(VenueModel venue) {
    return GestureDetector(
      onTap: _openMaps,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.borderLight),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.map_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Haritada Göster',
                    style: GoogleFonts.lexend(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Google Maps\'te aç',
                    style: GoogleFonts.lexend(
                      fontSize: 12,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.textLight,
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Shimmer loading state
  // ---------------------------------------------------------------------------

  Widget _buildShimmerLoading() {
    return AnimatedBuilder(
      animation: _shimmerAnimation,
      builder: (context, _) {
        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Back button area
              Padding(
                padding: const EdgeInsets.all(8),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              // Photo placeholder
              _shimmerBox(height: 200, borderRadius: 0),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _shimmerBox(height: 20, widthFactor: 0.7),
                    const SizedBox(height: 12),
                    _shimmerBox(height: 14, widthFactor: 0.9),
                    const SizedBox(height: 12),
                    _shimmerBox(height: 14, widthFactor: 0.4),
                    const SizedBox(height: 20),
                    _shimmerBox(height: 1),
                    const SizedBox(height: 20),
                    _shimmerBox(height: 16, widthFactor: 0.5),
                    const SizedBox(height: 12),
                    for (int i = 0; i < 4; i++) ...[
                      _shimmerBox(height: 14),
                      const SizedBox(height: 8),
                    ],
                    const SizedBox(height: 20),
                    _shimmerBox(height: 1),
                    const SizedBox(height: 20),
                    _shimmerBox(height: 16, widthFactor: 0.4),
                    const SizedBox(height: 12),
                    _shimmerBox(height: 60),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _shimmerBox({
    required double height,
    double? widthFactor,
    double borderRadius = 6,
  }) {
    final box = Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Colors.grey[300]!,
            Colors.grey[100]!,
            Colors.grey[300]!,
          ],
          stops: [
            (_shimmerAnimation.value - 0.3).clamp(0.0, 1.0),
            _shimmerAnimation.value.clamp(0.0, 1.0),
            (_shimmerAnimation.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );

    if (widthFactor != null) {
      return FractionallySizedBox(
        widthFactor: widthFactor,
        alignment: Alignment.centerLeft,
        child: box,
      );
    }
    return box;
  }

  // ---------------------------------------------------------------------------
  // Error state
  // ---------------------------------------------------------------------------

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: AppColors.textLight.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Mekan detayları yüklenemedi',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage.isNotEmpty
                  ? _errorMessage
                  : 'Lütfen internet bağlantınızı kontrol edip tekrar deneyin',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDetails,
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(
                'Tekrar Dene',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
