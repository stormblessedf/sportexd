import 'package:cloud_firestore/cloud_firestore.dart';
import 'position_slot.dart';
import 'route_data.dart';

enum MeetupType {
  football,
  basketball,
  volleyball,
  tennis,
  tableTennis,
  badminton,
  swimming,
  running,
  cycling,
  hiking,
  yoga,
  fitness,
  boxing,
  climbing,
  skiing,
  other,
}

extension MeetupTypeExtension on MeetupType {
  String get displayName {
    switch (this) {
      case MeetupType.football:
        return 'Futbol';
      case MeetupType.basketball:
        return 'Basketbol';
      case MeetupType.volleyball:
        return 'Voleybol';
      case MeetupType.tennis:
        return 'Tenis';
      case MeetupType.tableTennis:
        return 'Masa Tenisi';
      case MeetupType.badminton:
        return 'Badminton';
      case MeetupType.swimming:
        return 'YÃ¼zme';
      case MeetupType.running:
        return 'KoÅŸu';
      case MeetupType.cycling:
        return 'Bisiklet';
      case MeetupType.hiking:
        return 'DoÄŸa YÃ¼rÃ¼yÃ¼ÅŸÃ¼';
      case MeetupType.yoga:
        return 'Yoga';
      case MeetupType.fitness:
        return 'Fitness';
      case MeetupType.boxing:
        return 'Boks';
      case MeetupType.climbing:
        return 'TÄ±rmanÄ±ÅŸ';
      case MeetupType.skiing:
        return 'Kayak';
      case MeetupType.other:
        return 'DiÄŸer';
    }
  }

  /// Bu etkinlik tÃ¼rÃ¼ rota planlama destekliyor mu?
  bool get supportsRoute =>
      this == MeetupType.running ||
      this == MeetupType.cycling ||
      this == MeetupType.hiking;
}

class MeetupModel {
  final String id;
  final String title;
  final String description;
  final String rules;
  final String imageUrl;
  final MeetupType type;
  final DateTime date;
  final DateTime? endDate;
  final String locationName;
  final String locationAddress;
  final String organizerId;
  final String organizerName;
  final String? organizerImageUrl;
  final double? organizerRating;
  final int currentParticipants;
  final int maxParticipants;
  final bool hideFromFeedUntilAccepted;
  final bool isFull;
  final List<String> participantIds;
  final List<String> waitlistUserIds;
  final double? latitude;
  final double? longitude;
  final bool isOrganizerOnlyChat;
  final DateTime createdAt;

  // Football-specific fields (null = not a football meetup with teams)
  final String? teamFormat; // "4v4", "5v5", "6v6", "7v7"
  final String? formation; // "1-2-1-1"
  final List<PositionSlot>? teamASlots; // Team A position slots
  final List<PositionSlot>? teamBSlots; // Team B position slots

  // Route-specific fields (for running, cycling, hiking)
  final RouteData? routeData;

  bool get hasRoute => routeData != null && routeData!.isValid;
  bool get isRouteApplicable => type.supportsRoute;

