import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/services/meetup_service.dart';
import '../../mock_firebase.dart';

MeetupModel _makeMeetup({
  required DateTime date,
  DateTime? endDate,
}) {
  return MeetupModel(
    id: 'test-id',
    title: 'Test',
    description: '',
    imageUrl: '',
    type: MeetupType.football,
    date: date,
    endDate: endDate,
    locationName: '',
    locationAddress: '',
    organizerId: 'org1',
    organizerName: 'Org',
    currentParticipants: 1,
    maxParticipants: 10,
  );
}

void main() {
  late MeetupService service;

  setUpAll(() async {
    setupFirebaseCoreMocks();
    await Firebase.initializeApp();
  });

  setUp(() {
    service = MeetupService();
  });

  group('getEffectiveEndDate', () {
    test('returns endDate when it is not null', () {
      final end = DateTime(2025, 6, 1, 16, 0);
      final meetup = _makeMeetup(
        date: DateTime(2025, 6, 1, 14, 0),
        endDate: end,
      );
      expect(service.getEffectiveEndDate(meetup), equals(end));
    });

    test('returns date + 2 hours when endDate is null', () {
      final date = DateTime(2025, 6, 1, 14, 0);
      final meetup = _makeMeetup(date: date);
      expect(
        service.getEffectiveEndDate(meetup),
        equals(DateTime(2025, 6, 1, 16, 0)),
      );
    });
  });

  group('isMeetupActive', () {
    test('returns true when now is between date and effectiveEndDate', () {
      final meetup = _makeMeetup(date: DateTime(2025, 6, 1, 14, 0));
      final now = DateTime(2025, 6, 1, 15, 0);
      expect(service.isMeetupActive(meetup, now: now), isTrue);
    });

    test('returns true when now equals date (inclusive start)', () {
      final date = DateTime(2025, 6, 1, 14, 0);
      final meetup = _makeMeetup(date: date);
      expect(service.isMeetupActive(meetup, now: date), isTrue);
    });

    test('returns false when now equals effectiveEndDate (exclusive end)', () {
      final date = DateTime(2025, 6, 1, 14, 0);
      final end = DateTime(2025, 6, 1, 16, 0);
      final meetup = _makeMeetup(date: date, endDate: end);
      expect(service.isMeetupActive(meetup, now: end), isFalse);
    });

    test('returns false when now is before date', () {
      final meetup = _makeMeetup(date: DateTime(2025, 6, 1, 14, 0));
      final now = DateTime(2025, 6, 1, 13, 0);
      expect(service.isMeetupActive(meetup, now: now), isFalse);
    });

    test('returns false when now is after effectiveEndDate', () {
      final meetup = _makeMeetup(date: DateTime(2025, 6, 1, 14, 0));
      final now = DateTime(2025, 6, 1, 17, 0);
      expect(service.isMeetupActive(meetup, now: now), isFalse);
    });

    test('works with explicit endDate', () {
      final meetup = _makeMeetup(
        date: DateTime(2025, 6, 1, 14, 0),
        endDate: DateTime(2025, 6, 1, 18, 0),
      );
      final now = DateTime(2025, 6, 1, 17, 0);
      expect(service.isMeetupActive(meetup, now: now), isTrue);
    });
  });
}
