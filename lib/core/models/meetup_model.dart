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
        return 'Yüzme';
      case MeetupType.running:
        return 'Koşu';
      case MeetupType.cycling:
        return 'Bisiklet';
      case MeetupType.hiking:
        return 'Doğa Yürüyüşü';
      case MeetupType.yoga:
        return 'Yoga';
      case MeetupType.fitness:
        return 'Fitness';
      case MeetupType.boxing:
        return 'Boks';
      case MeetupType.climbing:
        return 'Tırmanış';
      case MeetupType.skiing:
        return 'Kayak';
      case MeetupType.other:
        return 'Diğer';
    }
  }

  /// Bu etkinlik türü rota planlama destekliyor mu?
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
      'isFull': isFull,
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

  factory MeetupModel.mockFootball() {
    return MeetupModel(
      id: 'm1',
      title: 'Hafta Sonu 7vs7 Halı Saha',
      description: 'Dostluk maçı yapacağız, eksik oyuncular var. Kaleci lazım!',
      imageUrl: 'football.png',
      type: MeetupType.football,
      date: DateTime.now().add(const Duration(days: 2)),
      locationName: 'Caddebostan Sahil Spor',
      locationAddress: 'Caddebostan, Kadıköy/İstanbul',
      organizerId: 'mock_1',
      organizerName: 'Kaan Sportif',
      currentParticipants: 11,
      maxParticipants: 14,
    );
  }

  factory MeetupModel.mockYoga() {
    return MeetupModel(
      id: 'm2',
      title: 'Gün Batımında Yoga',
      description:
          'Zihnimizi boşaltmak ve esnemek için harika bir fırsat. Matınızı getirin.',
      imageUrl: 'yoga.png',
      type: MeetupType.yoga,
      date: DateTime.now().add(const Duration(days: 1)),
      locationName: 'Moda Sahili',
      locationAddress: 'Moda, Kadıköy/İstanbul',
      organizerId: 'mock_2',
      organizerName: 'Yoga Master',
      currentParticipants: 5,
      maxParticipants: 20,
    );
  }

  factory MeetupModel.mockTennis() {
    return MeetupModel(
      id: 'm3',
      title: 'Tenis Partneri Aranıyor',
      description:
          'Orta seviye tenis partneri arıyorum. Kort ücretini bölüşeceğiz.',
      imageUrl: 'tennis.png',
      type: MeetupType.tennis,
      date: DateTime.now().add(const Duration(days: 3)),
      locationName: 'Dalyan Tenis Kulübü',
      locationAddress: 'Fenerbahçe, Kadıköy',
      organizerId: 'mock_1',
      organizerName: 'Kaan Sportif',
      currentParticipants: 1,
      maxParticipants: 2,
    );
  }
}
