class EligibleMeetup {
  final String meetupId;
  final String title;
  final DateTime date;
  final String sportType;
  final bool hasRated;

  const EligibleMeetup({
    required this.meetupId,
    required this.title,
    required this.date,
    required this.sportType,
    required this.hasRated,
  });

  EligibleMeetup copyWith({
    String? meetupId,
    String? title,
    DateTime? date,
    String? sportType,
    bool? hasRated,
  }) {
    return EligibleMeetup(
      meetupId: meetupId ?? this.meetupId,
      title: title ?? this.title,
      date: date ?? this.date,
      sportType: sportType ?? this.sportType,
      hasRated: hasRated ?? this.hasRated,
    );
  }
}
