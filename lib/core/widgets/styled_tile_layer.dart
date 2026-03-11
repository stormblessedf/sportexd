import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:provider/provider.dart';

import '../services/map_preferences_service.dart';

/// A flutter_map-compatible tile layer that automatically applies the colour
/// filter defined by [MapPreferencesService.tileColorFilter].
///
/// Drop this widget in place of every bare [TileLayer] inside a [FlutterMap]
/// children list.  When no filter is active for the current style it renders
/// exactly like a plain [TileLayer].
class StyledTileLayer extends StatelessWidget {
  const StyledTileLayer({super.key});

  @override
  Widget build(BuildContext context) {
    final mapPrefs = context.watch<MapPreferencesService>();

    final tile = TileLayer(
      urlTemplate: mapPrefs.currentTileUrl,
      subdomains: mapPrefs.currentSubdomains,
      userAgentPackageName: 'com.sporsal.app',
    );

    final filter = mapPrefs.tileColorFilter;
    if (filter == null) return tile;

    return ColorFiltered(colorFilter: filter, child: tile);
  }
}