  MeetupModel({
    required this.id,
    required this.title,
    required this.description,
    this.rules = '',
    required this.imageUrl,
    required this.type,
    required this.date,
    this.endDate,
    required this.locationName,
    required this.locationAddress,
    required this.organizerId,
    required this.organizerName,
    this.organizerImageUrl,
    this.organizerRating,
    required this.currentParticipants,
    required this.maxParticipants,
    this.hideFromFeedUntilAccepted = false,
    this.isFull = false,
    this.participantIds = const [],
    this.waitlistUserIds = const [],
    this.latitude,
    this.longitude,
    this.isOrganizerOnlyChat = false,
    DateTime? createdAt,
    this.teamFormat,
    this.formation,
    this.teamASlots,
    this.teamBSlots,
    this.routeData,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasCoordinates => latitude != null && longitude != null;

  int get availableSpots {
    final spots = maxParticipants - currentParticipants;
    return spots < 0 ? 0 : spots;
  }

  double get fillRatio {
    if (maxParticipants <= 0) return 0;
    return currentParticipants / maxParticipants;
  }

  String get participantState {
    return computeParticipantState(
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
    );
  }

  List<String> get searchKeywords => buildSearchKeywords(
        title: title,
        description: description,
        locationName: locationName,
        locationAddress: locationAddress,
        organizerName: organizerName,
        type: type,
      );

  /// Only swipe-created invite meetups may stay hidden until the invite is accepted.
  bool get isFeedVisible =>
      !hideFromFeedUntilAccepted || currentParticipants > 1;

  /// Is this a football meetup with team formations?
  bool get isFootballWithTeams =>
      type == MeetupType.football &&
      teamFormat != null &&
      formation != null &&
      teamASlots != null &&
      teamBSlots != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'rules': rules,
      'imageUrl': imageUrl,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'endDate': endDate != null ? Timestamp.fromDate(endDate!) : null,
      'locationName': locationName,
      'locationAddress': locationAddress,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerImageUrl': organizerImageUrl,
      'organizerRating': organizerRating,
      'currentParticipants': currentParticipants,
      'maxParticipants': maxParticipants,
      'hideFromFeedUntilAccepted': hideFromFeedUntilAccepted,
      'isFull': isFull,
      'participantState': participantState,
      'availableSpots': availableSpots,
      'searchKeywords': searchKeywords,
      'participantIds': participantIds,
      'waitlistUserIds': waitlistUserIds,
      'latitude': latitude,
      'longitude': longitude,
      'isOrganizerOnlyChat': isOrganizerOnlyChat,
      'createdAt': Timestamp.fromDate(createdAt),
      'teamFormat': teamFormat,
      'formation': formation,
      'teamASlots': teamASlots?.map((slot) => slot.toJson()).toList(),
      'teamBSlots': teamBSlots?.map((slot) => slot.toJson()).toList(),
      'routeData': routeData?.toJson(),
    };
  }

  factory MeetupModel.fromJson(Map<String, dynamic> json) {
    // Safely parse the date field
    DateTime parsedDate;
    final dateValue = json['date'];
    if (dateValue is Timestamp) {
      parsedDate = dateValue.toDate();
    } else if (dateValue is String) {
      parsedDate = DateTime.tryParse(dateValue) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return MeetupModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      rules: json['rules'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: MeetupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MeetupType.other,
      ),
      date: parsedDate,
      endDate: json['endDate'] != null ? _parseDateTime(json['endDate']) : null,
      locationName: json['locationName'] ?? '',
      locationAddress: json['locationAddress'] ?? '',
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? 'Unknown',
      organizerImageUrl: json['organizerImageUrl'],
      organizerRating: (json['organizerRating'] as num?)?.toDouble(),
      currentParticipants: json['currentParticipants'] ?? 0,
      maxParticipants: json['maxParticipants'] ?? 0,
      hideFromFeedUntilAccepted:
          json['hideFromFeedUntilAccepted'] == true,
      isFull: json['isFull'] ?? false,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      waitlistUserIds: List<String>.from(json['waitlistUserIds'] ?? []),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      isOrganizerOnlyChat: json['isOrganizerOnlyChat'] ?? false,
      createdAt: _parseDateTime(json['createdAt']),
      teamFormat: json['teamFormat'] as String?,
      formation: json['formation'] as String?,
      teamASlots: _parsePositionSlots(json['teamASlots']),
      teamBSlots: _parsePositionSlots(json['teamBSlots']),
      routeData: json['routeData'] != null
          ? RouteData.tryFromJson(json['routeData'] as Map<String, dynamic>)
          : null,
    );
  }

