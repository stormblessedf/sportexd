import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sporsal/core/services/location_service.dart';
import 'package:sporsal/core/services/places_service.dart';
import 'package:sporsal/core/services/search_history_service.dart';
import 'package:sporsal/core/services/venue_recommendation_service.dart';
import 'package:sporsal/features/profile/presentation/controllers/photo_upload_controller.dart';
import 'package:sporsal/features/venue_recommendations/presentation/venue_detail_screen.dart';
import 'package:sporsal/features/venue_recommendations/presentation/venue_list_screen.dart';
import 'package:sporsal/features/venue_recommendations/presentation/venue_onboarding_screen.dart';
import 'package:sporsal/theme/app_colors.dart';
import 'package:sporsal/l10n/app_localizations.dart';

class MainShell extends StatefulWidget {
  final Widget navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final SearchHistoryService _searchHistoryService = SearchHistoryService();
  bool _hasActiveSession = false;

  /// Kullanıcı kendi profil ekranındaysa true döner.
  /// `/profile` rotası kendi profili; `/profile/:id` başka kullanıcı.
  bool get _isOnOwnProfile {
    final location = GoRouterState.of(context).uri.toString();
    return location == '/profile';
  }

  @override
  void initState() {
    super.initState();
    _checkActiveSession();
  }

  /// Checks if there are recent searches (indicating a previous onboarding).
  Future<void> _checkActiveSession() async {
    final searches = await _searchHistoryService.getRecentSearches();
    if (mounted) {
      setState(() => _hasActiveSession = searches.isNotEmpty);
    }
  }

  /// Handles venue icon tap.
  /// If user has previous searches, navigates directly to VenueListScreen
  /// with the last search query. Otherwise opens VenueOnboardingScreen.
  Future<void> _onVenueIconTapped() async {
    final searches = await _searchHistoryService.getRecentSearches();

    if (!mounted) return;

    if (searches.isNotEmpty) {
      final lastSearch = searches.first;
      final placesService = PlacesService();
      final venueService = VenueRecommendationService(placesService);
      final locationService = LocationService();

      try {
        final venues = await venueService.searchVenues(
          sportType: lastSearch.sportType,
          lat: lastSearch.latitude,
          lng: lastSearch.longitude,
        );

        if (!mounted) return;

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => VenueListScreen(
              venues: venues,
              sportType: lastSearch.sportType,
              regionName: lastSearch.regionName,
              userLat: lastSearch.latitude,
              userLng: lastSearch.longitude,
              detailScreenBuilder: (venue) {
                double? distanceKm;
                if (venue.latitude != 0.0 || venue.longitude != 0.0) {
                  distanceKm = locationService.calculateDistance(
                    lastSearch.latitude,
                    lastSearch.longitude,
                    venue.latitude,
                    venue.longitude,
                  );
                }
                return VenueDetailScreen(
                  placeId: venue.placeId,
                  sportType: lastSearch.sportType,
                  initialVenue: venue,
                  distanceKm: distanceKm,
                );
              },
            ),
          ),
        );
      } catch (_) {
        // On error, fall back to onboarding
        if (!mounted) return;
        _navigateToOnboarding();
      }
    } else {
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const VenueOnboardingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isOwnProfile = _isOnOwnProfile;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: ListenableBuilder(
        listenable: PhotoUploadController.instance,
        builder: (context, _) {
          final l10n = AppLocalizations.of(context)!;
          return NavigationBar(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) =>
                _onItemTapped(index, context, isOwnProfile),
            destinations: _buildDestinations(isOwnProfile, l10n),
          );
        },
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(
      bool isOwnProfile, AppLocalizations l10n) {
    final destinations = <NavigationDestination>[
      NavigationDestination(
        icon: const Icon(Icons.home_outlined),
        selectedIcon: const Icon(Icons.home),
        label: l10n.navFeed,
      ),
      NavigationDestination(
        icon: const Icon(Icons.chat_bubble_outline),
        selectedIcon: const Icon(Icons.chat_bubble),
        label: l10n.navChats,
      ),
      NavigationDestination(
        icon: const Icon(Icons.add_circle_outline),
        selectedIcon: const Icon(Icons.add_circle),
        label: l10n.navCreate,
      ),
      NavigationDestination(
        icon: Badge(
          isLabelVisible: _hasActiveSession,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.place_outlined),
        ),
        selectedIcon: Badge(
          isLabelVisible: _hasActiveSession,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.place),
        ),
        label: l10n.navVenues,
      ),
      NavigationDestination(
        icon: const Icon(Icons.person_outline),
        selectedIcon: const Icon(Icons.person),
        label: l10n.navProfile,
      ),
    ];

    if (isOwnProfile) {
      final isUploading = PhotoUploadController.instance.isUploading;
      destinations.add(
        NavigationDestination(
          icon: Icon(
            Icons.add_a_photo_outlined,
            color: isUploading ? Colors.grey : null,
          ),
          selectedIcon: Icon(
            Icons.add_a_photo,
            color: isUploading ? Colors.grey : null,
          ),
          label: l10n.navPhoto,
          enabled: !isUploading,
        ),
      );
    }

    return destinations;
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/create')) return 2;
    // Index 3 is now 'Mekanlar' — it's never "selected" via route
    if (location.startsWith('/profile')) return 4;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context, bool isOwnProfile) {
    // Intercept the photo upload button (last item when on own profile)
    if (isOwnProfile && index == 5) {
      if (!PhotoUploadController.instance.isUploading) {
        PhotoUploadController.instance.triggerUpload();
      }
      return;
    }

    // Intercept venue icon tap — not a route-based navigation
    if (index == 3) {
      _onVenueIconTapped();
      return;
    }

    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/chats');
        break;
      case 2:
        context.go('/create');
        break;
      case 4:
        context.go('/profile');
        break;
    }
  }
}
