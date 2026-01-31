import 'dart:convert';
import '../models/meetup_model.dart';

/// Date range filter types
enum DateRangeType { all, today, thisWeek, thisMonth, custom }

/// Participant availability filter
enum ParticipantFilter { any, hasSpace, almostFull }

/// Sort order options
enum SortOrder { intelligent, date, distance, popularity, newest }

/// View mode for discovery page
enum ViewMode { list, map }

/// Date range filter with presets and custom range
class DateRangeFilter {
  final DateRangeType type;
  final DateTime? customStart;
  final DateTime? customEnd;

  const DateRangeFilter({
    this.type = DateRangeType.all,
    this.customStart,
    this.customEnd,
  });

  /// Get start date based on filter type
  DateTime get startDate {
    final now = DateTime.now();
    switch (type) {
      case DateRangeType.all:
        return now;
      case DateRangeType.today:
        return DateTime(now.year, now.month, now.day);
      case DateRangeType.thisWeek:
        return DateTime(now.year, now.month, now.day);
      case DateRangeType.thisMonth:
        return DateTime(now.year, now.month, now.day);
      case DateRangeType.custom:
        return customStart ?? DateTime(now.year, now.month, now.day);
    }
  }

  /// Get end date based on filter type
  DateTime get endDate {
    final now = DateTime.now();
    switch (type) {
      case DateRangeType.all:
        return now.add(const Duration(days: 365));
      case DateRangeType.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateRangeType.thisWeek:
        return DateTime(now.year, now.month, now.day).add(const Duration(days: 7));
      case DateRangeType.thisMonth:
        return DateTime(now.year, now.month, now.day).add(const Duration(days: 30));
      case DateRangeType.custom:
        return customEnd ?? now.add(const Duration(days: 365));
    }
  }

  /// Check if date is within range (inclusive)
  bool isInRange(DateTime date) {
    return !date.isBefore(startDate) && !date.isAfter(endDate);
  }

  // Presets
  static const DateRangeFilter all = DateRangeFilter(type: DateRangeType.all);
  static const DateRangeFilter today = DateRangeFilter(type: DateRangeType.today);
  static const DateRangeFilter thisWeek = DateRangeFilter(type: DateRangeType.thisWeek);
  static const DateRangeFilter thisMonth = DateRangeFilter(type: DateRangeType.thisMonth);

  static DateRangeFilter custom(DateTime start, DateTime end) {
    return DateRangeFilter(
      type: DateRangeType.custom,
      customStart: start,
      customEnd: end,
    );
  }

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'customStart': customStart?.toIso8601String(),
        'customEnd': customEnd?.toIso8601String(),
      };

  factory DateRangeFilter.fromJson(Map<String, dynamic> json) {
    return DateRangeFilter(
      type: DateRangeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => DateRangeType.all,
      ),
      customStart: json['customStart'] != null
          ? DateTime.parse(json['customStart'])
          : null,
      customEnd: json['customEnd'] != null
          ? DateTime.parse(json['customEnd'])
          : null,
    );
  }

  DateRangeFilter copyWith({
    DateRangeType? type,
    DateTime? customStart,
    DateTime? customEnd,
  }) {
    return DateRangeFilter(
      type: type ?? this.type,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
    );
  }

  String get displayName {
    switch (type) {
      case DateRangeType.all:
        return 'Tümü';
      case DateRangeType.today:
        return 'Bugün';
      case DateRangeType.thisWeek:
        return 'Bu Hafta';
      case DateRangeType.thisMonth:
        return 'Bu Ay';
      case DateRangeType.custom:
        return 'Özel';
    }
  }
}

/// Distance filter with user location
class DistanceFilter {
  final double radiusKm;
  final double userLatitude;
  final double userLongitude;

  const DistanceFilter({
    required this.radiusKm,
    required this.userLatitude,
    required this.userLongitude,
  });

  // Preset distances
  static const double nearby = 5.0;
  static const double medium = 10.0;
  static const double far = 25.0;
  static const double veryFar = 50.0;

  Map<String, dynamic> toJson() => {
        'radiusKm': radiusKm,
        'userLatitude': userLatitude,
        'userLongitude': userLongitude,
      };

  factory DistanceFilter.fromJson(Map<String, dynamic> json) {
    return DistanceFilter(
      radiusKm: (json['radiusKm'] as num).toDouble(),
      userLatitude: (json['userLatitude'] as num).toDouble(),
      userLongitude: (json['userLongitude'] as num).toDouble(),
    );
  }

