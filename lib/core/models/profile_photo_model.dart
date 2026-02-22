import 'package:cloud_firestore/cloud_firestore.dart';

class ProfilePhotoModel {
  final String photoId;
  final String userId;
  final String photoUrl;
  final String storagePath;
  final DateTime createdAt;

  const ProfilePhotoModel({
    required this.photoId,
    required this.userId,
    required this.photoUrl,
    required this.storagePath,
    required this.createdAt,
  });

  factory ProfilePhotoModel.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    final createdAtValue = json['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return ProfilePhotoModel(
      photoId: json['photoId'] ?? '',
      userId: json['userId'] ?? '',
      photoUrl: json['photoUrl'] ?? '',
      storagePath: json['storagePath'] ?? '',
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'photoId': photoId,
      'userId': userId,
      'photoUrl': photoUrl,
      'storagePath': storagePath,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ProfilePhotoModel copyWith({
    String? photoId,
    String? userId,
    String? photoUrl,
    String? storagePath,
    DateTime? createdAt,
  }) {
    return ProfilePhotoModel(
      photoId: photoId ?? this.photoId,
      userId: userId ?? this.userId,
      photoUrl: photoUrl ?? this.photoUrl,
      storagePath: storagePath ?? this.storagePath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProfilePhotoModel &&
          runtimeType == other.runtimeType &&
          photoId == other.photoId &&
          userId == other.userId &&
          photoUrl == other.photoUrl &&
          storagePath == other.storagePath &&
          createdAt == other.createdAt;

  @override
  int get hashCode =>
      photoId.hashCode ^
      userId.hashCode ^
      photoUrl.hashCode ^
      storagePath.hashCode ^
      createdAt.hashCode;

  @override
  String toString() =>
      'ProfilePhotoModel(photoId: $photoId, userId: $userId, photoUrl: $photoUrl, storagePath: $storagePath, createdAt: $createdAt)';
}
