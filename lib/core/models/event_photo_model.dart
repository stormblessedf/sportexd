import 'package:cloud_firestore/cloud_firestore.dart';

class EventPhotoModel {
  final String id;
  final String meetupId;
  final String userId;
  final String userName;
  final String? userImageUrl;
  final String photoUrl;
  final DateTime createdAt;

  const EventPhotoModel({
    required this.id,
    required this.meetupId,
    required this.userId,
    required this.userName,
    this.userImageUrl,
    required this.photoUrl,
    required this.createdAt,
  });

  factory EventPhotoModel.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    final createdAtValue = json['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return EventPhotoModel(
      id: json['id'] ?? '',
      meetupId: json['meetupId'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userImageUrl: json['userImageUrl'],
      photoUrl: json['photoUrl'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetupId': meetupId,
      'userId': userId,
      'userName': userName,
      'userImageUrl': userImageUrl,
      'photoUrl': photoUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  EventPhotoModel copyWith({
    String? id,
    String? meetupId,
    String? userId,
    String? userName,
    String? userImageUrl,
    String? photoUrl,
    DateTime? createdAt,
  }) {
    return EventPhotoModel(
      id: id ?? this.id,
      meetupId: meetupId ?? this.meetupId,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userImageUrl: userImageUrl ?? this.userImageUrl,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventPhotoModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          meetupId == other.meetupId &&
          userId == other.userId &&
          userName == other.userName &&
          userImageUrl == other.userImageUrl &&
          photoUrl == other.photoUrl &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      id.hashCode ^
      meetupId.hashCode ^
      userId.hashCode ^
      userName.hashCode ^
      userImageUrl.hashCode ^
      photoUrl.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'EventPhotoModel(id: $id, meetupId: $meetupId, userId: $userId, userName: $userName, photoUrl: $photoUrl, createdAt: $createdAt)';
}
