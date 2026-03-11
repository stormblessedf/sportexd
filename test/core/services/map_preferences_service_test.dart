import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sporsal/core/services/map_preferences_service.dart';
import 'package:sporsal/core/utils/map_style.dart';

void main() {
  group('MapPreferencesService migration and persistence', () {
    test('preserves saved style during migration', () async {
      SharedPreferences.setMockInitialValues({'map_style': 'dark'});

      final service = MapPreferencesService();
      await service.initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(service.currentStyle, MapStyleOption.dark);
      expect(prefs.getString('map_style'), MapStyleOption.dark.name);
      expect(prefs.getBool('map_style_migrated_v2'), isTrue);
    });

    test('defaults to cityNightGold when no saved style exists', () async {
      SharedPreferences.setMockInitialValues({});

      final service = MapPreferencesService();
      await service.initialize();

      final prefs = await SharedPreferences.getInstance();
      expect(service.currentStyle, MapStyleOption.cityNightGold);
      expect(prefs.getString('map_style'), MapStyleOption.cityNightGold.name);
      expect(prefs.getBool('map_style_migrated_v2'), isTrue);
    });

    test('setMapStyle persists selection and survives re-initialize', () async {
      SharedPreferences.setMockInitialValues({
        'map_style': MapStyleOption.cityNightGold.name,
        'map_style_migrated_v2': true,
      });

      final service = MapPreferencesService();
      await service.initialize();
      await service.setMapStyle(MapStyleOption.minimal);

      final reloaded = MapPreferencesService();
      await reloaded.initialize();

      expect(reloaded.currentStyle, MapStyleOption.minimal);
    });

    test(
      'routes City Night Gold through Mapbox runtime values when token exists',
      () async {
        SharedPreferences.setMockInitialValues({
          'map_style': MapStyleOption.cityNightGold.name,
          'map_style_migrated_v2': true,
        });

        final service = MapPreferencesService(
          mapboxTokenOverride: 'pk.test.token',
          mapboxStyleIdOverride: 'navigation-night-v1',
        );
        await service.initialize();

        expect(
          service.currentTileUrl,
          contains(
            'api.mapbox.com/styles/v1/mapbox/navigation-night-v1/tiles/256',
          ),
        );
        expect(service.currentSubdomains, isEmpty);
        expect(service.currentAttribution, MapTileUrls.mapboxAttribution);
        expect(service.tileColorFilter, isNull);
      },
    );

    test('uses CARTO fallback runtime values when no token exists', () async {
      SharedPreferences.setMockInitialValues({
        'map_style': MapStyleOption.cityNightGold.name,
        'map_style_migrated_v2': true,
      });

      final service = MapPreferencesService(mapboxTokenOverride: '');
      await service.initialize();

      expect(service.currentTileUrl, MapTileUrls.cartoVoyager);
      expect(service.currentSubdomains, MapTileUrls.cartoSubdomains);
      expect(service.currentAttribution, MapTileUrls.cartoAttribution);
      expect(service.tileColorFilter, isNotNull);
    });
  });
}
