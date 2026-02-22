import 'package:sporsal/core/models/meetup_model.dart';

class MonthlyActivity {
  final int year;
  final int month;
  final int count;

  const MonthlyActivity({
    required this.year,
    required this.month,
    required this.count,
  });
}

class UserStatisticsModel {
  final int totalMeetups;
  final MeetupType? mostParticipatedSport;
  final int mostParticipatedSportCount;
  final double averageMonthlyParticipation;
  final int partnerCount;
  final Map<MeetupType, int> sportDistribution;
  final Map<MeetupType, double> sportPercentages;
  final List<MonthlyActivity> monthlyActivities;
  final double reliabilityScore;

  const UserStatisticsModel({
    required this.totalMeetups,
    this.mostParticipatedSport,
    this.mostParticipatedSportCount = 0,
    this.averageMonthlyParticipation = 0.0,
    this.partnerCount = 0,
    this.sportDistribution = const {},
    this.sportPercentages = const {},
    this.monthlyActivities = const [],
    this.reliabilityScore = 100.0,
  });

  factory UserStatisticsModel.empty() => const UserStatisticsModel(
        totalMeetups: 0,
      );
}
