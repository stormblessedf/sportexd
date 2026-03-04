import 'dart:async';
import 'dart:js_interop';
import 'package:flutter/material.dart';
import '../models/location_data.dart';
import '../models/place_autocomplete_result.dart';

export '../models/place_autocomplete_result.dart';

// AutocompleteSuggestion API
@JS('google.maps.places.AutocompleteSuggestion.fetchAutocompleteSuggestions')
external JSPromise _fetchAutocompleteSuggestions(JSObject request);

// TextSearch API (Places New)
@JS('google.maps.places.Place.searchByText')
external JSPromise _textSearch(JSObject request);

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
  external String? get id;
  external String? get displayName;
  external String? get formattedAddress;
  external LatLngJS? get location;
  external double? get rating;
  external int? get userRatingCount;
  external JSAny? get priceLevel;
  external String? get internationalPhoneNumber;
  external PlaceOpeningHours? get currentOpeningHours;
  external JSArray? get photos;
  external JSArray? get reviews;
  external JSPromise fetchFields(JSObject options);
}

// TextSearch response
@JS()
extension type TextSearchResponse._(JSObject _) implements JSObject {
  external JSArray? get places;
}

@JS()
extension type PlacePhoto._(JSObject _) implements JSObject {
  external String getURI(JSObject options);
}

@JS()
extension type PlaceReview._(JSObject _) implements JSObject {
  external String? get authorAttribution;
  external double? get rating;
  external String? get text;
  external String? get relativePublishTimeDescription;
}

@JS()
extension type PlaceOpeningHours._(JSObject _) implements JSObject {
  external bool? get isOpen;
  external JSArray? get weekdayDescriptions;
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

  /// Searches nearby places by keyword around a location.
  Future<List<Map<String, dynamic>>> searchNearbyPlaces({
    required double lat,
    required double lng,
    required String keyword,
    int radius = 10000,
    int maxResults = 20,
  }) async {
    try {
      debugPrint(
          'PlacesService: searchNearbyPlaces "$keyword" at ($lat, $lng)');

      final request = _createJsObject({
        'textQuery': keyword,
        'fields': [
          'displayName',
          'formattedAddress',
          'location',
          'rating',
          'userRatingCount',
          'photos',
        ],
        'locationBias': _createJsObject({
          'center': _createJsObject({'lat': lat, 'lng': lng}),
          'radius': radius,
        }),
        'maxResultCount': maxResults,
      });

      final response = await _textSearch(request).toDart;
      final searchResponse = response as TextSearchResponse;
      final results = <Map<String, dynamic>>[];

      if (searchResponse.places != null) {
        final placesList = searchResponse.places!.toDart;
        for (final item in placesList) {
          try {
            final place = item as PlaceJS;
            final loc = place.location;
            results.add({
              'placeId': place.id ?? '',
              'name': place.displayName ?? '',
              'address': place.formattedAddress ?? '',
              'latitude': loc?.lat() ?? 0.0,
              'longitude': loc?.lng() ?? 0.0,
              'rating': place.rating ?? 0.0,
              'userRatingCount': place.userRatingCount ?? 0,
              'photoUrl': _extractFirstPhotoUrl(place.photos),
            });
          } catch (e) {
            debugPrint('PlacesService: Error parsing place result: $e');
          }
        }
      }

      debugPrint('PlacesService: Found ${results.length} nearby places');
      return results;
    } catch (e) {
      debugPrint('PlacesService: searchNearbyPlaces error: $e');
      return [];
    }
  }

  /// Fetches full details for a single place by ID.
  Future<Map<String, dynamic>?> getPlaceFullDetails(String placeId) async {
    if (placeId.isEmpty) return null;

    try {
      debugPrint('PlacesService: getPlaceFullDetails for "$placeId"');

      final placeOptions = _createJsObject({'id': placeId});
      final place = PlaceJS(placeOptions);

      final fieldsOptions = _createJsObject({
        'fields': [
          'displayName',
          'formattedAddress',
          'location',
          'rating',
          'userRatingCount',
          'priceLevel',
          'currentOpeningHours',
          'reviews',
          'photos',
          'internationalPhoneNumber',
        ],
      });

      await place.fetchFields(fieldsOptions).toDart;

      final loc = place.location;
      final openingHours = place.currentOpeningHours;

      // Parse weekday descriptions
      final weekdayHours = <String>[];
      if (openingHours?.weekdayDescriptions != null) {
        for (final desc in openingHours!.weekdayDescriptions!.toDart) {
          weekdayHours.add((desc as JSAny).toString());
        }
      }

      // Parse reviews
      final reviewsList = <Map<String, dynamic>>[];
      if (place.reviews != null) {
        for (final item in place.reviews!.toDart) {
          try {
            final review = item as PlaceReview;
            reviewsList.add({
              'authorName': review.authorAttribution ?? '',
              'rating': review.rating ?? 0.0,
              'text': review.text ?? '',
              'relativeTime': review.relativePublishTimeDescription ?? '',
            });
          } catch (e) {
            debugPrint('PlacesService: Error parsing review: $e');
          }
        }
      }

      // Parse photo URLs
      final photoUrls = <String>[];
      if (place.photos != null) {
        for (final item in place.photos!.toDart) {
          try {
            final photo = item as PlacePhoto;
            photoUrls.add(getPhotoUrl(photo));
          } catch (e) {
            debugPrint('PlacesService: Error parsing photo: $e');
          }
        }
      }

      // Parse price level
      int priceLevel = 0;
      if (place.priceLevel != null) {
        final priceLevelStr = place.priceLevel.toString();
        // Google Places API (New) returns price level as string enum
        const priceLevelMap = {
          'FREE': 0,
          'INEXPENSIVE': 1,
          'MODERATE': 2,
          'EXPENSIVE': 3,
          'VERY_EXPENSIVE': 4,
        };
        priceLevel = priceLevelMap[priceLevelStr] ?? 0;
      }

      debugPrint('PlacesService: Got full details - ${place.displayName}');
      return {
        'placeId': placeId,
        'name': place.displayName ?? '',
        'address': place.formattedAddress ?? '',
        'latitude': loc?.lat() ?? 0.0,
        'longitude': loc?.lng() ?? 0.0,
        'rating': place.rating ?? 0.0,
        'userRatingCount': place.userRatingCount ?? 0,
        'priceLevel': priceLevel,
        'isOpen': openingHours?.isOpen ?? false,
        'weekdayHours': weekdayHours,
        'phoneNumber': place.internationalPhoneNumber ?? '',
        'photoUrls': photoUrls,
        'reviews': reviewsList,
      };
    } catch (e) {
      debugPrint('PlacesService: getPlaceFullDetails error: $e');
      return null;
    }
  }

  /// Creates a photo URL from a PlacePhoto reference.
  String getPhotoUrl(dynamic photoRef, {int maxWidth = 800}) {
    try {
      final photo = photoRef as PlacePhoto;
      final options = _createJsObject({'maxWidthPx': maxWidth});
      return photo.getURI(options);
    } catch (e) {
      debugPrint('PlacesService: getPhotoUrl error: $e');
      return '';
    }
  }

  String _extractFirstPhotoUrl(JSArray? photos) {
    if (photos == null) return '';
    final photoList = photos.toDart;
    if (photoList.isEmpty) return '';
    try {
      final photo = photoList.first as PlacePhoto;
      return getPhotoUrl(photo);
    } catch (e) {
      return '';
    }
  }
}
