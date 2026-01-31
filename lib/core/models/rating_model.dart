class RatingModel {
  final String id;
  final String meetupId;
  final String raterId;
  final String ratedUserId;
  final double rating;
  final String? comment;
  final DateTime createdAt;

  const RatingModel({
    required this.id,
    required this.meetupId,
    required this.raterId,
    required this.ratedUserId,
    required this.rating,
    this.comment,
    required this.createdAt,
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
    };
  }

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? '',
      meetupId: json['meetupId'] ?? '',
      raterId: json['raterId'] ?? '',
      ratedUserId: json['ratedUserId'] ?? '',
      rating: (json['rating'] ?? 0.0).toDouble(),
      comment: json['comment'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
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
  }) {
    return RatingModel(
      id: id ?? this.id,
      meetupId: meetupId ?? this.meetupId,
      raterId: raterId ?? this.raterId,
      ratedUserId: ratedUserId ?? this.ratedUserId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
