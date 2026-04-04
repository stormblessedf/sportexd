import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/filter_state.dart';
import '../models/meetup_model.dart';
import '../services/filter_service.dart';
import '../services/search_service.dart' show Debouncer;
import '../services/recommendation_service.dart';
import '../services/location_service.dart';

class DiscoveryController extends ChangeNotifier {
  // Services
  final FilterService _filterService = FilterService();
  final RecommendationService _recommendationService = RecommendationService();

  // State
  FilterState _filterState = FilterState.empty;
  ViewMode _viewMode = ViewMode.list;
  List<MeetupModel> _allMeetups = [];
  List<MeetupWithDistance> _filteredMeetups = [];
  RecommendationSections _recommendations = const RecommendationSections();

  // Loading states
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _error;

  // Pagination
  DocumentSnapshot? _lastDocument;
  static const int _pageSize = 20;

  // Location
  double? _userLatitude;
  double? _userLongitude;
  bool _hasLocationPermission = false;

  // Search debouncer
  final Debouncer _searchDebouncer = Debouncer();

  // User ID for recommendations
  String? _userId;

  // Getters
  FilterState get filterState => _filterState;
  ViewMode get viewMode => _viewMode;
  List<MeetupWithDistance> get meetups => _filteredMeetups;
  RecommendationSections get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasMore => _hasMore;
  String? get error => _error;
  bool get hasLocationPermission => _hasLocationPermission;
  double? get userLatitude => _userLatitude;
  double? get userLongitude => _userLongitude;

