import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/user_model.dart';
import '../models/user_statistics_model.dart';

class StatisticsService {
  final FirebaseFirestore _firestore;

  StatisticsService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<UserStatisticsModel> getUserStatistics(String userId) async {
    final meetupsSnapshot = await _firestore
        .collection('meetups')
        .where('participantIds', arrayContains: userId)
        .get();

    final userDoc =
        await _firestore.collection('users').doc(userId).get();

    if (!userDoc.exists) {
      return UserStatisticsModel.empty();
    }

    final meetups = meetupsSnapshot.docs
        .map((d) => MeetupModel.fromJson(d.data()))
        .toList();
    final user = UserModel.fromJson(userDoc.data()!);

    return calculateStatistics(meetups: meetups, user: user);
  }

  /// Pure function — no side effects, fully testable.
  static UserStatisticsModel calculateStatistics({
    required List<MeetupModel> meetups,
    required UserModel user,
  }) {
    if (meetups.isEmpty) {
      return UserStatisticsModel(
        totalMeetups: 0,
        partnerCount: user.partners.length,
        reliabilityScore: user.reliabilityScore,
      );
    }

    // Sport distribution
    final distribution = <MeetupType, int>{};
    for (final m in meetups) {
      distribution[m.type] = (distribution[m.type] ?? 0) + 1;
    }

    // Sport percentages (sum to 100)
    final total = meetups.length;
    final percentages = <MeetupType, double>{};
    if (distribution.length == 1) {
      percentages[distribution.keys.first] = 100.0;
    } else {
      double runningSum = 0;
      final sorted = distribution.entries.toList()
        ..sort((a, b) => a.value.compareTo(b.value));
      for (var i = 0; i < sorted.length; i++) {
        if (i == sorted.length - 1) {
          // Last entry gets the remainder to ensure sum == 100
          percentages[sorted[i].key] = 100.0 - runningSum;
        } else {
          final pct = double.parse(
            (sorted[i].value / total * 100).toStringAsFixed(1),
          );
          percentages[sorted[i].key] = pct;
          runningSum += pct;
        }
      }
    }

    // Most participated sport
    MeetupType? mostSport;
    int mostCount = 0;
    for (final entry in distribution.entries) {
      if (entry.value > mostCount) {
        mostCount = entry.value;
        mostSport = entry.key;
      }
    }

    // Monthly activities (last 6 months)
    final now = DateTime.now();
    final sixMonthsAgo = DateTime(now.year, now.month - 5, 1);
    final monthlyMap = <String, int>{};
    for (var i = 0; i < 6; i++) {
      final m = DateTime(now.year, now.month - i, 1);
      monthlyMap['${m.year}-${m.month}'] = 0;
    }
    for (final m in meetups) {
      if (m.date.isAfter(sixMonthsAgo) ||
          (m.date.year == sixMonthsAgo.year &&
              m.date.month == sixMonthsAgo.month)) {
        final key = '${m.date.year}-${m.date.month}';
        if (monthlyMap.containsKey(key)) {
          monthlyMap[key] = monthlyMap[key]! + 1;
        }
      }
    }
    final monthlyActivities = <MonthlyActivity>[];
    for (var i = 5; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month}';
      monthlyActivities.add(MonthlyActivity(
        year: m.year,
        month: m.month,
        count: monthlyMap[key] ?? 0,
      ));
    }

    // Average monthly participation
    final earliest = meetups
        .map((m) => m.date)
        .reduce((a, b) => a.isBefore(b) ? a : b);
    final monthsDiff =
        (now.year - earliest.year) * 12 + (now.month - earliest.month);
    final months = monthsDiff < 1 ? 1 : monthsDiff;
    final avgMonthly = total / months;

    return UserStatisticsModel(
      totalMeetups: total,
      mostParticipatedSport: mostSport,
      mostParticipatedSportCount: mostCount,
      averageMonthlyParticipation: avgMonthly,
      partnerCount: user.partners.length,
      sportDistribution: distribution,
      sportPercentages: percentages,
      monthlyActivities: monthlyActivities,
      reliabilityScore: user.reliabilityScore,
    );
  }
}
