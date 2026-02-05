import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:latlong2/latlong.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/meetup_service.dart';
import '../../../core/services/map_preferences_service.dart';
import '../../../core/utils/custom_marker_generator.dart';

class NearbyMeetupsMapScreen extends StatefulWidget {
  /// If true, shows without AppBar (for embedding in other screens)
  final bool embedded;

  const NearbyMeetupsMapScreen({
    super.key,
    this.embedded = false,
  });

  @override
  State<NearbyMeetupsMapScreen> createState() => _NearbyMeetupsMapScreenState();
}

class _NearbyMeetupsMapScreenState extends State<NearbyMeetupsMapScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  Map<String, MeetupModel> _meetupById = {};
  MeetupModel? _selectedMeetup;
  String? _selectedMarkerId;
  bool _isLoading = true;
  LatLng? _userLocation;
  final Set<MeetupType> _selectedFilters = {};
  bool _filterExpanded = false;
  List<MeetupModel> _allMeetups = [];
  double _currentZoom = 12;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final locationService = context.read<LocationService>();

    // Try to get user location
    final userLoc = await locationService.getCurrentLocation();
    if (userLoc != null) {
      _userLocation = LatLng(userLoc.latitude, userLoc.longitude);
    } else {
      // Default to Istanbul
      _userLocation = LatLng(
        LocationService.defaultLatitude,
        LocationService.defaultLongitude,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _buildMarkers(List<MeetupModel> meetups) {
    _allMeetups = meetups;
    final markers = <Marker>[];
    final meetupMap = <String, MeetupModel>{};

    // Filter meetups based on selected sport types
    final filteredMeetups = _selectedFilters.isEmpty
        ? meetups
        : meetups.where((m) => _selectedFilters.contains(m.type)).toList();

    for (final meetup in filteredMeetups) {
      if (!meetup.hasCoordinates) continue;

      final point = LatLng(meetup.latitude!, meetup.longitude!);
      meetupMap[meetup.id] = meetup;

      // Use custom sport-specific marker widgets with selection state
      final isSelected = _selectedMarkerId == meetup.id;
      final size = CustomMarkerGenerator.getSizeForZoom(
        selected: isSelected,
        zoom: _currentZoom,
      );

      markers.add(
        Marker(
          key: ValueKey(meetup.id),
          point: point,
          width: size.width,
          height: size.height,
          alignment: Alignment.center,
          child: MouseRegion(
            cursor: SystemMouseCursors.click,
            child: CustomMarkerGenerator.buildMarkerWidget(
              meetup.type,
              selected: isSelected,
              zoom: _currentZoom,
            ),
          ),
        ),
      );
    }

    setState(() {
      _markers = markers;
      _meetupById = meetupMap;
    });
  }

  void _onMarkerTap(MeetupModel meetup) {
    setState(() {
      _selectedMeetup = meetup;
      _selectedMarkerId = meetup.id;
    });
    // Rebuild markers to update selection state
    _buildMarkers(_allMeetups);
  }

  void _onClusterTap(List<Marker> markers) {
    if (markers.isEmpty) return;

    // Calculate bounds of all markers in cluster
    double minLat = double.infinity;
    double maxLat = double.negativeInfinity;
    double minLng = double.infinity;
    double maxLng = double.negativeInfinity;

    for (final marker in markers) {
      minLat = marker.point.latitude < minLat ? marker.point.latitude : minLat;
      maxLat = marker.point.latitude > maxLat ? marker.point.latitude : maxLat;
      minLng = marker.point.longitude < minLng ? marker.point.longitude : minLng;
      maxLng = marker.point.longitude > maxLng ? marker.point.longitude : maxLng;
    }

    // Add padding to bounds
    const padding = 0.002;
    final bounds = LatLngBounds(
      LatLng(minLat - padding, minLng - padding),
      LatLng(maxLat + padding, maxLng + padding),
    );

    // Fit map to show all markers in cluster
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(50),
      ),
    );
  }

  void _goToUserLocation() {
    if (_userLocation == null) return;

    _mapController.move(_userLocation!, 13);
  }

  void _onPositionChanged(MapPosition position, bool hasGesture) {
    if (position.zoom != null && position.zoom != _currentZoom) {
      _currentZoom = position.zoom!;
      // Rebuild markers with new zoom level
      if (_allMeetups.isNotEmpty) {
        _buildMarkers(_allMeetups);
      }
    }
  }

  void _onMapTap(TapPosition tapPosition, LatLng point) {
    setState(() {
      _selectedMeetup = null;
      _selectedMarkerId = null;
    });
    _buildMarkers(_allMeetups);
  }

  Widget _buildClusterMarker(List<Marker> markers) {
    // Get sport types in this cluster
    final sportTypes = <MeetupType>{};
    for (final marker in markers) {
      if (marker.key is ValueKey<String>) {
        final meetupId = (marker.key as ValueKey<String>).value;
        final meetup = _meetupById[meetupId];
        if (meetup != null) {
          sportTypes.add(meetup.type);
        }
      }
    }

    // Use primary color or first sport color
    final Color clusterColor;
    if (sportTypes.length == 1) {
      clusterColor = CustomMarkerGenerator.getSportColor(sportTypes.first);
    } else {
      clusterColor = const Color(0xFF13EC5B); // Sporsal primary green
    }

    return GestureDetector(
      onTap: () => _onClusterTap(markers),
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: clusterColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
              color: clusterColor.withValues(alpha: 0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${markers.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'etkinlik',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date, {DateTime? endDate}) {
    final startTime = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (endDate != null) {
      final endTime = '${endDate.hour.toString().padLeft(2, '0')}:${endDate.minute.toString().padLeft(2, '0')}';
      return '${date.day}/${date.month} $startTime - $endTime';
    }
    return '${date.day}/${date.month} $startTime';
  }

  @override
  Widget build(BuildContext context) {
    // For embedded mode, return just the map content
    if (widget.embedded) {
      return _buildMapContent(context, topPadding: 12);
    }

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.explore_rounded,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Yakındaki Buluşmalar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _goToUserLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: _buildMapContent(context, topPadding: MediaQuery.of(context).padding.top + 70),
    );
  }

  Widget _buildMapContent(BuildContext context, {required double topPadding}) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final mapPrefs = context.watch<MapPreferencesService>();

    return Stack(
      children: [
        // Map
        StreamBuilder<List<MeetupModel>>(
          stream: context.read<MeetupService>().getUpcomingMeetups(),
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _buildMarkers(snapshot.data!);
              });
            }

            return FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _userLocation ?? LatLng(
                  LocationService.defaultLatitude,
                  LocationService.defaultLongitude,
                ),
                initialZoom: 12,
                onPositionChanged: _onPositionChanged,
                onTap: _onMapTap,
              ),
              children: [
                TileLayer(
                  urlTemplate: mapPrefs.currentTileUrl,
                  subdomains: mapPrefs.currentSubdomains,
                  userAgentPackageName: 'com.sporsal.app',
                ),
                MarkerClusterLayerWidget(
                  options: MarkerClusterLayerOptions(
                    maxClusterRadius: 80,
                    size: const Size(56, 56),
                    markers: _markers,
                    builder: (context, markers) => _buildClusterMarker(markers),
                    zoomToBoundsOnClick: false,
                    spiderfyCluster: false,
                    onMarkerTap: (marker) {
                      if (marker.key is ValueKey<String>) {
                        final meetupId = (marker.key as ValueKey<String>).value;
                        final meetup = _meetupById[meetupId];
                        if (meetup != null) {
                          _onMarkerTap(meetup);
                        }
                      }
                    },
                  ),
                ),
              ],
            );
          },
        ),

        // Sport Type Filter Dropdown
        Positioned(
          top: topPadding,
          left: 12,
          child: _buildSportFilterDropdown(context),
        ),

        // Location button for embedded mode
        if (widget.embedded)
          Positioned(
            top: topPadding,
            right: 12,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Material(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: _goToUserLocation,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        Icons.my_location_rounded,
                        color: Theme.of(context).colorScheme.primary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Selected Meetup Card
        if (_selectedMeetup != null)
          Positioned(
            bottom: 24,
            left: 16,
            right: 16,
            child: _buildMeetupCard(_selectedMeetup!),
          ),
      ],
    );
  }

  Widget _buildSportFilterDropdown(BuildContext context) {
    final activeFilterCount = _selectedFilters.length;

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          constraints: BoxConstraints(
            maxWidth: _filterExpanded ? 200 : 160,
            maxHeight: _filterExpanded ? 320 : 48,
          ),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: activeFilterCount > 0
                  ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                  : Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header / Toggle Button
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => setState(() => _filterExpanded = !_filterExpanded),
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.filter_list_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          activeFilterCount > 0
                              ? 'Filtre ($activeFilterCount)'
                              : 'Spor Türü',
                          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        AnimatedRotation(
                          turns: _filterExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            Icons.keyboard_arrow_down_rounded,
                            size: 18,
                            color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Expandable Filter List
              if (_filterExpanded)
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Clear all button
                        if (_selectedFilters.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() => _selectedFilters.clear());
                                _buildMarkers(_allMeetups);
                              },
                              icon: const Icon(Icons.clear_all, size: 16),
                              label: const Text('Temizle'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            ),
                          ),
                        // Sport type filters
                        _buildFilterItem(MeetupType.football, 'Futbol'),
                        _buildFilterItem(MeetupType.basketball, 'Basketbol'),
                        _buildFilterItem(MeetupType.volleyball, 'Voleybol'),
                        _buildFilterItem(MeetupType.tennis, 'Tenis'),
                        _buildFilterItem(MeetupType.running, 'Koşu'),
                        _buildFilterItem(MeetupType.cycling, 'Bisiklet'),
                        _buildFilterItem(MeetupType.swimming, 'Yüzme'),
                        _buildFilterItem(MeetupType.yoga, 'Yoga'),
                        _buildFilterItem(MeetupType.fitness, 'Fitness'),
                        _buildFilterItem(MeetupType.other, 'Diğer'),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterItem(MeetupType type, String label) {
    final color = CustomMarkerGenerator.getSportColor(type);
    final icon = CustomMarkerGenerator.getSportIcon(type);
    final isSelected = _selectedFilters.contains(type);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedFilters.remove(type);
              } else {
                _selectedFilters.add(type);
              }
            });
            _buildMarkers(_allMeetups);
          },
          borderRadius: BorderRadius.circular(8),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? color.withValues(alpha: 0.4) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isSelected ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(icon, size: 14, color: color),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check_circle, size: 16, color: color),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetupCard(MeetupModel meetup) {
    final sportColor = CustomMarkerGenerator.getSportColor(meetup.type);

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.92),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: sportColor.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => context.push('/detail', extra: meetup),
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    // Image with sport color border
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: sportColor.withValues(alpha: 0.4),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: sportColor.withValues(alpha: 0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          meetup.imageUrl,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  sportColor.withValues(alpha: 0.2),
                                  sportColor.withValues(alpha: 0.1),
                                ],
                              ),
                            ),
                            child: Icon(
                              CustomMarkerGenerator.getSportIcon(meetup.type),
                              color: sportColor,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Sport badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  sportColor.withValues(alpha: 0.15),
                                  sportColor.withValues(alpha: 0.08),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: sportColor.withValues(alpha: 0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  CustomMarkerGenerator.getSportIcon(meetup.type),
                                  size: 14,
                                  color: sportColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  meetup.type.displayName,
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: sportColor,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            meetup.title,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              _buildInfoChip(
                                Icons.schedule_rounded,
                                _formatDate(meetup.date, endDate: meetup.endDate),
                              ),
                              const SizedBox(width: 10),
                              _buildInfoChip(
                                Icons.group_rounded,
                                '${meetup.currentParticipants}/${meetup.maxParticipants}',
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Arrow
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: sportColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: sportColor,
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 14,
          color: Theme.of(context).colorScheme.outline,
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
