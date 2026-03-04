import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sporsal/core/services/meetup_service.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import '../../helpers/factories.dart';
import '../../mock_firebase.dart';

void main() {
  group('MeetupService', () {
    late MeetupService service;

    setUpAll(() async {
      setupFirebaseCoreMocks();
      await Firebase.initializeApp();
    });

    setUp(() {
      service = MeetupService();
    });

    group('getEffectiveEndDate', () {
      test('returns endDate when provided', () {
        final endDate = DateTime(2026, 3, 1, 18, 0);
        final meetup = TestFactory.meetup(
          date: DateTime(2026, 3, 1, 16, 0),
        );
        // Create a meetup with endDate by using copyWith or direct model
        final meetupWithEnd = MeetupModel(
          id: meetup.id,
          title: meetup.title,
          description: meetup.description,
          rules: meetup.rules,
          imageUrl: meetup.imageUrl,
          type: meetup.type,
          date: meetup.date,
          endDate: endDate,
          locationName: meetup.locationName,
          locationAddress: meetup.locationAddress,
          organizerId: meetup.organizerId,
          organizerName: meetup.organizerName,
          currentParticipants: meetup.currentParticipants,
          maxParticipants: meetup.maxParticipants,
          participantIds: meetup.participantIds,
        );

        expect(service.getEffectiveEndDate(meetupWithEnd), equals(endDate));
      });

      test('returns date + 2 hours when endDate is null', () {
        final date = DateTime(2026, 3, 1, 16, 0);
        final meetup = TestFactory.meetup(date: date);

        expect(
          service.getEffectiveEndDate(meetup),
          equals(date.add(const Duration(hours: 2))),
        );
      });
    });

    group('isMeetupActive', () {
      test('returns true when now is between date and effectiveEnd', () {
        final now = DateTime(2026, 3, 1, 17, 0);
        final meetup = TestFactory.meetup(
          date: DateTime(2026, 3, 1, 16, 0),
        );

        expect(service.isMeetupActive(meetup, now: now), isTrue);
      });

      test('returns false when now is before date', () {
        final now = DateTime(2026, 3, 1, 15, 0);
        final meetup = TestFactory.meetup(
          date: DateTime(2026, 3, 1, 16, 0),
        );

        expect(service.isMeetupActive(meetup, now: now), isFalse);
      });

      test('returns false when now is after effectiveEnd', () {
        final now = DateTime(2026, 3, 1, 19, 0);
        final meetup = TestFactory.meetup(
          date: DateTime(2026, 3, 1, 16, 0),
        );

        expect(service.isMeetupActive(meetup, now: now), isFalse);
      });
    });

    group('isMeetupPast', () {
      test('returns true for past meetups', () {
        final meetup = TestFactory.meetup(
          date: DateTime(2020, 1, 1, 10, 0),
        );

        expect(service.isMeetupPast(meetup), isTrue);
      });

      test('returns false for future meetups', () {
        final meetup = TestFactory.meetup(
          date: DateTime(2030, 1, 1, 10, 0),
        );

        expect(service.isMeetupPast(meetup), isFalse);
      });
    });
  });
}
