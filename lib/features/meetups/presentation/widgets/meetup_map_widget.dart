import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/widgets/styled_tile_layer.dart';
import '../../../../l10n/app_localizations.dart';
import 'map_error_widget.dart';

class MeetupMapWidget extends StatelessWidget {
  final double? latitude;
  final double? longitude;
  final String locationName;
  final String? locationAddress;
  final double height;
  final bool showOpenButton;

  const MeetupMapWidget({
    super.key,
    this.latitude,
    this.longitude,
    required this.locationName,
    this.locationAddress,
    this.height = 180,
    this.showOpenButton = true,
  });

  bool get hasCoordinates => latitude != null && longitude != null;

  Future<void> _openInMaps() async {
    if (!hasCoordinates) return;

    final query = Uri.encodeComponent('$latitude,$longitude');
    final googleMapsUrl = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$query',
    );

    if (await canLaunchUrl(googleMapsUrl)) {
      await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!hasCoordinates) {
      return MapErrorWidget(
        message: l10n.locationCoordinatesMissing,
        locationName: locationName,
      );
    }

    final position = LatLng(latitude!, longitude!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: position,
                initialZoom: 15,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.none,
                ),
              ),
              children: [
                const StyledTileLayer(),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: position,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFB84A2A),
                        size: 40,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        if (showOpenButton) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _openInMaps,
              icon: const Icon(Icons.open_in_new, size: 18),
              label: Text(l10n.openOnMap),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