  DistanceFilter copyWith({
    double? radiusKm,
    double? userLatitude,
    double? userLongitude,
  }) {
    return DistanceFilter(
      radiusKm: radiusKm ?? this.radiusKm,
      userLatitude: userLatitude ?? this.userLatitude,
      userLongitude: userLongitude ?? this.userLongitude,
    );
  }
}

/// Main filter state containing all filter criteria
class FilterState {
  final Set<MeetupType> sportTypes;
  final DateRangeFilter dateRange;
  final DistanceFilter? distance;
  final ParticipantFilter participantFilter;
  final SortOrder sortOrder;
  final String searchQuery;

  const FilterState({
    this.sportTypes = const {},
    this.dateRange = const DateRangeFilter(),
    this.distance,
    this.participantFilter = ParticipantFilter.any,
    this.sortOrder = SortOrder.intelligent,
    this.searchQuery = '',
  });

  /// Check if any filters are active
  bool get hasActiveFilters {
    return sportTypes.isNotEmpty ||
        dateRange.type != DateRangeType.all ||
        distance != null ||
        participantFilter != ParticipantFilter.any;
  }

  /// Count active filters
  int get activeFilterCount {
    int count = 0;
    if (sportTypes.isNotEmpty) count++;
    if (dateRange.type != DateRangeType.all) count++;
    if (distance != null) count++;
    if (participantFilter != ParticipantFilter.any) count++;
    return count;
  }

  /// Create a copy with updated fields
  FilterState copyWith({
    Set<MeetupType>? sportTypes,
    DateRangeFilter? dateRange,
    DistanceFilter? distance,
    bool clearDistance = false,
    ParticipantFilter? participantFilter,
    SortOrder? sortOrder,
    String? searchQuery,
  }) {
    return FilterState(
      sportTypes: sportTypes ?? this.sportTypes,
      dateRange: dateRange ?? this.dateRange,
      distance: clearDistance ? null : (distance ?? this.distance),
      participantFilter: participantFilter ?? this.participantFilter,
      sortOrder: sortOrder ?? this.sortOrder,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Serialize to JSON (excludes search text)
  Map<String, dynamic> toJson() => {
        'sportTypes': sportTypes.map((e) => e.name).toList(),
        'dateRange': dateRange.toJson(),
        'distance': distance?.toJson(),
        'participantFilter': participantFilter.name,
        'sortOrder': sortOrder.name,
        // searchQuery is not persisted
      };

  /// Deserialize from JSON
  factory FilterState.fromJson(Map<String, dynamic> json) {
    return FilterState(
      sportTypes: (json['sportTypes'] as List<dynamic>?)
              ?.map((e) => MeetupType.values.firstWhere(
                    (t) => t.name == e,
                    orElse: () => MeetupType.other,
                  ))
              .toSet() ??
          {},
      dateRange: json['dateRange'] != null
          ? DateRangeFilter.fromJson(json['dateRange'])
          : const DateRangeFilter(),
      distance: json['distance'] != null
          ? DistanceFilter.fromJson(json['distance'])
          : null,
      participantFilter: ParticipantFilter.values.firstWhere(
        (e) => e.name == json['participantFilter'],
        orElse: () => ParticipantFilter.any,
      ),
      sortOrder: SortOrder.values.firstWhere(
        (e) => e.name == json['sortOrder'],
        orElse: () => SortOrder.intelligent,
      ),
      searchQuery: '',
    );
  }

  /// Serialize to JSON string
  String toJsonString() => jsonEncode(toJson());

  /// Deserialize from JSON string
  factory FilterState.fromJsonString(String jsonString) {
    return FilterState.fromJson(jsonDecode(jsonString));
  }

  /// Default/empty state
  static const FilterState empty = FilterState();
}

/// Meetup with calculated distance
class MeetupWithDistance {
  final MeetupModel meetup;
  final double? distanceKm;

  const MeetupWithDistance({
    required this.meetup,
    this.distanceKm,
  });

  /// Format distance for display
  String get formattedDistance {
    if (distanceKm == null) return '';
    if (distanceKm! < 1) {
      return '${(distanceKm! * 1000).round()} m';
    }
    return '${distanceKm!.toStringAsFixed(1)} km';
  }
}

/// Recommendation sections model
class RecommendationSections {
  final List<MeetupModel> forYou;
  final List<MeetupModel> trendingNearby;
  final List<MeetupModel> startingSoon;
  final List<MeetupModel> newEvents;

  const RecommendationSections({
    this.forYou = const [],
    this.trendingNearby = const [],
    this.startingSoon = const [],
    this.newEvents = const [],
  });

  bool get hasAnyRecommendations =>
      forYou.isNotEmpty ||
      trendingNearby.isNotEmpty ||
      startingSoon.isNotEmpty ||
      newEvents.isNotEmpty;
}
