import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import '../models/location_data.dart';

class PlaceAutocompleteResult {
  final String placeId;
  final String description;
  final String mainText;
  final String secondaryText;

  const PlaceAutocompleteResult({
    required this.placeId,
    required this.description,
    required this.mainText,
    required this.secondaryText,
  });
}

// AutocompleteSuggestion API
@JS('google.maps.places.AutocompleteSuggestion.fetchAutocompleteSuggestions')
external JSPromise _fetchAutocompleteSuggestions(JSObject request);

@JS()
extension type AutocompleteSuggestionsResponse._(JSObject _) implements JSObject {
  external JSArray? get suggestions;
}

@JS()
extension type AutocompleteSuggestion._(JSObject _) implements JSObject {
  external PlacePrediction get placePrediction;
}

@JS()
extension type PlacePrediction._(JSObject _) implements JSObject {
  external String get placeId;
  external FormattedText get text;
  external FormattedText get mainText;
  external FormattedText get secondaryText;
}

@JS()
extension type FormattedText._(JSObject _) implements JSObject {
  external String get text;
}

// Place API
@JS('google.maps.places.Place')
extension type PlaceJS._(JSObject _) implements JSObject {
  external factory PlaceJS(JSObject options);
  external String? get displayName;
  external String? get formattedAddress;
  external LatLngJS? get location;
  external JSPromise fetchFields(JSObject options);
}

@JS()
extension type LatLngJS._(JSObject _) implements JSObject {
  external double lat();
  external double lng();
}

// Helper to create JS objects
@JS('Object.create')
external JSObject _objectCreate(JSObject? proto);

@JS('Reflect.set')
external void _setProperty(JSObject obj, String key, JSAny? value);

JSObject _createJsObject(Map<String, dynamic> map) {
  final obj = _objectCreate(null);
  for (final entry in map.entries) {
    _setProperty(obj, entry.key, _toJsValue(entry.value));
  }
  return obj;
}

JSAny? _toJsValue(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.toJS;
  if (value is num) return value.toJS;
  if (value is bool) return value.toJS;
  if (value is List) {
    return value.map((e) => _toJsValue(e)).toList().toJS;
  }
  if (value is Map<String, dynamic>) {
    return _createJsObject(value);
  }
  return null;
}

class PlacesService {
  Future<List<PlaceAutocompleteResult>> getAutocomplete(String query) async {
    if (query.isEmpty || query.length < 2) return [];

    try {
      debugPrint('PlacesService: Fetching autocomplete for "$query"');

      final request = _createJsObject({
        'input': query,
        // No region restriction - works worldwide
      });

      final response = await _fetchAutocompleteSuggestions(request).toDart
          as AutocompleteSuggestionsResponse;

      final results = <PlaceAutocompleteResult>[];
      final suggestions = response.suggestions?.toDart;

      debugPrint('PlacesService: Got ${suggestions?.length ?? 0} suggestions');

      if (suggestions != null) {
        for (final item in suggestions) {
          try {
            final suggestion = item as AutocompleteSuggestion;
            final prediction = suggestion.placePrediction;
            results.add(PlaceAutocompleteResult(
              placeId: prediction.placeId,
              description: prediction.text.text,
              mainText: prediction.mainText.text,
              secondaryText: prediction.secondaryText.text,
            ));
          } catch (e) {
            debugPrint('PlacesService: Error parsing suggestion: $e');
          }
        }
      }

      return results;
    } catch (e) {
      debugPrint('PlacesService: Autocomplete error: $e');
      return [];
    }
  }

  Future<LocationData?> getPlaceDetails(String placeId) async {
    try {
      debugPrint('PlacesService: Fetching place details for "$placeId"');

      final placeOptions = _createJsObject({
        'id': placeId,
      });

      final place = PlaceJS(placeOptions);

      final fieldsOptions = _createJsObject({
        'fields': ['displayName', 'formattedAddress', 'location'],
      });

      await place.fetchFields(fieldsOptions).toDart;

      final location = place.location;
      if (location != null) {
        debugPrint('PlacesService: Got place details - ${place.displayName}');
        return LocationData(
          latitude: location.lat(),
          longitude: location.lng(),
          name: place.displayName,
          address: place.formattedAddress,
        );
      }

      debugPrint('PlacesService: No location found for place');
      return null;
    } catch (e) {
      debugPrint('PlacesService: Place details error: $e');
      return null;
    }
  }
}
