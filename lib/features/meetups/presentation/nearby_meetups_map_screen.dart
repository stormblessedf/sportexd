import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../core/models/meetup_model.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/meetup_service.dart';
import '../../../core/utils/map_style.dart';
import '../../../core/utils/custom_marker_generator.dart';

class NearbyMeetupsMapScreen extends StatefulWidget {
  const NearbyMeetupsMapScreen({super.key});

  @override
  State<NearbyMeetupsMapScreen> createState() => _NearbyMeetupsMapScreenState();
}

class _NearbyMeetupsMapScreenState extends State<NearbyMeetupsMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  MeetupModel? _selectedMeetup;
  bool _isLoading = true;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    final locationService = context.read<LocationService>();

    // Initialize custom markers
    await CustomMarkerGenerator.initialize();

    // Try to get user location
    final userLoc = await locationService.getCurrentLocation();
    if (userLoc != null) {
      _userLocation = LatLng(userLoc.latitude, userLoc.longitude);
    } else {
      // Default to Istanbul
      _userLocation = const LatLng(
        LocationService.defaultLatitude,
        LocationService.defaultLongitude,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  void _buildMarkers(List<MeetupModel> meetups) {
    final markers = <Marker>{};

    for (final meetup in meetups) {
      if (!meetup.hasCoordinates) continue;

      // Use custom sport-specific marker icons
      final markerIcon = CustomMarkerGenerator.getMarker(meetup.type);

      markers.add(
        Marker(
          markerId: MarkerId(meetup.id),
          position: LatLng(meetup.latitude!, meetup.longitude!),
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: meetup.title,
            snippet: meetup.locationName,
          ),
          onTap: () {
            setState(() => _selectedMeetup = meetup);
          },
        ),
      );
    }

    setState(() => _markers = markers);
  }

  void _goToUserLocation() {
    if (_userLocation == null || _mapController == null) return;

    _mapController!.animateCamera(
      CameraUpdate.newLatLngZoom(_userLocation!, 13),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yakındaki Buluşmalar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _goToUserLocation,
            tooltip: 'Konumuma Git',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
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

                    return GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: _userLocation ?? const LatLng(
                          LocationService.defaultLatitude,
                          LocationService.defaultLongitude,
                        ),
                        zoom: 12,
                      ),
                      onMapCreated: (controller) => _mapController = controller,
                      markers: _markers,
                      style: MapStyle.sportStyle,
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onTap: (_) {
                        setState(() => _selectedMeetup = null);
                      },
                    );
                  },
                ),

                // Legend
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildLegendItem('Futbol', const Color(0xFF13EC5B), Icons.sports_soccer),
                        _buildLegendItem('Basketbol', const Color(0xFFFF6B35), Icons.sports_basketball),
                        _buildLegendItem('Tenis', const Color(0xFFFFD93D), Icons.sports_tennis),
                        _buildLegendItem('Yoga', const Color(0xFF9B59B6), Icons.self_improvement),
                        _buildLegendItem('Koşu', const Color(0xFF3498DB), Icons.directions_run),
                        _buildLegendItem('Diğer', const Color(0xFFE74C3C), Icons.sports),
                      ],
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
            ),
    );
  }

  Widget _buildLegendItem(String label, Color color, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getSportIcon(MeetupType type) {
    switch (type) {
      case MeetupType.football:
        return Icons.sports_soccer;
      case MeetupType.basketball:
        return Icons.sports_basketball;
      case MeetupType.tennis:
        return Icons.sports_tennis;
      case MeetupType.yoga:
        return Icons.self_improvement;
      case MeetupType.running:
        return Icons.directions_run;
      case MeetupType.other:
        return Icons.sports;
    }
  }

  Widget _buildMeetupCard(MeetupModel meetup) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: () => context.push('/detail', extra: meetup),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  meetup.imageUrl,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 80,
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.sports),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _getSportIcon(meetup.type),
                            size: 12,
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            meetup.type.displayName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
                              fontWeight: FontWeight.bold,
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
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDate(meetup.date),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(width: 12),
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${meetup.currentParticipants}/${meetup.maxParticipants}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Arrow
              Icon(
                Icons.chevron_right,
                color: Theme.of(context).colorScheme.outline,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
