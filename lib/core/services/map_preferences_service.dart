import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/map_style.dart';

enum MapStyleOption {
  enhanced('Sportif (Açık)', MapTileUrls.cartoVoyager, MapTileUrls.cartoSubdomains, MapTileUrls.cartoAttribution),
  dark('Gece Modu', MapTileUrls.cartoDark, MapTileUrls.cartoSubdomains, MapTileUrls.cartoAttribution),
  light('Klasik Açık', MapTileUrls.cartoLight, MapTileUrls.cartoSubdomains, MapTileUrls.cartoAttribution),
  minimal('Minimal', MapTileUrls.standard, MapTileUrls.defaultSubdomains, MapTileUrls.osmAttribution);

  final String displayName;
  final String tileUrl;
  final List<String> subdomains;
  final String attribution;

  const MapStyleOption(this.displayName, this.tileUrl, this.subdomains, this.attribution);
}

class MapPreferencesService extends ChangeNotifier {
  static const String _mapStyleKey = 'map_style';

  MapStyleOption _currentStyle = MapStyleOption.enhanced;
  bool _initialized = false;

  MapStyleOption get currentStyle => _currentStyle;
  String get currentTileUrl => _currentStyle.tileUrl;
  List<String> get currentSubdomains => _currentStyle.subdomains;
  String get currentAttribution => _currentStyle.attribution;
  bool get isInitialized => _initialized;

  Future<void> initialize() async {
    if (_initialized) return;

    final prefs = await SharedPreferences.getInstance();
    final savedStyle = prefs.getString(_mapStyleKey);

    if (savedStyle != null) {
      _currentStyle = MapStyleOption.values.firstWhere(
        (style) => style.name == savedStyle,
        orElse: () => MapStyleOption.enhanced,
      );
    }

    _initialized = true;
    notifyListeners();
  }

  Future<void> setMapStyle(MapStyleOption style) async {
    if (_currentStyle == style) return;

    _currentStyle = style;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_mapStyleKey, style.name);

    notifyListeners();
  }
}
