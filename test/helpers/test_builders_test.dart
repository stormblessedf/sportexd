import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'test_builders.dart';

void main() {
  group('TestUserBuilder', () {
    test('build() returns valid UserModel with defaults', () {
      final user = TestUserBuilder().build();

      expect(user.id, 'test-user-1');
      expect(user.username, 'TestUser');
      expect(user.email, 'test@sporsal.com');
      expect(user.reliabilityScore, 100.0);
      expect(user.averageRating, 0.0);
      expect(user.totalMeetupsJoined, 0);
      expect(user.totalMeetupsRegistered, 0);
      expect(user.isOnline, false);
    });

    test('defaults satisfy business rule constraints', () {
      final user = TestUserBuilder().build();

      expect(user.reliabilityScore, greaterThanOrEqualTo(0.0));
      expect(user.reliabilityScore, lessThanOrEqualTo(100.0));
      expect(user.averageRating, greaterThanOrEqualTo(0.0));
      expect(user.averageRating, lessThanOrEqualTo(5.0));
    });

    test('chainable setters override fields', () {
      final user = TestUserBuilder()
          .withId('custom-id')
          .withUsername('CustomUser')
          .withEmail('custom@test.com')
          .withReliabilityScore(85.0)
          .withAverageRating(4.2)
          .withIsOnline(true)
          .build();

      expect(user.id, 'custom-id');
      expect(user.username, 'CustomUser');
      expect(user.email, 'custom@test.com');
      expect(user.reliabilityScore, 85.0);
      expect(user.averageRating, 4.2);
      expect(user.isOnline, true);
    });

    test('all optional fields can be set', () {
      final user = TestUserBuilder()
          .withBio('Test bio')
          .withProfileImageUrl('https://img.com/pic.jpg')
          .withLocation('Istanbul')
          .withGender('male')
          .withBirthDate(DateTime(1995, 3, 10))
          .withHeight(180)
          .withWeight(75)
          .withLevel(Level.advanced)
          .withPlayStyle(PlayStyle.competitive)
          .withTeamPreference('Team A')
          .withInterestedSports([SportType.football, SportType.tennis])
          .withPreferredTimes([PreferredTime.weekendMorning])
          .withPartners(['p1', 'p2'])
          .withPartnersCount(2)
          .withTotalRatings(50)
          .withTotalMeetupsJoined(10)
          .withTotalMeetupsRegistered(12)
          .withLastSeen(DateTime(2025, 1, 1))
          .build();

      expect(user.bio, 'Test bio');
      expect(user.profileImageUrl, 'https://img.com/pic.jpg');
      expect(user.location, 'Istanbul');
      expect(user.height, 180);
      expect(user.weight, 75);
      expect(user.level, Level.advanced);
      expect(user.playStyle, PlayStyle.competitive);
      expect(user.interestedSports, [SportType.football, SportType.tennis]);
      expect(user.partners, ['p1', 'p2']);
      expect(user.partnersCount, 2);
    });
  });

  group('TestMeetupBuilder', () {
    test('build() returns valid MeetupModel with defaults', () {
      final meetup = TestMeetupBuilder().build();

      expect(meetup.id, 'test-meetup-1');
      expect(meetup.title, 'Test Etkinlik');
      expect(meetup.type, MeetupType.football);
      expect(meetup.organizerId, 'organizer-1');
      expect(meetup.organizerName, 'Test Organizer');
      expect(meetup.currentParticipants, 1);
      expect(meetup.maxParticipants, 10);
    });

    test('defaults satisfy currentParticipants <= maxParticipants', () {
      final meetup = TestMeetupBuilder().build();
      expect(meetup.currentParticipants, lessThanOrEqualTo(meetup.maxParticipants));
    });

    test('build() clamps currentParticipants when exceeding maxParticipants', () {
      final meetup = TestMeetupBuilder()
          .withCurrentParticipants(20)
          .withMaxParticipants(10)
          .build();

      expect(meetup.currentParticipants, 10);
      expect(meetup.maxParticipants, 10);
    });

    test('chainable setters override fields', () {
      final meetup = TestMeetupBuilder()
          .withId('custom-meetup')
          .withTitle('Custom Meetup')
          .withType(MeetupType.tennis)
          .withMaxParticipants(4)
          .withCurrentParticipants(2)
          .withOrganizerId('org-2')
          .withOrganizerName('Jane')
          .build();

      expect(meetup.id, 'custom-meetup');
      expect(meetup.title, 'Custom Meetup');
      expect(meetup.type, MeetupType.tennis);
      expect(meetup.maxParticipants, 4);
      expect(meetup.currentParticipants, 2);
      expect(meetup.organizerId, 'org-2');
      expect(meetup.organizerName, 'Jane');
    });

    test('all optional fields can be set', () {
      final date = DateTime(2025, 8, 1);
      final endDate = DateTime(2025, 8, 1, 18, 0);
      final meetup = TestMeetupBuilder()
          .withDescription('Full description')
          .withRules('No fouls')
          .withImageUrl('https://img.com/meetup.jpg')
          .withDate(date)
          .withEndDate(endDate)
          .withLocationName('Central Park')
          .withLocationAddress('NYC')
          .withOrganizerImageUrl('https://img.com/org.jpg')
          .withOrganizerRating(4.8)
          .withIsFull(true)
          .withParticipantIds(['u1', 'u2'])
          .withWaitlistUserIds(['u3'])
          .withLatitude(40.7128)
          .withLongitude(-74.0060)
          .withIsOrganizerOnlyChat(true)
          .withCreatedAt(DateTime(2025, 7, 1))
          .withTeamFormat('5v5')
          .withFormation('1-2-1-1')
          .build();

      expect(meetup.description, 'Full description');
      expect(meetup.rules, 'No fouls');
      expect(meetup.date, date);
      expect(meetup.endDate, endDate);
      expect(meetup.locationName, 'Central Park');
      expect(meetup.organizerRating, 4.8);
      expect(meetup.isFull, true);
      expect(meetup.waitlistUserIds, ['u3']);
      expect(meetup.latitude, 40.7128);
      expect(meetup.isOrganizerOnlyChat, true);
      expect(meetup.teamFormat, '5v5');
      expect(meetup.formation, '1-2-1-1');
    });
  });
}
