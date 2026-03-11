import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/utils/map_style.dart';

void main() {
  group('MapTileUrls City Night Gold resolver', () {
    test('falls back to CARTO Voyager when token is empty', () {
      final url = MapTileUrls.resolveCityNightGoldTileUrl(tokenOverride: '');
      expect(url, MapTileUrls.cartoVoyager);
    });

    test('builds Mapbox URL when token exists', () {
      const token = 'pk.test.token';
      const styleId = 'navigation-night-v1';
      final url = MapTileUrls.resolveCityNightGoldTileUrl(
        tokenOverride: token,
        styleIdOverride: styleId,
      );

      expect(
        url,
        contains('api.mapbox.com/styles/v1/mapbox/$styleId/tiles/256'),
      );
      expect(url, contains('access_token=$token'));
    });

    test(
      'returns no subdomains with token, carto subdomains without token',
      () {
        final withToken = MapTileUrls.resolveCityNightGoldSubdomains(
          tokenOverride: 'pk.test.token',
        );
        final withoutToken = MapTileUrls.resolveCityNightGoldSubdomains(
          tokenOverride: '',
        );

        expect(withToken, isEmpty);
        expect(withoutToken, MapTileUrls.cartoSubdomains);
      },
    );

    test(
      'returns mapbox attribution with token, carto attribution without token',
      () {
        final withToken = MapTileUrls.resolveCityNightGoldAttribution(
          tokenOverride: 'pk.test.token',
        );
        final withoutToken = MapTileUrls.resolveCityNightGoldAttribution(
          tokenOverride: '',
        );

        expect(withToken, MapTileUrls.mapboxAttribution);
        expect(withoutToken, MapTileUrls.cartoAttribution);
      },
    );
  });
}
