/// Map tile URLs for OpenStreetMap, CARTO and Mapbox styles.
///
/// City Night Gold uses Mapbox `navigation-night-v1` when
/// `MAPBOX_ACCESS_TOKEN` is provided via `--dart-define`.
/// If no token is available, it falls back to CARTO Voyager.
class MapTileUrls {
  /// Standard OpenStreetMap tiles.
  static const String standard =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// CARTO Dark basemap.
  static const String cartoDark =
      'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  /// CARTO Light basemap.
  static const String cartoLight =
      'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  /// CARTO Voyager basemap.
  static const String cartoVoyager =
      'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  /// Default subdomains for OpenStreetMap.
  static const List<String> defaultSubdomains = ['a', 'b', 'c'];

  /// Subdomains for CARTO tiles.
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// Attribution for OpenStreetMap.
  static const String osmAttribution = '(c) OpenStreetMap contributors';

  /// Attribution for CARTO.
  static const String cartoAttribution =
      '(c) OpenStreetMap contributors, (c) CARTO';

  /// Attribution for Mapbox.
  static const String mapboxAttribution =
      '(c) Mapbox, (c) OpenStreetMap contributors';

  /// Default Mapbox style for City Night Gold.
  static const String defaultMapboxStyleId = 'navigation-night-v1';

  static const String _mapboxAccessToken = String.fromEnvironment(
    'MAPBOX_ACCESS_TOKEN',
    defaultValue: '',
  );

  /// Whether a Mapbox access token is available at compile time.
  static bool get hasMapboxToken => _mapboxAccessToken.isNotEmpty;

  static const String _mapboxStyleId = String.fromEnvironment(
    'MAPBOX_STYLE_ID',
    defaultValue: defaultMapboxStyleId,
  );

  static String resolveCityNightGoldTileUrl({
    String? tokenOverride,
    String? styleIdOverride,
  }) {
    final token = (tokenOverride ?? _mapboxAccessToken).trim();
    if (token.isEmpty) {
      return cartoVoyager;
    }

    final styleIdCandidate = (styleIdOverride ?? _mapboxStyleId).trim();
    final styleId = styleIdCandidate.isEmpty
        ? defaultMapboxStyleId
        : styleIdCandidate;

    return 'https://api.mapbox.com/styles/v1/mapbox/$styleId/tiles/256/{z}/{x}/{y}@2x?access_token=$token';
  }

  static List<String> resolveCityNightGoldSubdomains({String? tokenOverride}) {
    final token = (tokenOverride ?? _mapboxAccessToken).trim();
    if (token.isEmpty) {
      return cartoSubdomains;
    }
    return const <String>[];
  }

  static String resolveCityNightGoldAttribution({String? tokenOverride}) {
    final token = (tokenOverride ?? _mapboxAccessToken).trim();
    if (token.isEmpty) {
      return cartoAttribution;
    }
    return mapboxAttribution;
  }
}
