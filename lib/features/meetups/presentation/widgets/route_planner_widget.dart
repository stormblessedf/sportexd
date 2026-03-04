import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/location_data.dart';
import '../../../../core/models/meetup_model.dart';
import '../../../../core/models/route_data.dart';
import '../../../../core/services/location_service.dart';
import '../../../../core/services/map_preferences_service.dart';
import '../../../../core/services/routing_service.dart';
import '../../../../core/utils/route_distance_calculator.dart';

class RoutePlannerWidget extends StatefulWidget {
  final RouteData? initialRoute;
  final ValueChanged<RouteData?> onRouteChanged;
  final MeetupType? meetupType;

  const RoutePlannerWidget({
    super.key,
    this.initialRoute,
    required this.onRouteChanged,
    this.meetupType,
  });

  @override
  State<RoutePlannerWidget> createState() => _RoutePlannerWidgetState();
}

class _RoutePlannerWidgetState extends State<RoutePlannerWidget> {
  LocationData? _startPoint;
  LocationData? _endPoint;
  List<LocationData> _waypoints = [];
  final MapController _mapController = MapController();

  // OSRM'den gelen detaylı rota noktaları
  List<LatLng> _routeGeometry = [];
  double _osrmDistanceKm = 0;
  bool _isLoadingRoute = false;

  static const Color primary = Color(0xFF13EC5B);
  static const Color textDark = Color(0xFF0F172A);
  static const Color textMuted = Color(0xFF64748B);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color borderLight = Color(0xFFE2E8F0);

  String? _selectingPoint;

  @override
  void initState() {
    super.initState();
    if (widget.initialRoute != null) {
      _startPoint = widget.initialRoute!.startPoint;
      _endPoint = widget.initialRoute!.endPoint;
      _waypoints = List.from(widget.initialRoute!.waypoints);
      _osrmDistanceKm = widget.initialRoute!.totalDistanceKm;
      // Kayıtlı geometry varsa yükle
      if (widget.initialRoute!.hasGeometry) {
        _routeGeometry = widget.initialRoute!.routeGeometry
            .map((pair) => LatLng(pair[0], pair[1]))
            .toList();
      }
    }
  }

  /// OSRM'den gerçek yol rotası al
  Future<void> _fetchRoute() async {
    final coords = <LatLng>[];
    if (_startPoint != null) {
      coords.add(LatLng(_startPoint!.latitude, _startPoint!.longitude));
    }
    for (final wp in _waypoints) {
      coords.add(LatLng(wp.latitude, wp.longitude));
    }
    if (_endPoint != null) {
      coords.add(LatLng(_endPoint!.latitude, _endPoint!.longitude));
    }

    if (coords.length < 2) {
      setState(() {
        _routeGeometry = [];
        _osrmDistanceKm = 0;
      });
      _notifyRouteChanged();
      return;
    }

    setState(() => _isLoadingRoute = true);

    final result = await RoutingService.getRoute(
      coordinates: coords,
      meetupType: widget.meetupType,
    );

    if (mounted) {
      setState(() {
        _isLoadingRoute = false;
        if (result != null) {
          _routeGeometry = result.polylinePoints;
          _osrmDistanceKm = result.distanceKm;
        } else {
          // Fallback: düz çizgi
          _routeGeometry = coords;
          _osrmDistanceKm = RouteDistanceCalculator.totalDistance(
            coords.map((c) => LocationData(
              latitude: c.latitude,
              longitude: c.longitude,
            )).toList(),
          );
        }
      });
      _notifyRouteChanged();
      _fitBounds();
    }
  }

  void _notifyRouteChanged() {
    if (_startPoint == null) {
      widget.onRouteChanged(null);
      return;
    }

    // Geometry'yi [lat, lng] çiftleri olarak kaydet
    final geometryData = _routeGeometry
        .map((p) => [p.latitude, p.longitude])
        .toList();

    widget.onRouteChanged(RouteData(
      startPoint: _startPoint!,
      endPoint: _endPoint,
      waypoints: _waypoints,
      totalDistanceKm: _osrmDistanceKm,
      routeGeometry: geometryData,
    ));
  }

