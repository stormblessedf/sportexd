import 'package:cloud_firestore/cloud_firestore.dart';

class RatingModel {
  final String id;
  final String meetupId;
  final String raterId;
  final String ratedUserId;
  final double rating;
  final String? comment;
  final DateTime createdAt;
  final String? meetupTitle;
  final String? sportType;
  final String? raterName;
  final String? raterPhotoUrl;

  const RatingModel({
    required this.id,
    required this.meetupId,
    required this.raterId,
    required this.ratedUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
    this.meetupTitle,
    this.sportType,
    this.raterName,
    this.raterPhotoUrl,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'meetupId': meetupId,
      'raterId': raterId,
      'ratedUserId': ratedUserId,
      'rating': rating,
      'comment': comment,
      'createdAt': createdAt.toIso8601String(),
      'meetupTitle': meetupTitle,
      'sportType': sportType,
      'raterName': raterName,
      'raterPhotoUrl': raterPhotoUrl,
    };
  }

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    DateTime createdAt;
    final createdAtValue = json['createdAt'];
    if (createdAtValue is Timestamp) {
      createdAt = createdAtValue.toDate();
    } else if (createdAtValue is String) {
      createdAt = DateTime.tryParse(createdAtValue) ?? DateTime.now();
    } else {
      createdAt = DateTime.now();
    }

    return RatingModel(
      id: json['id'] ?? '',
      meetupId: json['meetupId'] ?? '',
      raterId: json['raterId'] ?? '',
      ratedUserId: json['ratedUserId'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'],
      createdAt: createdAt,
      meetupTitle: json['meetupTitle'],
      sportType: json['sportType'],
      raterName: json['raterName'],
      raterPhotoUrl: json['raterPhotoUrl'],
    );
  }

  RatingModel copyWith({
    String? id,
    String? meetupId,
    String? raterId,
    String? ratedUserId,
    double? rating,
    String? comment,
    DateTime? createdAt,
    String? meetupTitle,
    String? sportType,
    String? raterName,
    String? raterPhotoUrl,
  }) {
    return RatingModel(
      id: id ?? this.id,
      meetupId: meetupId ?? this.meetupId,
      raterId: raterId ?? this.raterId,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
      meetupTitle: meetupTitle ?? this.meetupTitle,
      sportType: sportType ?? this.sportType,
      raterName: raterName ?? this.raterName,
      raterPhotoUrl: raterPhotoUrl ?? this.raterPhotoUrl,
    );
  }
}
