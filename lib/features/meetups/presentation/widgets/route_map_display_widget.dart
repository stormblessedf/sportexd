import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import '../../../../core/models/route_data.dart';
import '../../../../core/services/map_preferences_service.dart';
import '../../../../core/utils/route_distance_calculator.dart';

class RouteMapDisplayWidget extends StatefulWidget {
  final RouteData routeData;
  final double height;

  const RouteMapDisplayWidget({
    super.key,
    required this.routeData,
    this.height = 220,
  });

  @override
  State<RouteMapDisplayWidget> createState() => _RouteMapDisplayWidgetState();
}

class _RouteMapDisplayWidgetState extends State<RouteMapDisplayWidget> {
  final MapController _mapController = MapController();
  static const Color primary = Color(0xFF13EC5B);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fitBounds());
  }

  List<LatLng> get _polylinePoints {
    // OSRM geometry varsa onu kullan, yoksa node'lardan düz çizgi
    if (widget.routeData.hasGeometry) {
      return widget.routeData.routeGeometry
          .map((pair) => LatLng(pair[0], pair[1]))
          .toList();
    }
    return widget.routeData.allPoints
        .map((p) => LatLng(p.latitude, p.longitude))
        .toList();
  }

  void _fitBounds() {
    final points = _polylinePoints;
    if (points.length >= 2) {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(40)),
      );
    } else if (points.length == 1) {
      _mapController.move(points.first, 14);
    }
  }

  @override
  Widget build(BuildContext context) {
    final mapPrefs = context.watch<MapPreferencesService>();
    final polylinePoints = _polylinePoints;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Mesafe bilgisi
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            color: primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.route, size: 16, color: primary),
              const SizedBox(width: 6),
              Text(
                'Rota Mesafesi: ${RouteDistanceCalculator.formatDistance(widget.routeData.totalDistanceKm)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: primary,
                ),
              ),
            ],
          ),
        ),
        // Harita
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: widget.height,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: polylinePoints.isNotEmpty
                    ? polylinePoints.first
                    : const LatLng(41.0082, 28.9784),
                initialZoom: 13,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: mapPrefs.currentTileUrl,
                  subdomains: mapPrefs.currentSubdomains,
                  userAgentPackageName: 'com.sporsal.app',
                ),
                if (polylinePoints.length >= 2)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polylinePoints,
                        color: primary,
                        strokeWidth: 4,
                      ),
                    ],
                  ),
                MarkerLayer(markers: _buildMarkers()),
              ],
            ),
          ),
        ),
      ],
    );
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];
    final route = widget.routeData;

    markers.add(Marker(
      point: LatLng(route.startPoint.latitude, route.startPoint.longitude),
      width: 36, height: 36,
      child: const Icon(Icons.trip_origin, color: Color(0xFF13EC5B), size: 32),
    ));

    for (int i = 0; i < route.waypoints.length; i++) {
      final wp = route.waypoints[i];
      markers.add(Marker(
        point: LatLng(wp.latitude, wp.longitude),
        width: 24, height: 24,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.orange,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Center(
            child: Text('${i + 1}',
              style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ));
    }

    if (route.endPoint != null) {
      markers.add(Marker(
        point: LatLng(route.endPoint!.latitude, route.endPoint!.longitude),
        width: 36, height: 36,
        child: const Icon(Icons.location_on, color: Colors.red, size: 32),
      ));
    }

    return markers;
  }
}
