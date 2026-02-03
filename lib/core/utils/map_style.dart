/// Map tile URLs for OpenStreetMap and CARTO basemaps
/// Used with flutter_map TileLayer
class MapTileUrls {
  /// Standard OpenStreetMap tiles
  static const String standard = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  /// CARTO Dark basemap - modern dark mode
  static const String cartoDark = 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}{r}.png';

  /// CARTO Light basemap - clean light theme
  static const String cartoLight = 'https://{s}.basemaps.cartocdn.com/light_all/{z}/{x}/{y}{r}.png';

  /// CARTO Voyager basemap - colorful, detailed style (recommended)
  static const String cartoVoyager = 'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}{r}.png';

  /// Default subdomains for OpenStreetMap
  static const List<String> defaultSubdomains = ['a', 'b', 'c'];

  /// Subdomains for CARTO tiles
  static const List<String> cartoSubdomains = ['a', 'b', 'c', 'd'];

  /// Attribution for OpenStreetMap
  static const String osmAttribution = '© OpenStreetMap contributors';

  /// Attribution for CARTO
  static const String cartoAttribution = '© OpenStreetMap contributors, © CARTO';
}
