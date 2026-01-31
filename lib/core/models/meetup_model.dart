import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetupType { football, yoga, tennis, basketball, running, other }

extension MeetupTypeExtension on MeetupType {
  String get displayName {
    switch (this) {
      case MeetupType.football:
        return 'Futbol';
      case MeetupType.basketball:
        return 'Basketbol';
      case MeetupType.tennis:
        return 'Tenis';
      case MeetupType.yoga:
        return 'Yoga';
      case MeetupType.running:
        return 'Koşu';
      case MeetupType.other:
        return 'Diğer';
    }
  }
}

class MeetupModel {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final MeetupType type;
  final DateTime date;
  final String locationName;
  final String locationAddress;
  final String organizerId;
  final String organizerName;
  final String? organizerImageUrl;
  final int currentParticipants;
  final int maxParticipants;
  final bool isFull;
  final List<String> participantIds;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;

  MeetupModel({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.type,
    required this.date,
    required this.locationName,
    required this.locationAddress,
    required this.organizerId,
    required this.organizerName,
    this.organizerImageUrl,
    required this.currentParticipants,
    required this.maxParticipants,
    this.isFull = false,
    this.participantIds = const [],
    this.latitude,
    this.longitude,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get hasCoordinates => latitude != null && longitude != null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'imageUrl': imageUrl,
      'type': type.name,
      'date': Timestamp.fromDate(date),
      'locationName': locationName,
      'locationAddress': locationAddress,
      'organizerId': organizerId,
      'organizerName': organizerName,
      'organizerImageUrl': organizerImageUrl,
      'currentParticipants': currentParticipants,
      'maxParticipants': maxParticipants,
      'isFull': isFull,
      'participantIds': participantIds,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': Timestamp.fromDate(createdAt),
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
      imageUrl: json['imageUrl'] ?? '',
      type: MeetupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MeetupType.other,
      ),
      date: parsedDate,
      locationName: json['locationName'] ?? '',
      locationAddress: json['locationAddress'] ?? '',
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? 'Unknown',
      organizerImageUrl: json['organizerImageUrl'],
      currentParticipants: json['currentParticipants'] ?? 0,
      maxParticipants: json['maxParticipants'] ?? 0,
      isFull: json['isFull'] ?? false,
      participantIds: List<String>.from(json['participantIds'] ?? []),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      createdAt: _parseDateTime(json['createdAt']),
    );
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
