import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sporsal/core/services/location_service.dart';
import 'package:sporsal/core/services/places_service.dart';
import 'package:sporsal/core/services/search_history_service.dart';
import 'package:sporsal/core/services/venue_recommendation_service.dart';
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
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VenueOnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: Builder(
        builder: (context) {
          final l10n = AppLocalizations.of(context)!;
          return NavigationBar(
            selectedIndex: _calculateSelectedIndex(context),
            onDestinationSelected: (index) => _onItemTapped(index, context),
            destinations: _buildDestinations(l10n),
          );
        },
      ),
    );
  }

  List<NavigationDestination> _buildDestinations(AppLocalizations l10n) {
    return <NavigationDestination>[
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
        icon: const Icon(Icons.sports_handball_outlined),
        selectedIcon: const Icon(Icons.sports_handball),
        label: l10n.swipeInvite,
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
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/home')) return 0;
    if (location.startsWith('/chats')) return 1;
    if (location.startsWith('/create')) return 2;
    if (location.startsWith('/swipe-invites')) return 3;
    // Index 4 is 'Mekanlar' and is opened as an action, not a route.
    if (location.startsWith('/profile')) return 5;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    // Intercept venue icon tap - not a route-based navigation
    if (index == 4) {
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
      case 3:
        context.go('/swipe-invites');
        break;
      case 5:
        context.go('/profile');
        break;
    }
  }
}
