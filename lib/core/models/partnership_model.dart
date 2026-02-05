import 'package:cloud_firestore/cloud_firestore.dart';

enum PartnershipStatus { pending, accepted, rejected, blocked }

class PartnershipModel {
  final String id;
  final String userId; // Requester
  final String partnerId; // Receiver
  final PartnershipStatus status;
  final List<String> sharedMeetupIds;
  final DateTime requestedAt;
  final DateTime? respondedAt;
  final DateTime createdAt;

  const PartnershipModel({
    required this.id,
    required this.userId,
    required this.partnerId,
    required this.status,
    required this.sharedMeetupIds,
    required this.requestedAt,
    this.respondedAt,
    required this.createdAt,
  });

  /// Generate consistent partnership ID from two user IDs
  static String generateId(String uid1, String uid2) {
    return uid1.compareTo(uid2) < 0 ? '${uid1}_$uid2' : '${uid2}_$uid1';
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'partnerId': partnerId,
      'status': status.name,
      'sharedMeetupIds': sharedMeetupIds,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'respondedAt': respondedAt != null ? Timestamp.fromDate(respondedAt!) : null,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  factory PartnershipModel.fromJson(Map<String, dynamic> json) {
    return PartnershipModel(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      partnerId: json['partnerId'] ?? '',
      status: PartnershipStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => PartnershipStatus.pending,
      ),
      sharedMeetupIds: (json['sharedMeetupIds'] as List<dynamic>?)?.cast<String>() ?? [],
      requestedAt: _parseDateTime(json['requestedAt']),
      respondedAt: json['respondedAt'] != null ? _parseDateTime(json['respondedAt']) : null,
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.parse(value);
    return DateTime.now();
  }

  PartnershipModel copyWith({
    String? id,
    String? userId,
    String? partnerId,
    PartnershipStatus? status,
    List<String>? sharedMeetupIds,
    DateTime? requestedAt,
    DateTime? respondedAt,
    DateTime? createdAt,
  }) {
    return PartnershipModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      partnerId: partnerId ?? this.partnerId,
      status: status ?? this.status,
      sharedMeetupIds: sharedMeetupIds ?? this.sharedMeetupIds,
      requestedAt: requestedAt ?? this.requestedAt,
      respondedAt: respondedAt ?? this.respondedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Get the other user's ID given one user's ID
  String getOtherUserId(String myUserId) {
    return myUserId == userId ? partnerId : userId;
  }

  /// Check if a user is involved in this partnership
  bool involvesUser(String uid) => userId == uid || partnerId == uid;
}
