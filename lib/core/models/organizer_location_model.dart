import 'package:cloud_firestore/cloud_firestore.dart';

/// Organizer's live GPS location during an active meetup.
/// Stored at: meetups/{meetupId}/organizer_location (single document)
class OrganizerLocationModel {
  final double latitude;
  final double longitude;
  final DateTime updatedAt;

  const OrganizerLocationModel({
    required this.latitude,
    required this.longitude,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory OrganizerLocationModel.fromJson(Map<String, dynamic> json) {
    DateTime updatedAt;
    final updatedAtValue = json['updatedAt'];
    if (updatedAtValue is Timestamp) {
      updatedAt = updatedAtValue.toDate();
    } else if (updatedAtValue is String) {
      updatedAt = DateTime.tryParse(updatedAtValue) ?? DateTime.now();
    } else {
      updatedAt = DateTime.now();
    }

    return OrganizerLocationModel(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      updatedAt: updatedAt,
    );
  }

  OrganizerLocationModel copyWith({
    double? latitude,
    double? longitude,
    DateTime? updatedAt,
  }) {
    return OrganizerLocationModel(
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrganizerLocationModel &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      latitude.hashCode ^ longitude.hashCode ^ updatedAt.hashCode;

  @override
  String toString() =>
      'OrganizerLocationModel(latitude: $latitude, longitude: $longitude, updatedAt: $updatedAt)';
}
