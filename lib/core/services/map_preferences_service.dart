import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/map_style.dart';

/// Warm vintage filter applied when City Night Gold falls back to CARTO.
const ColorFilter _kWarmVintageFilter = ColorFilter.matrix(<double>[
  0.52,
  0.30,
  0.0,
  0.0,
  20,
  0.0,
  0.80,
  0.08,
  0.0,
  0,
  0.06,
  0.06,
  0.65,
  0.0,
  -5,
  0.0,
  0.0,
  0.0,
  1.0,
  0,
]);

enum MapStyleOption {
  cityNightGold(
    MapTileUrls.cartoVoyager,
    MapTileUrls.cartoSubdomains,
    MapTileUrls.cartoAttribution,
  ),
  enhanced(
    MapTileUrls.cartoVoyager,
    MapTileUrls.cartoSubdomains,
    MapTileUrls.cartoAttribution,
  ),
  dark(
    MapTileUrls.cartoDark,
    MapTileUrls.cartoSubdomains,
    MapTileUrls.cartoAttribution,
  ),
  light(
    MapTileUrls.cartoLight,
    MapTileUrls.cartoSubdomains,
    MapTileUrls.cartoAttribution,
  ),
  minimal(
    MapTileUrls.standard,
    MapTileUrls.defaultSubdomains,
    MapTileUrls.osmAttribution,
  );

  final String tileUrl;
  final List<String> subdomains;
  final String attribution;

  const MapStyleOption(this.tileUrl, this.subdomains, this.attribution);
}

class MapPreferencesService extends ChangeNotifier {
  static const String _mapStyleKey = 'map_style';
  static const String _mapStyleMigratedV2Key = 'map_style_migrated_v2';

  MapPreferencesService({
    String? mapboxTokenOverride,
    String? mapboxStyleIdOverride,
  }) : _mapboxTokenOverride = mapboxTokenOverride,
       _mapboxStyleIdOverride = mapboxStyleIdOverride;

  final String? _mapboxTokenOverride;
  final String? _mapboxStyleIdOverride;

  MapStyleOption _currentStyle = MapStyleOption.cityNightGold;
  bool _initialized = false;

  MapStyleOption get currentStyle => _currentStyle;

  bool get _usesMapboxForCityNightGold {
    final override = _mapboxTokenOverride;
    if (override != null) {
      return override.trim().isNotEmpty;
    }
    return MapTileUrls.hasMapboxToken;
  }

  String get currentTileUrl {
    if (_currentStyle == MapStyleOption.cityNightGold) {
      return MapTileUrls.resolveCityNightGoldTileUrl(
        tokenOverride: _mapboxTokenOverride,
        styleIdOverride: _mapboxStyleIdOverride,
      );
    }
    return _currentStyle.tileUrl;
  }

  List<String> get currentSubdomains {
    if (_currentStyle == MapStyleOption.cityNightGold) {
      return MapTileUrls.resolveCityNightGoldSubdomains(
        tokenOverride: _mapboxTokenOverride,
      );
    }
    return _currentStyle.subdomains;
  }

  String get currentAttribution {
    if (_currentStyle == MapStyleOption.cityNightGold) {
      return MapTileUrls.resolveCityNightGoldAttribution(
        tokenOverride: _mapboxTokenOverride,
      );
    }
    return _currentStyle.attribution;
  }

  bool get isInitialized => _initialized;

  ColorFilter? get tileColorFilter {
    if (_currentStyle == MapStyleOption.cityNightGold &&
        !_usesMapboxForCityNightGold) {
      return _kWarmVintageFilter;
    }
    return null;
  }

  MapStyleOption _styleFromName(String? savedStyle) {
    if (savedStyle == null) {
      return MapStyleOption.cityNightGold;
    }
    return MapStyleOption.values.firstWhere(
      (style) => style.name == savedStyle,
      orElse: () => MapStyleOption.cityNightGold,
    );
  }

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedStyle = prefs.getString(_mapStyleKey);
    _currentStyle = _styleFromName(savedStyle);

    final migratedV2 = prefs.getBool(_mapStyleMigratedV2Key) ?? false;
    if (!migratedV2) {
      await prefs.setString(_mapStyleKey, _currentStyle.name);
      await prefs.setBool(_mapStyleMigratedV2Key, true);
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setMapStyle(MapStyleOption style) async {
    if (_currentStyle == style) return;

    _currentStyle = style;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapStyleKey, style.name);
    await prefs.setBool(_mapStyleMigratedV2Key, true);

    notifyListeners();
  }
}
