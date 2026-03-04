import 'venue_model.dart';

enum VenueEnvironment { all, indoor, outdoor }

enum VenueSortOrder { rating, distance, reviewCount }

class VenueFilterState {
  final VenueEnvironment environment;
  final Set<int> priceLevels;
  final double minRating;
  final double? maxDistanceKm;
  final bool onlyOpen;
  final VenueSortOrder sortOrder;

  const VenueFilterState({
    this.environment = VenueEnvironment.all,
    this.priceLevels = const {},
    this.minRating = 0.0,
    this.maxDistanceKm,
    this.onlyOpen = false,
    this.sortOrder = VenueSortOrder.rating,
  });

  static const VenueFilterState empty = VenueFilterState();

  int get activeFilterCount {
    int count = 0;
    if (environment != VenueEnvironment.all) count++;
    if (priceLevels.isNotEmpty) count++;
    if (minRating > 0.0) count++;
    if (maxDistanceKm != null) count++;
    if (onlyOpen) count++;
    if (sortOrder != VenueSortOrder.rating) count++;
    return count;
  }

  bool get hasActiveFilters => activeFilterCount > 0;

  bool matches(VenueModel venue, {double? distanceKm}) {
    if (onlyOpen && !venue.isOpen) return false;
    if (minRating > 0.0 && venue.rating < minRating) return false;
    if (priceLevels.isNotEmpty && !priceLevels.contains(venue.priceLevel)) {
      return false;
    }
    if (maxDistanceKm != null &&
        distanceKm != null &&
        distanceKm > maxDistanceKm!) {
      return false;
    }
    return true;
  }

  List<VenueModel> sort(
    List<VenueModel> venues, {
    double Function(VenueModel)? distanceCalculator,
  }) {
    final sorted = List<VenueModel>.from(venues);
    switch (sortOrder) {
      case VenueSortOrder.rating:
        sorted.sort((a, b) => b.rating.compareTo(a.rating));
      case VenueSortOrder.distance:
        if (distanceCalculator != null) {
          sorted.sort((a, b) =>
              distanceCalculator(a).compareTo(distanceCalculator(b)));
        }
      case VenueSortOrder.reviewCount:
        sorted.sort((a, b) => b.userRatingCount.compareTo(a.userRatingCount));
    }
    return sorted;
  }

  VenueFilterState copyWith({
    VenueEnvironment? environment,
    Set<int>? priceLevels,
    double? minRating,
    double? Function()? maxDistanceKm,
    bool? onlyOpen,
    VenueSortOrder? sortOrder,
  }) {
    return VenueFilterState(
      environment: environment ?? this.environment,
      priceLevels: priceLevels ?? this.priceLevels,
      minRating: minRating ?? this.minRating,
      maxDistanceKm:
          maxDistanceKm != null ? maxDistanceKm() : this.maxDistanceKm,
      onlyOpen: onlyOpen ?? this.onlyOpen,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'environment': environment.name,
      'priceLevels': priceLevels.toList(),
      'minRating': minRating,
      'maxDistanceKm': maxDistanceKm,
      'onlyOpen': onlyOpen,
      'sortOrder': sortOrder.name,
    };
  }

  factory VenueFilterState.fromJson(Map<String, dynamic> json) {
    return VenueFilterState(
      environment: VenueEnvironment.values.firstWhere(
        (e) => e.name == json['environment'],
        orElse: () => VenueEnvironment.all,
      ),
      priceLevels: (json['priceLevels'] as List?)
              ?.map((e) => (e as num).toInt())
              .toSet() ??
          {},
      minRating: (json['minRating'] as num?)?.toDouble() ?? 0.0,
      maxDistanceKm: (json['maxDistanceKm'] as num?)?.toDouble(),
      onlyOpen: json['onlyOpen'] ?? false,
      sortOrder: VenueSortOrder.values.firstWhere(
        (e) => e.name == json['sortOrder'],
        orElse: () => VenueSortOrder.rating,
      ),
    );
  }
}
