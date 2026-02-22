import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, group, test;
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import '../helpers/arbitraries.dart';

void main() {
  // --- Task 9.1: UserModel JSON round-trip ---

  group('UserModel JSON round-trip', () {
    /// **Validates: Requirements 9.2**
    Glados(any.userModel).test(
      'toJson → fromJson preserves key fields',
      (user) {
        final json = user.toJson();
        final restored = UserModel.fromJson(json);

        expect(restored.id, equals(user.id));
        expect(restored.username, equals(user.username));
        expect(restored.email, equals(user.email));
        expect(restored.reliabilityScore, equals(user.reliabilityScore));
        expect(restored.averageRating, equals(user.averageRating));
        expect(restored.totalRatings, equals(user.totalRatings));
        expect(restored.totalMeetupsJoined, equals(user.totalMeetupsJoined));
        expect(
          restored.totalMeetupsRegistered,
          equals(user.totalMeetupsRegistered),
        );
        expect(restored.partnersCount, equals(user.partnersCount));
      },
    );
  });

  // --- Task 9.2: MeetupModel JSON round-trip ---

  group('MeetupModel JSON round-trip', () {
    /// **Validates: Requirements 9.3**
    Glados(any.meetupModel).test(
      'toJson → fromJson preserves key non-date fields',
      (meetup) {
        final json = meetup.toJson();
        // fromJson handles Timestamp objects from toJson directly
        final restored = MeetupModel.fromJson(json);

        expect(restored.id, equals(meetup.id));
        expect(restored.title, equals(meetup.title));
        expect(restored.description, equals(meetup.description));
        expect(restored.type, equals(meetup.type));
        expect(restored.organizerId, equals(meetup.organizerId));
        expect(restored.organizerName, equals(meetup.organizerName));
        expect(
          restored.currentParticipants,
          equals(meetup.currentParticipants),
        );
        expect(restored.maxParticipants, equals(meetup.maxParticipants));
      },
    );
  });

  // --- Task 9.3: Invariant property tests ---

  group('UserModel invariants', () {
    /// **Validates: Requirements 3.1**
    Glados(any.userModel).test(
      'reliabilityScore is within 0-100',
      (user) {
        expect(user.reliabilityScore, greaterThanOrEqualTo(0.0));
        expect(user.reliabilityScore, lessThanOrEqualTo(100.0));
      },
    );

    /// **Validates: Requirements 3.2**
    Glados(any.userModel).test(
      'averageRating is within 0-5',
      (user) {
        expect(user.averageRating, greaterThanOrEqualTo(0.0));
        expect(user.averageRating, lessThanOrEqualTo(5.0));
      },
    );
  });

  group('MeetupModel invariants', () {
    /// **Validates: Requirements 4.1**
    Glados(any.meetupModel).test(
      'currentParticipants <= maxParticipants',
      (meetup) {
        expect(
          meetup.currentParticipants,
          lessThanOrEqualTo(meetup.maxParticipants),
        );
      },
    );
  });

  // --- Task 9.4: SportType displayName non-empty ---

  group('SportType properties', () {
    /// **Validates: Requirements 1.1**
    Glados(any.sportType).test(
      'displayName is never empty',
      (sportType) {
        expect(sportType.displayName.isNotEmpty, isTrue);
      },
    );
  });
}
