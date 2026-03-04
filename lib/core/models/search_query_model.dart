import 'meetup_model.dart';

class SearchQueryModel {
  final String id;
  final MeetupType sportType;
  final String regionName;
  final double latitude;
  final double longitude;
  final DateTime searchedAt;

  const SearchQueryModel({
    required this.id,
    required this.sportType,
    required this.regionName,
    required this.latitude,
    required this.longitude,
    required this.searchedAt,
  });

  factory SearchQueryModel.fromJson(Map<String, dynamic> json) {
    return SearchQueryModel(
      id: json['id'] ?? '',
      sportType: MeetupType.values.firstWhere(
        (e) => e.name == json['sportType'],
        orElse: () => MeetupType.other,
      ),
      regionName: json['regionName'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      searchedAt: json['searchedAt'] != null
          ? DateTime.parse(json['searchedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sportType': sportType.name,
      'regionName': regionName,
      'latitude': latitude,
      'longitude': longitude,
      'searchedAt': searchedAt.toIso8601String(),
    };
  }
}
