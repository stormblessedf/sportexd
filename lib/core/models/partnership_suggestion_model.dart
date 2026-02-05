class PartnershipSuggestionModel {
  final String suggestedUserId;
  final String suggestedUserName;
  final String meetupId;
  final int stars;
  final DateTime createdAt;

  const PartnershipSuggestionModel({
    required this.suggestedUserId,
    required this.suggestedUserName,
    required this.meetupId,
    required this.stars,
    required this.createdAt,
  });

  String getMessage() {
    return '$suggestedUserName ile iyi bir uyum yakaladın. Onu Spor Partnerlerine ekle?';
  }
}
