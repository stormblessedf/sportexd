import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, group, test;
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'arbitraries.dart';

void main() {
  group('Enum Arbitrary smoke tests', () {
    /// **Validates: Requirements 1.1**
    Glados(any.sportType).test(
      'SportType arbitrary produces only valid enum values',
      (sportType) {
        expect(SportType.values.contains(sportType), isTrue);
      },
    );

    /// **Validates: Requirements 1.2**
    Glados(any.meetupType).test(
      'MeetupType arbitrary produces only valid enum values',
      (meetupType) {
        expect(MeetupType.values.contains(meetupType), isTrue);
      },
    );

    /// **Validates: Requirements 1.1**
    Glados(any.badgeType).test(
      'BadgeType arbitrary produces only valid enum values',
      (badgeType) {
        expect(BadgeType.values.contains(badgeType), isTrue);
      },
    );

    /// **Validates: Requirements 1.1**
    Glados(any.level).test(
      'Level arbitrary produces only valid enum values',
      (level) {
        expect(Level.values.contains(level), isTrue);
      },
    );

    /// **Validates: Requirements 1.1**
    Glados(any.playStyle).test(
      'PlayStyle arbitrary produces only valid enum values',
      (playStyle) {
        expect(PlayStyle.values.contains(playStyle), isTrue);
      },
    );

    /// **Validates: Requirements 1.1**
    Glados(any.preferredTime).test(
      'PreferredTime arbitrary produces only valid enum values',
      (preferredTime) {
        expect(PreferredTime.values.contains(preferredTime), isTrue);
      },
    );
  });
}