  static List<PositionSlot>? _parsePositionSlots(dynamic value) {
    if (value == null) return null;
    if (value is! List) return null;
    return value
        .map((item) => PositionSlot.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }

  static String computeParticipantState({
    required int currentParticipants,
    required int maxParticipants,
  }) {
    if (maxParticipants <= 0) return 'has_space';
    if (currentParticipants >= maxParticipants) return 'full';
    if (currentParticipants / maxParticipants >= 0.8) return 'almost_full';
    return 'has_space';
  }

/*
  static List<String> buildSearchKeywords({
    required String title,
    required String description,
    required String locationName,
    required String locationAddress,
    required String organizerName,
    required MeetupType type,
  }) {
    final rawText = [
      title,
      description,
      locationName,
      locationAddress,
      organizerName,
      type.name,
      type.displayName,
    ].join(' ');

    final normalized = rawText
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9Ã§ÄŸÄ±Ã¶ÅŸÃ¼\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().length >= 2)
        .map((token) => token.trim())
        .toSet()
        .toList()
      ..sort();

    return normalized;
  }

*/

  static List<String> buildSearchKeywords({
    required String title,
    required String description,
    required String locationName,
    required String locationAddress,
    required String organizerName,
    required MeetupType type,
  }) {
    final rawText = [
      title,
      description,
      locationName,
      locationAddress,
      organizerName,
      type.name,
      type.displayName,
    ].join(' ');

    final normalized = _normalizeSearchText(rawText)
        .split(RegExp(r'\s+'))
        .where((token) => token.trim().length >= 2)
        .map((token) => token.trim())
        .toSet()
        .toList()
      ..sort();

    return normalized;
  }

  static String _normalizeSearchText(String input) {
    var normalized = input.toLowerCase();
    const replacements = <String, String>{
      '\u00E7': 'c',
      '\u011F': 'g',
      '\u0131': 'i',
      'i\u0307': 'i',
      '\u00F6': 'o',
      '\u015F': 's',
      '\u00FC': 'u',
    };

    replacements.forEach((from, to) {
      normalized = normalized.replaceAll(from, to);
    });

    return normalized.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
  }

  factory MeetupModel.mockFootball() {
    return MeetupModel(
      id: 'm1',
      title: 'Hafta Sonu 7vs7 HalÄ± Saha',
      description: 'Dostluk maÃ§Ä± yapacaÄŸÄ±z, eksik oyuncular var. Kaleci lazÄ±m!',
      imageUrl: 'football.png',
      type: MeetupType.football,
      date: DateTime.now().add(const Duration(days: 2)),
      locationName: 'Caddebostan Sahil Spor',
      locationAddress: 'Caddebostan, KadÄ±kÃ¶y/Ä°stanbul',
      organizerId: 'mock_1',
      organizerName: 'Kaan Sportif',
      currentParticipants: 11,
      maxParticipants: 14,
    );
  }

  factory MeetupModel.mockYoga() {
    return MeetupModel(
      id: 'm2',
      title: 'GÃ¼n BatÄ±mÄ±nda Yoga',
      description:
          'Zihnimizi boÅŸaltmak ve esnemek iÃ§in harika bir fÄ±rsat. MatÄ±nÄ±zÄ± getirin.',
      imageUrl: 'yoga.png',
      type: MeetupType.yoga,
      date: DateTime.now().add(const Duration(days: 1)),
      locationName: 'Moda Sahili',
      locationAddress: 'Moda, KadÄ±kÃ¶y/Ä°stanbul',
      organizerId: 'mock_2',
      organizerName: 'Yoga Master',
      currentParticipants: 5,
      maxParticipants: 20,
    );
  }

  factory MeetupModel.mockTennis() {
    return MeetupModel(
      id: 'm3',
      title: 'Tenis Partneri AranÄ±yor',
      description:
          'Orta seviye tenis partneri arÄ±yorum. Kort Ã¼cretini bÃ¶lÃ¼ÅŸeceÄŸiz.',
      imageUrl: 'tennis.png',
      type: MeetupType.tennis,
      date: DateTime.now().add(const Duration(days: 3)),
      locationName: 'Dalyan Tenis KulÃ¼bÃ¼',
      locationAddress: 'FenerbahÃ§e, KadÄ±kÃ¶y',
      organizerId: 'mock_1',
      organizerName: 'Kaan Sportif',
      currentParticipants: 1,
      maxParticipants: 2,
    );
  }
}