  /// Initialize the controller
  Future<void> initialize(String userId) async {
    _userId = userId;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Load saved filter state but clear sport type filters AND distance filter.
      // Sport type filters are session-only to prevent stale filters
      // from hiding newly created meetups.
      // Distance filter is also cleared because saved coordinates may be stale
      // and would silently exclude meetups in different locations.
      final savedState = await _filterService.loadFilterState();
      if (savedState != null) {
        _filterState = savedState.copyWith(
          sportTypes: <MeetupType>{},
          clearDistance: true,
        );
        debugPrint('[Feed] Loaded saved filter (sport types + distance cleared): dateRange=${_filterState.dateRange.type.name}, sort=${_filterState.sortOrder.name}');
      } else {
        debugPrint('[Feed] No saved filter, using defaults');
      }

      // Try to get user location (with timeout to prevent web hang)
      await _updateUserLocation().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          debugPrint('[Feed] Location fetch timed out, proceeding without location');
        },
      );

      // Fetch initial data
      await _fetchMeetups();

      // Generate recommendations
      await _generateRecommendations();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update user location
  Future<void> _updateUserLocation() async {
    try {
      final locationService = LocationService();
      final location = await locationService.getCurrentLocation();
      if (location != null) {
        _userLatitude = location.latitude;
        _userLongitude = location.longitude;
        _hasLocationPermission = true;
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      _hasLocationPermission = false;
    }
  }

  /// Request location permission
  Future<bool> requestLocationPermission() async {
    try {
      final locationService = LocationService();
      final location = await locationService.getCurrentLocation();
      if (location != null) {
        _userLatitude = location.latitude;
        _userLongitude = location.longitude;
        _hasLocationPermission = true;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Error requesting location: $e');
    }
    _hasLocationPermission = false;
    notifyListeners();
    return false;
  }

  /// Fetch meetups with current filters
  Future<void> _fetchMeetups({bool reset = true}) async {
    if (reset) {
      _lastDocument = null;
      _hasMore = true;
      _allMeetups = [];
    }

    try {
      debugPrint('[Feed] filterState: sportTypes=${_filterState.sportTypes}, dateRange=${_filterState.dateRange.type.name}, startDate=${_filterState.dateRange.startDate}, endDate=${_filterState.dateRange.endDate}');
      final query = _filterService.buildQuery(_filterState);
      final limitedQuery = query.limit(_pageSize);

      QuerySnapshot<Map<String, dynamic>> snapshot;
      if (_lastDocument != null) {
        snapshot = await limitedQuery.startAfterDocument(_lastDocument!).get(
          const GetOptions(source: Source.serverAndCache),
        );
      } else {
        snapshot = await limitedQuery.get(
          const GetOptions(source: Source.serverAndCache),
        );
      }

      debugPrint('[Feed] Query returned ${snapshot.docs.length} documents');
      for (final doc in snapshot.docs) {
        final data = doc.data();
        debugPrint('[Feed] doc=${doc.id}, title=${data['title']}, date=${data['date']}, type=${data['type']}');
      }

      if (snapshot.docs.isEmpty) {
        _hasMore = false;
      } else {
        _lastDocument = snapshot.docs.last;
        final newMeetups = snapshot.docs
            .map((doc) => MeetupModel.fromJson(doc.data()))
            .where((meetup) => meetup.isFeedVisible)
            .toList();
        _allMeetups.addAll(newMeetups);
        _hasMore = newMeetups.length == _pageSize;
      }

      // Apply post-filters
      _applyFilters();
    } catch (e) {
      debugPrint('Error fetching meetups: $e');
      _error = 'Etkinlikler yüklenirken hata oluştu';
      rethrow;
    }
  }

  /// Apply filters to all meetups
  void _applyFilters() {
    _filteredMeetups = _filterService.applyPostFilters(
      _allMeetups,
      _filterState,
      _userLatitude,
      _userLongitude,
    );
    debugPrint('[Feed] After post-filters: ${_allMeetups.length} -> ${_filteredMeetups.length} meetups');
    notifyListeners();
  }

  /// Generate recommendations
  Future<void> _generateRecommendations() async {
    if (_userId == null) return;

    try {
      _recommendations = await _recommendationService.generateRecommendations(
        userId: _userId!,
        userLatitude: _userLatitude,
        userLongitude: _userLongitude,
        allMeetups: _allMeetups,
      );
    } catch (e) {
      debugPrint('Error generating recommendations: $e');
    }
  }

  /// Apply new filters
  Future<void> applyFilters(FilterState newState) async {
    _filterState = newState;
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Save filter state (excludes search query and sport types — sport types are session-only)
      await _filterService.saveFilterState(
        newState.copyWith(searchQuery: '', sportTypes: <MeetupType>{}),
      );

      // Fetch new data
      await _fetchMeetups(reset: true);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update search query with debouncing
  void search(String query) {
    _searchDebouncer.run(() {
      _filterState = _filterState.copyWith(searchQuery: query);
      _applyFilters();
    });
  }

  /// Clear search
  void clearSearch() {
    _filterState = _filterState.copyWith(searchQuery: '');
    _applyFilters();
  }

  /// Load more meetups (pagination)
  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      await _fetchMeetups(reset: false);
    } catch (e) {
      debugPrint('Error loading more: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  /// Refresh data
  Future<void> refresh() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _updateUserLocation();
      await _fetchMeetups(reset: true);
      await _generateRecommendations();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggle view mode
  void toggleViewMode() {
    _viewMode = _viewMode == ViewMode.list ? ViewMode.map : ViewMode.list;
    notifyListeners();
  }

  /// Set view mode
  void setViewMode(ViewMode mode) {
    _viewMode = mode;
    notifyListeners();
  }

  /// Clear all filters
  Future<void> clearFilters() async {
    _filterState = FilterState.empty;
    await _filterService.clearFilterState();
    await refresh();
  }

  /// Toggle sport type filter
  void toggleSportType(MeetupType type) {
    final currentTypes = Set<MeetupType>.from(_filterState.sportTypes);
    if (currentTypes.contains(type)) {
      currentTypes.remove(type);
    } else {
      currentTypes.add(type);
    }
    applyFilters(_filterState.copyWith(sportTypes: currentTypes));
  }

  /// Set date range filter
  void setDateRange(DateRangeFilter dateRange) {
    applyFilters(_filterState.copyWith(dateRange: dateRange));
  }

  /// Set distance filter
  Future<void> setDistanceFilter(double? radiusKm) async {
    if (radiusKm == null) {
      applyFilters(_filterState.copyWith(clearDistance: true));
      return;
    }

    if (!_hasLocationPermission) {
      final granted = await requestLocationPermission();
      if (!granted) return;
    }

    if (_userLatitude != null && _userLongitude != null) {
      applyFilters(_filterState.copyWith(
        distance: DistanceFilter(
          radiusKm: radiusKm,
          userLatitude: _userLatitude!,
          userLongitude: _userLongitude!,
        ),
      ));
    }
  }

  /// Set participant filter
  void setParticipantFilter(ParticipantFilter filter) {
    applyFilters(_filterState.copyWith(participantFilter: filter));
  }

  /// Set sort order
  void setSortOrder(SortOrder order) {
    applyFilters(_filterState.copyWith(sortOrder: order));
  }

  /// Quick filter: Today
  void filterToday() {
    applyFilters(_filterState.copyWith(dateRange: DateRangeFilter.today));
  }

  /// Quick filter: This Week
  void filterThisWeek() {
    applyFilters(_filterState.copyWith(dateRange: DateRangeFilter.thisWeek));
  }

  /// Quick filter: Near Me
  Future<void> filterNearMe() async {
    await setDistanceFilter(DistanceFilter.nearby);
  }

  @override
  void dispose() {
    _searchDebouncer.dispose();
    super.dispose();
  }
}
