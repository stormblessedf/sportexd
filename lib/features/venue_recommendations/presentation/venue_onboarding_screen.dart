import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sporsal/core/models/location_data.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/search_query_model.dart';
import 'package:sporsal/core/models/venue_model.dart';
import 'package:sporsal/core/services/location_service.dart';
import 'package:sporsal/core/services/places_service.dart';
import 'package:sporsal/core/services/search_history_service.dart';
import 'package:sporsal/core/services/venue_recommendation_service.dart';
import 'package:sporsal/features/venue_recommendations/presentation/venue_detail_screen.dart';
import 'package:sporsal/features/venue_recommendations/presentation/venue_list_screen.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/region_selector.dart';
import 'package:sporsal/features/venue_recommendations/presentation/widgets/sport_type_grid.dart';
import 'package:sporsal/theme/app_colors.dart';

/// Two-step onboarding screen for venue recommendations.
///
/// Step 1: Sport type selection via [SportTypeGrid].
/// Step 2: Region selection via [RegionSelector].
///
/// When both selections are complete, searches venues via
/// [VenueRecommendationService] and navigates to the results.
///
/// Validates: Requirements 2.4, 3.6
class VenueOnboardingScreen extends StatefulWidget {
  const VenueOnboardingScreen({super.key});

  @override
  State<VenueOnboardingScreen> createState() => _VenueOnboardingScreenState();
}

class _VenueOnboardingScreenState extends State<VenueOnboardingScreen> {
  final _placesService = PlacesService();
  final _locationService = LocationService();
  final _searchHistoryService = SearchHistoryService();
  late final VenueRecommendationService _venueService;

  int _currentStep = 0;
  MeetupType? _selectedSportType;
  LocationData? _selectedRegion;
  String _regionName = '';
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _venueService = VenueRecommendationService(_placesService);
  }

  // ---------------------------------------------------------------------------
  // Handlers
  // ---------------------------------------------------------------------------

  void _onSportTypeSelected(MeetupType type) {
    setState(() {
      _selectedSportType = type;
    });
  }

  void _goToRegionStep() {
    if (_selectedSportType == null) return;
    setState(() {
      _currentStep = 1;
      _errorMessage = null;
    });
  }

  void _goBackToSportStep() {
    setState(() {
      _currentStep = 0;
      _selectedRegion = null;
      _regionName = '';
      _errorMessage = null;
    });
  }

  void _onRegionSelected(LocationData location) {
    setState(() {
      _selectedRegion = location;
      _errorMessage = null;
    });
  }

  void _onRegionNameChanged(String name) {
    _regionName = name;
  }

  Future<void> _searchVenues() async {
    if (_selectedSportType == null || _selectedRegion == null) return;

    setState(() {
      _isSearching = true;
      _errorMessage = null;
    });

    try {
      // Save search to history
      final query = SearchQueryModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        sportType: _selectedSportType!,
        regionName: _regionName.isNotEmpty
            ? _regionName
            : _selectedRegion!.address ?? 'Bilinmeyen Konum',
        latitude: _selectedRegion!.latitude,
        longitude: _selectedRegion!.longitude,
        searchedAt: DateTime.now(),
      );
      await _searchHistoryService.saveSearch(query);

      // Search venues
      final venues = await _venueService.searchVenues(
        sportType: _selectedSportType!,
        lat: _selectedRegion!.latitude,
        lng: _selectedRegion!.longitude,
      );

      if (!mounted) return;

      // Navigate to results
      // VenueListScreen will be created in task 6.3 — for now log results
      debugPrint(
        'VenueOnboardingScreen: Found ${venues.length} venues for '
        '${_selectedSportType!.displayName} in $_regionName',
      );

      _navigateToResults(venues);
    } on VenueException catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.userMessage;
        _isSearching = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
        _isSearching = false;
      });
    }
  }

  void _navigateToResults(List<VenueModel> venues) {
    final sportType = _selectedSportType!;
    final userLat = _selectedRegion!.latitude;
    final userLng = _selectedRegion!.longitude;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => VenueListScreen(
          venues: venues,
          sportType: sportType,
          regionName: _regionName.isNotEmpty
              ? _regionName
              : _selectedRegion!.address ?? '',
          userLat: userLat,
          userLng: userLng,
          detailScreenBuilder: (venue) {
            double? distanceKm;
            if (venue.latitude != 0.0 || venue.longitude != 0.0) {
              distanceKm = _locationService.calculateDistance(
                userLat,
                userLng,
                venue.latitude,
                venue.longitude,
              );
            }
            return VenueDetailScreen(
              placeId: venue.placeId,
              sportType: sportType,
              initialVenue: venue,
              distanceKm: distanceKm,
            );
          },
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
      appBar: AppBar(
        backgroundColor: AppColors.surfaceLight,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: _currentStep == 0
              ? () => Navigator.of(context).pop()
              : _goBackToSportStep,
        ),
        title: Text(
          _currentStep == 0 ? 'Spor Türü Seçin' : 'Bölge Seçin',
          style: GoogleFonts.lexend(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        centerTitle: true,
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _currentStep == 0
            ? _buildSportTypeStep()
            : _buildRegionStep(),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 1: Sport Type Selection
  // ---------------------------------------------------------------------------

  Widget _buildSportTypeStep() {
    return Column(
      key: const ValueKey('sport_step'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'Hangi sporu yapmak istiyorsunuz?',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SportTypeGrid(
                  selectedType: _selectedSportType,
                  onTypeSelected: _onSportTypeSelected,
                ),
              ],
            ),
          ),
        ),
        _buildContinueButton(),
      ],
    );
  }

  Widget _buildContinueButton() {
    final isEnabled = _selectedSportType != null;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isEnabled ? _goToRegionStep : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isEnabled ? AppColors.primary : AppColors.borderLight,
              foregroundColor:
                  isEnabled ? Colors.white : AppColors.textLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Text(
              'Devam',
              style: GoogleFonts.lexend(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Step 2: Region Selection
  // ---------------------------------------------------------------------------

  Widget _buildRegionStep() {
    return Column(
      key: const ValueKey('region_step'),
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Selected sport chip
                _buildSelectedSportChip(),
                const SizedBox(height: 20),
                Text(
                  'Nerede spor yapmak istiyorsunuz?',
                  style: GoogleFonts.lexend(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 16),
                RegionSelector(
                  onRegionSelected: _onRegionSelected,
                  onRegionNameChanged: _onRegionNameChanged,
                  autocompleteFetcher: _placesService.getAutocomplete,
                  placeDetailFetcher: _placesService.getPlaceDetails,
                  currentLocationFetcher: _locationService.getCurrentLocation,
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  _buildErrorBanner(),
                ],
              ],
            ),
          ),
        ),
        _buildSearchButton(),
      ],
    );
  }

  Widget _buildSelectedSportChip() {
    if (_selectedSportType == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.sports, size: 16, color: AppColors.primary),
          const SizedBox(width: 6),
          Text(
            _selectedSportType!.displayName,
            style: GoogleFonts.lexend(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchButton() {
    final isEnabled = _selectedRegion != null && !_isSearching;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: isEnabled ? _searchVenues : null,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isEnabled ? AppColors.primary : AppColors.borderLight,
              foregroundColor:
                  isEnabled ? Colors.white : AppColors.textLight,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: _isSearching
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    'Ara',
                    style: GoogleFonts.lexend(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.error.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.lexend(
                fontSize: 12,
                color: AppColors.textMuted,
              ),
            ),
          ),
          TextButton(
            onPressed: _searchVenues,
            child: Text(
              'Tekrar Dene',
              style: GoogleFonts.lexend(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
