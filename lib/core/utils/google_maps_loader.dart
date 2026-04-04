import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'package:flutter/foundation.dart';
import 'package:web/web.dart' as web;

/// Loads Google Maps JavaScript API dynamically using the key from --dart-define.
///
/// Usage in build/run:
///   flutter run --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
///   flutter build web --dart-define=GOOGLE_MAPS_API_KEY=your_key_here
class GoogleMapsLoader {
  static const _apiKey = String.fromEnvironment('GOOGLE_MAPS_API_KEY');
  static const _scriptId = 'google-maps-javascript-api';
  static const _pollInterval = Duration(milliseconds: 100);
  static const _loadTimeout = Duration(seconds: 8);
  static Future<bool>? _loadingFuture;

  static bool get isConfigured => _apiKey.isNotEmpty;

  static bool get isPlacesReady => !kIsWeb || _hasPlacesLibrary();

  static Future<bool> load() {
    if (!kIsWeb) return Future.value(true);
    if (_hasPlacesLibrary()) return Future.value(true);
    if (_loadingFuture != null) return _loadingFuture!;

    if (_apiKey.isEmpty) {
      debugPrint(
        'WARNING: GOOGLE_MAPS_API_KEY not set. '
        'Run with --dart-define=GOOGLE_MAPS_API_KEY=your_key',
      );
      return Future.value(false);
    }

    _loadingFuture = _loadScriptAndWait();
    return _loadingFuture!;
  }

  static Future<bool> _loadScriptAndWait() async {
    final existingScript = web.document.getElementById(_scriptId);
    if (existingScript == null) {
      final script =
          web.document.createElement('script') as web.HTMLScriptElement;
      script.id = _scriptId;
      script.src =
          'https://maps.googleapis.com/maps/api/js?key=$_apiKey'
          '&libraries=places,geocoding,marker&v=weekly';
      script.async = true;
      web.document.head?.appendChild(script);
    }

    final deadline = DateTime.now().add(_loadTimeout);
    while (DateTime.now().isBefore(deadline)) {
      if (_hasPlacesLibrary()) {
        return true;
      }
      await Future.delayed(_pollInterval);
    }

    final ready = _hasPlacesLibrary();
    if (!ready) {
      _loadingFuture = null;
      debugPrint('GoogleMapsLoader: Places library did not become ready.');
    }
    return ready;
  }

  static bool _hasPlacesLibrary() {
    try {
      final google = _getProperty(_globalThis, 'google');
      final maps = _getProperty(google, 'maps');
      final places = _getProperty(maps, 'places');
      return _getProperty(places, 'AutocompleteSuggestion') != null &&
          _getProperty(places, 'Place') != null;
    } catch (_) {
      return false;
    }
  }

  static JSAny? _getProperty(JSAny? target, String key) {
    if (target == null || target.isUndefinedOrNull) {
      return null;
    }

    final value = (target as JSObject).getProperty(key.toJS);
    if (value == null || value.isUndefinedOrNull) {
      return null;
    }
    return value;
  }
}

@JS('globalThis')
external JSObject get _globalThis;
