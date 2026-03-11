import 'dart:js_interop';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Loads Google Maps JavaScript API dynamically using the key from --dart-define.
///
/// Usage in build/run:
///   flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
///   flutter build web --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
class GoogleMapsLoader {
  static const _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  static void load() {
    if (!kIsWeb) return;
    if (_apiKey.isEmpty) {
      debugPrint(
        'WARNING: GOOGLE_MAPS_API_KEY not set. '
        'Run with --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
      return;
    }

    final script = web.document.createElement('script') as web.HTMLScriptElement;
    script.src =
        'https://maps.googleapis.com/maps/api/js?key=$_apiKey'
        '&libraries=places,geocoding,marker&v=weekly';
    script.async = true;
    web.document.head?.appendChild(script);
  }
}
