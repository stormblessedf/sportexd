/// A single autocomplete suggestion returned by the Places API.
///
/// Extracted from [PlacesService] so it can be imported without the
/// web-only `dart:js_interop` dependency.
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
