import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/venue_filter_state.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/core/services/location_service.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/skeleton_venue_card.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_card.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_filter_panel.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/venue_sort_selector.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Screen that displays venue recommendation results in a scrollable list.
///
/// Receives venues as a parameter (already fetched by VenueOnboardingScreen).
/// Shows max 20 venues initially with lazy loading on scroll.
/// Displays skeleton cards during loading and an empty state message
/// when no results are found.
///
/// Validates: Requirements 5.1, 5.6, 5.7, 4.7
class VenueListScreen extends StatefulWidget {
  const VenueListScreen({
    super.key,
    required this.venues,
    required this.sportType,
    required this.regionName,
    this.userLat,
    this.userLng,
    this.detailScreenBuilder,
  });

  final List<VenueModel> venues;
  final MeetupType sportType;
  final String regionName;
  final double? userLat;
  final double? userLng;

  /// Builds the detail screen for a tapped venue.
  /// If null, tapping a venue card is a no-op.
  final Widget Function(VenueModel venue)? detailScreenBuilder;

  @override
  State<VenueListScreen> createState() => _VenueListScreenState();
}

class _VenueListScreenState extends State<VenueListScreen> {
  static const int _pageSize = 20;

  final LocationService _locationService = LocationService();
  final ScrollController _scrollController = ScrollController();

  /// Number of venues currently visible in the list.
  int _displayedCount = _pageSize;
  bool _isLoadingMore = false;
  bool _isInitialLoading = true;

