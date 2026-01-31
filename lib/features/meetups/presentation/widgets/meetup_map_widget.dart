import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/map_style.dart';
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
    if (!hasCoordinates) {
      return MapErrorWidget(
        message: 'Konum koordinatı bulunamadı',
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
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: position,
                zoom: 15,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('meetup_location'),
                  position: position,
                  infoWindow: InfoWindow(title: locationName),
                ),
              },
              style: MapStyle.minimalStyle,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
              scrollGesturesEnabled: false,
              zoomGesturesEnabled: false,
              rotateGesturesEnabled: false,
              tiltGesturesEnabled: false,
              liteModeEnabled: true,
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
              label: const Text('Haritada Aç'),
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
