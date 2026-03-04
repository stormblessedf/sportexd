import 'meetup_model.dart';

class VenueReview {
  final String authorName;
  final double rating;
  final String text;
  final String relativeTime;

  const VenueReview({
    this.authorName = '',
    this.rating = 0.0,
    this.text = '',
    this.relativeTime = '',
  });

  factory VenueReview.fromJson(Map<String, dynamic> json) {
    return VenueReview(
      authorName: json['authorName'] ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      text: json['text'] ?? '',
      relativeTime: json['relativeTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'authorName': authorName,
      'rating': rating,
      'text': text,
      'relativeTime': relativeTime,
    };
  }
}

class VenueModel {
  final String placeId;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double rating;
  final int userRatingCount;
  final int priceLevel;
  final bool isOpen;
  final List<String> weekdayHours;
  final String phoneNumber;
  final List<String> photoUrls;
  final List<VenueReview> reviews;
  final MeetupType? sportType;

  const VenueModel({
    required this.placeId,
    this.name = '',
    this.address = '',
    this.latitude = 0.0,
    this.longitude = 0.0,
    this.rating = 0.0,
    this.userRatingCount = 0,
    this.priceLevel = 0,
    this.isOpen = false,
    this.weekdayHours = const [],
    this.phoneNumber = '',
    this.photoUrls = const [],
    this.reviews = const [],
    this.sportType,
  });

  factory VenueModel.fromPlacesResponse(Map<String, dynamic> data) {
    final location = data['location'] as Map<String, dynamic>?;
    final reviewsList = data['reviews'] as List?;

    return VenueModel(
      placeId: data['placeId'] ?? '',
      name: data['displayName'] ?? data['name'] ?? '',
      address: data['formattedAddress'] ?? data['address'] ?? '',
      latitude: (location?['lat'] as num?)?.toDouble() ?? 0.0,
      longitude: (location?['lng'] as num?)?.toDouble() ?? 0.0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingCount: (data['userRatingCount'] as num?)?.toInt() ?? 0,
      priceLevel: (data['priceLevel'] as num?)?.toInt() ?? 0,
      isOpen: data['isOpen'] ?? false,
      weekdayHours: List<String>.from(data['weekdayHours'] ?? []),
      phoneNumber: data['phoneNumber'] ?? '',
      photoUrls: List<String>.from(data['photoUrls'] ?? []),
      reviews: reviewsList
              ?.map((r) =>
                  VenueReview.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      sportType: data['sportType'] != null
          ? MeetupType.values.firstWhere(
              (e) => e.name == data['sportType'],
              orElse: () => MeetupType.other,
            )
          : null,
    );
  }

  factory VenueModel.fromJson(Map<String, dynamic> json) {
    final reviewsList = json['reviews'] as List?;

    return VenueModel(
      placeId: json['placeId'] ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      userRatingCount: (json['userRatingCount'] as num?)?.toInt() ?? 0,
      priceLevel: (json['priceLevel'] as num?)?.toInt() ?? 0,
      isOpen: json['isOpen'] ?? false,
      weekdayHours: List<String>.from(json['weekdayHours'] ?? []),
      phoneNumber: json['phoneNumber'] ?? '',
      photoUrls: List<String>.from(json['photoUrls'] ?? []),
      reviews: reviewsList
              ?.map((r) =>
                  VenueReview.fromJson(r as Map<String, dynamic>))
              .toList() ??
          [],
      sportType: json['sportType'] != null
          ? MeetupType.values.firstWhere(
              (e) => e.name == json['sportType'],
              orElse: () => MeetupType.other,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'placeId': placeId,
      'name': name,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'rating': rating,
      'userRatingCount': userRatingCount,
      'priceLevel': priceLevel,
      'isOpen': isOpen,
      'weekdayHours': weekdayHours,
      'phoneNumber': phoneNumber,
      'photoUrls': photoUrls,
      'reviews': reviews.map((r) => r.toJson()).toList(),
      'sportType': sportType?.name,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VenueModel && other.placeId == placeId;
  }

  @override
  int get hashCode => placeId.hashCode;
}