  Future<void> _onMapTap(TapPosition tapPosition, LatLng position) async {
    if (_selectingPoint == null) return;

    final locationService = context.read<LocationService>();
    final address = await locationService.getAddressFromCoordinates(
      position.latitude,
      position.longitude,
    );

    final locationData = LocationData(
      latitude: position.latitude,
      longitude: position.longitude,
      address: address,
      name: address,
    );

    setState(() {
      if (_selectingPoint == 'start') {
        _startPoint = locationData;
      } else if (_selectingPoint == 'end') {
        _endPoint = locationData;
      } else if (_selectingPoint == 'waypoint') {
        _waypoints.add(locationData);
      }
      _selectingPoint = null;
    });

    // Gerçek yol rotası al
    await _fetchRoute();
  }

  void _fitBounds() {
    // Rota geometry varsa onu kullan, yoksa node'ları
    final points = _routeGeometry.isNotEmpty
        ? _routeGeometry
        : _buildNodePoints();

    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
      );
    } else if (points.length == 1) {
      _mapController.move(points.first, 14);
    }
  }

  List<LatLng> _buildNodePoints() {
    final points = <LatLng>[];
    if (_startPoint != null) {
      points.add(LatLng(_startPoint!.latitude, _startPoint!.longitude));
    }
    for (final wp in _waypoints) {
      points.add(LatLng(wp.latitude, wp.longitude));
    }
    if (_endPoint != null) {
      points.add(LatLng(_endPoint!.latitude, _endPoint!.longitude));
    }
    return points;
  }

  void _removeWaypoint(int index) {
    setState(() {
      _waypoints.removeAt(index);
    });
    _fetchRoute();
  }

  @override
  Widget build(BuildContext context) {
    final mapPrefs = context.watch<MapPreferencesService>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Başlık
        Row(
          children: [
            const Icon(Icons.route, color: primary, size: 22),
            const SizedBox(width: 8),
            const Text(
              'Rota Planlama',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textDark,
              ),
            ),
            const Spacer(),
            if (_isLoadingRoute)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
              )
            else if (_osrmDistanceKm > 0)
              Text(
                RouteDistanceCalculator.formatDistance(_osrmDistanceKm),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),

        // Başlangıç noktası
        _buildPointSelector(
          label: 'Başlangıç Noktası',
          icon: Icons.trip_origin,
          color: primary,
          location: _startPoint,
          isSelecting: _selectingPoint == 'start',
          onTap: () {
            setState(() {
              _selectingPoint = _selectingPoint == 'start' ? null : 'start';
            });
          },
          onClear: () {
            setState(() {
              _startPoint = null;
              _routeGeometry = [];
              _osrmDistanceKm = 0;
            });
            _notifyRouteChanged();
          },
        ),
        const SizedBox(height: 8),

        // Ara noktalar
        ..._waypoints.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildWaypointChip(entry.key, entry.value),
          );
        }),

        // Ara nokta ekle butonu
        if (_startPoint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectingPoint =
                      _selectingPoint == 'waypoint' ? null : 'waypoint';
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectingPoint == 'waypoint' ? primary : borderLight,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_location_alt, size: 16,
                      color: _selectingPoint == 'waypoint' ? primary : textMuted),
                    const SizedBox(width: 6),
                    Text(
                      _selectingPoint == 'waypoint'
                          ? 'Haritaya dokunun...'
                          : 'Ara Nokta Ekle',
                      style: TextStyle(
                        fontSize: 12,
                        color: _selectingPoint == 'waypoint' ? primary : textMuted,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

        // Bitiş noktası
        _buildPointSelector(
          label: 'Bitiş Noktası',
          icon: Icons.location_on,
          color: Colors.red,
          location: _endPoint,
          isSelecting: _selectingPoint == 'end',
          onTap: () {
            setState(() {
              _selectingPoint = _selectingPoint == 'end' ? null : 'end';
            });
          },
          onClear: () {
            setState(() {
              _endPoint = null;
            });
            _fetchRoute();
          },
        ),
        const SizedBox(height: 16),

        // Seçim ipucu
        if (_selectingPoint != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.touch_app, size: 16, color: primary),
                  const SizedBox(width: 6),
                  Text(
                    _selectingPoint == 'start'
                        ? 'Başlangıç noktasını seçmek için haritaya dokunun'
                        : _selectingPoint == 'end'
                            ? 'Bitiş noktasını seçmek için haritaya dokunun'
                            : 'Ara nokta eklemek için haritaya dokunun',
                    style: const TextStyle(fontSize: 12, color: primary, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

        // Harita
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 220,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _startPoint != null
                        ? LatLng(_startPoint!.latitude, _startPoint!.longitude)
                        : const LatLng(LocationService.defaultLatitude, LocationService.defaultLongitude),
                    initialZoom: 13,
                    onTap: _onMapTap,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: mapPrefs.currentTileUrl,
                      subdomains: mapPrefs.currentSubdomains,
                      userAgentPackageName: 'com.sporsal.app',
                    ),
                    // Rota çizgisi - OSRM geometry veya düz çizgi
                    if (_routeGeometry.length >= 2)
                      PolylineLayer(
                        polylines: [
                          Polyline(
                            points: _routeGeometry,
                            color: primary,
                            strokeWidth: 4,
                          ),
                        ],
                      ),
                    MarkerLayer(markers: _buildMarkers()),
                  ],
                ),
                // Loading overlay
                if (_isLoadingRoute)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black12,
                      child: const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(color: primary),
                            SizedBox(height: 8),
                            Text('Rota hesaplanıyor...',
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    if (_startPoint != null) {
      markers.add(Marker(
        point: LatLng(_startPoint!.latitude, _startPoint!.longitude),
        width: 36, height: 36,
        child: const Icon(Icons.trip_origin, color: Color(0xFF13EC5B), size: 32),
      ));
    }
    for (int i = 0; i < _waypoints.length; i++) {
      final wp = _waypoints[i];
      markers.add(Marker(
        point: LatLng(wp.latitude, wp.longitude),
        width: 28, height: 28,
        child: GestureDetector(
          onLongPress: () => _removeWaypoint(i),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.orange,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text('${i + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
        ),
      ));
    }
    if (_endPoint != null) {
      markers.add(Marker(
        point: LatLng(_endPoint!.latitude, _endPoint!.longitude),
        width: 36, height: 36,
        child: const Icon(Icons.location_on, color: Colors.red, size: 32),
      ));
    }
    return markers;
  }

  Widget _buildPointSelector({
    required String label,
    required IconData icon,
    required Color color,
    required LocationData? location,
    required bool isSelecting,
    required VoidCallback onTap,
    required VoidCallback onClear,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelecting ? color.withValues(alpha: 0.08) : surfaceLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelecting ? color : borderLight,
            width: isSelecting ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                location?.name ?? location?.address ?? label,
                style: TextStyle(
                  fontSize: 13,
                  color: location != null ? textDark : textMuted,
                  fontWeight: location != null ? FontWeight.w500 : FontWeight.normal,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (location != null)
              GestureDetector(
                onTap: onClear,
                child: const Icon(Icons.close, size: 18, color: textMuted),
              )
            else if (isSelecting)
              const SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: primary),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointChip(int index, LocationData waypoint) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 20, height: 20,
            decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
            child: Center(
              child: Text('${index + 1}',
                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              waypoint.name ?? waypoint.address ?? 'Ara Nokta ${index + 1}',
              style: const TextStyle(fontSize: 12, color: textDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () => _removeWaypoint(index),
            child: const Icon(Icons.close, size: 16, color: Colors.orange),
          ),
        ],
      ),
    );
  }
}
