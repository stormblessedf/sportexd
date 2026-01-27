import 'package:cloud_firestore/cloud_firestore.dart';

enum MeetupType { football, yoga, tennis, basketball, running, other }

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

  const MeetupModel({
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
  });

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
    };
  }

  factory MeetupModel.fromJson(Map<String, dynamic> json) {
    return MeetupModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      type: MeetupType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => MeetupType.other,
      ),
      date: (json['date'] as Timestamp).toDate(),
      locationName: json['locationName'] ?? '',
      locationAddress: json['locationAddress'] ?? '',
      organizerId: json['organizerId'] ?? '',
      organizerName: json['organizerName'] ?? 'Unknown',
      organizerImageUrl: json['organizerImageUrl'],
      currentParticipants: json['currentParticipants'] ?? 0,
      maxParticipants: json['maxParticipants'] ?? 0,
      isFull: json['isFull'] ?? false,
      participantIds: List<String>.from(json['participantIds'] ?? []),
    );
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