  /// Current filter/sort state for venue list.
  VenueFilterState _filter = VenueFilterState.empty;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    // Simulate brief loading state so skeleton cards are visible.
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) setState(() => _isInitialLoading = false);
    });
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Lazy loading
  // ---------------------------------------------------------------------------

  void _onScroll() {
    if (_isLoadingMore) return;
    if (_displayedCount >= _filteredVenues.length) return;

    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger when within 200px of the bottom.
    if (currentScroll >= maxScroll - 200) {
      _loadMore();
    }
  }

  Future<void> _loadMore() async {
    setState(() => _isLoadingMore = true);
    // Small delay to show loading indicator.
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() {
      _displayedCount =
          (_displayedCount + _pageSize).clamp(0, _filteredVenues.length);
      _isLoadingMore = false;
    });
  }

  // ---------------------------------------------------------------------------
  // Filtered + sorted venues
  // ---------------------------------------------------------------------------

  /// Returns the venue list after applying current filters and sort order.
  List<VenueModel> get _filteredVenues {
    final filtered = widget.venues.where((venue) {
      final distance = _distanceFor(venue);
      return _filter.matches(venue, distanceKm: distance);
    }).toList();
    return _filter.sort(
      filtered,
      distanceCalculator:
          (widget.userLat != null && widget.userLng != null)
              ? (v) => _distanceFor(v) ?? double.infinity
              : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Distance helper
  // ---------------------------------------------------------------------------

  double? _distanceFor(VenueModel venue) {
    if (widget.userLat == null || widget.userLng == null) return null;
    if (venue.latitude == 0.0 && venue.longitude == 0.0) return null;
    return _locationService.calculateDistance(
      widget.userLat!,
      widget.userLng!,
      venue.latitude,
      venue.longitude,
    );
  }

  // ---------------------------------------------------------------------------
  // Navigation
  // ---------------------------------------------------------------------------

  void _onVenueTap(VenueModel venue) {
    final builder = widget.detailScreenBuilder;
    if (builder == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => builder(venue)),
    );
  }

  // ---------------------------------------------------------------------------
  // Filter & sort handlers
  // ---------------------------------------------------------------------------

  void _onFilterChanged(VenueFilterState newFilter) {
    setState(() {
      _filter = newFilter;
      _displayedCount = _pageSize;
    });
  }

  void _onSortChanged(VenueSortOrder newSort) {
    setState(() {
      _filter = _filter.copyWith(sortOrder: newSort);
      _displayedCount = _pageSize;
    });
  }

  void _openFilterPanel() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.9,
        builder: (_, scrollController) => VenueFilterPanel(
          currentFilter: _filter,
          onFilterChanged: _onFilterChanged,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(),
      body: _isInitialLoading
          ? _buildLoadingState()
          : widget.venues.isEmpty
              ? _buildEmptyState()
              : _buildVenueList(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final title = widget.regionName.isNotEmpty
        ? '${widget.sportType.displayName} - ${widget.regionName}'
        : 'Mekan Önerileri';

    return AppBar(
      backgroundColor: AppColors.surfaceLight,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
        onPressed: () => Navigator.of(context).pop(),
      ),
      title: Text(
        title,
        style: GoogleFonts.lexend(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AppColors.textDark,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      centerTitle: true,
      actions: [
        _buildFilterButton(),
      ],
    );
  }

  /// Filter icon button with active filter count badge.
  /// Validates: Requirement 8.8
  Widget _buildFilterButton() {
    final count = _filter.activeFilterCount;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: IconButton(
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(
            '$count',
            style: GoogleFonts.lexend(
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.tune, color: AppColors.textDark),
        ),
        onPressed: _openFilterPanel,
        tooltip: 'Filtreler',
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Loading state — 5 skeleton cards
  // ---------------------------------------------------------------------------

  Widget _buildLoadingState() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => const SkeletonVenueCard(),
    );
  }

  // ---------------------------------------------------------------------------
  // Empty state
  // ---------------------------------------------------------------------------

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off_rounded,
              size: 64,
              color: AppColors.textLight.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              'Bu bölgede sonuç bulunamadı',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Farklı bir bölge veya spor türü deneyin',
              textAlign: TextAlign.center,
              style: GoogleFonts.lexend(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.tune, size: 18),
              label: Text(
                'Kriterleri Değiştir',
                style: GoogleFonts.lexend(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Venue list
  // ---------------------------------------------------------------------------

  Widget _buildVenueList() {
    final venues = _filteredVenues;
    final visibleVenues = venues.take(_displayedCount).toList();
    final hasLocationPermission =
        widget.userLat != null && widget.userLng != null;
    // +1 for the result count header, +1 for sort selector,
    // +1 for location banner if needed, +1 for loading indicator if needed.
    final hasMore = _displayedCount < venues.length;
    final bannerOffset = hasLocationPermission ? 0 : 1;
    // Items: resultCount + sortSelector + (banner?) + venues + (skeleton?)
    final headerCount = 2 + bannerOffset; // resultCount + sort + banner?
    final itemCount =
        visibleVenues.length + headerCount + (hasMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // First item: result count header.
        if (index == 0) return _buildResultCount(venues.length);

        // Second item: sort selector.
        if (index == 1) return _buildSortSelector(hasLocationPermission);

        // Location permission banner (shown right after sort selector).
        if (!hasLocationPermission && index == 2) {
          return _buildLocationPermissionBanner();
        }

        // Last item when loading more: skeleton indicator.
        if (hasMore && index == itemCount - 1) {
          return const Padding(
            padding: EdgeInsets.only(top: 12),
            child: SkeletonVenueCard(),
          );
        }

        final venueIndex = index - headerCount;
        final venue = visibleVenues[venueIndex];
        final distance = _distanceFor(venue);

        return Padding(
          padding: EdgeInsets.only(top: venueIndex == 0 ? 0 : 12),
          child: VenueCard(
            venue: venue,
            distanceKm: distance,
            onTap: () => _onVenueTap(venue),
          ),
        );
      },
    );
  }

  Widget _buildResultCount(int filteredCount) {
    final total = widget.venues.length;
    final text = filteredCount == total
        ? '$total mekan bulundu'
        : '$filteredCount/$total mekan bulundu';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.lexend(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.textMuted,
        ),
      ),
    );
  }

  /// Sort selector row between result count and venue cards.
  /// Validates: Requirement 9.5
  Widget _buildSortSelector(bool hasLocationPermission) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: VenueSortSelector(
        currentSort: _filter.sortOrder,
        onSortChanged: _onSortChanged,
        hasLocationPermission: hasLocationPermission,
      ),
    );
  }

  /// Subtle banner shown when user location is unavailable.
  /// Validates: Requirement 13.4
  Widget _buildLocationPermissionBanner() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.warning.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: AppColors.warning.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_off_outlined,
              size: 18,
              color: AppColors.warning,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Mesafe bilgisi için konum izni gerekli',
                style: GoogleFonts.lexend(
                  fontSize: 12,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
