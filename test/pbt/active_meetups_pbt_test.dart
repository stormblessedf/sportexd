import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, group, test, setUp, setUpAll, tearDown, tearDownAll;
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/services/meetup_service.dart';
import 'package:sporsal/features/profile/presentation/widgets/active_meetup_card.dart';
import '../helpers/arbitraries.dart';
import '../mock_firebase.dart';

/// Custom arbitrary that generates MeetupModels with varying endDate values
/// (both null and non-null) to properly test effective end date logic.
extension MeetupWithEndDateArbitrary on Any {
  Generator<MeetupModel> get meetupWithEndDate => combine5(
        nonEmptyLetterOrDigits, // id
        meetupType, // type
        intInRange(2020, 2030), // year
        intInRange(1, 12), // month
        intInRange(1, 28), // day (safe range)
        (String id, MeetupType type, int year, int month, int day) {
          final date = DateTime(year, month, day, 14, 0);

          // Use id hash to deterministically decide null vs non-null endDate
          // and to vary the endDate offset
          final hasEndDate = id.hashCode.isEven;
          final offsetHours = 1 + (id.length % 5); // 1-5 hours

          return MeetupModel(
            id: id,
            title: 'Test Meetup',
            description: 'Test',
            imageUrl: 'https://example.com/img.jpg',
            type: type,
            date: date,
            endDate: hasEndDate ? date.add(Duration(hours: offsetHours)) : null,
            locationName: 'Test Location',
            locationAddress: 'Test Address',
            organizerId: 'org-1',
            organizerName: 'Organizer',
            currentParticipants: 1,
            maxParticipants: 10,
          );
        },
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

  group('Feature: active-meetups-profile', () {
    /// **Validates: Requirements 1.2, 1.3**
    /// Property 1: Efektif bitiş tarihi hesaplaması
    ///
    /// For any MeetupModel, `getEffectiveEndDate` returns `endDate` when
    /// non-null, otherwise `date + 2 hours`.
    Glados(any.meetupWithEndDate, ExploreConfig(numRuns: 100)).test(
      'Property 1: getEffectiveEndDate returns endDate when non-null, otherwise date + 2 hours',
      (meetup) {
        final result = service.getEffectiveEndDate(meetup);

        if (meetup.endDate != null) {
          expect(
            result,
            equals(meetup.endDate),
            reason:
                'When endDate is non-null, getEffectiveEndDate should return endDate',
          );
        } else {
          expect(
            result,
            equals(meetup.date.add(const Duration(hours: 2))),
            reason:
                'When endDate is null, getEffectiveEndDate should return date + 2 hours',
          );
        }
      },
    );

    /// **Validates: Requirements 1.1**
    /// Property 2: Aktif etkinlik tespiti
    ///
    /// For any MeetupModel and any `now` DateTime,
    /// `isMeetupActive(meetup, now: now)` returns true iff
    /// `meetup.date <= now < getEffectiveEndDate(meetup)`.
    Glados2(any.meetupWithEndDate, any.intInRange(-3, 5),
            ExploreConfig(numRuns: 100))
        .test(
      'Property 2: isMeetupActive returns true iff meetup.date <= now < getEffectiveEndDate(meetup)',
      (meetup, hourOffset) {
        // Generate `now` relative to the meetup's date so we cover
        // before-start, during, and after-end scenarios.
        final now = meetup.date.add(Duration(hours: hourOffset));

        final effectiveEnd = service.getEffectiveEndDate(meetup);
        final expectedActive =
            !meetup.date.isAfter(now) && now.isBefore(effectiveEnd);

        final result = service.isMeetupActive(meetup, now: now);

        expect(
          result,
          equals(expectedActive),
          reason:
              'isMeetupActive should return $expectedActive for '
              'date=${meetup.date}, endDate=${meetup.endDate}, now=$now, '
              'effectiveEnd=$effectiveEnd',
        );
      },
    );

    /// **Validates: Requirements 3.3**
    /// Property 3: Aktif etkinlik kartı gerekli bilgileri gösterir
    ///
    /// For any active MeetupModel, `ActiveMeetupCard` renders sport type
    /// displayName, locationName, and remaining time text.
    testWidgets(
      'Property 3: ActiveMeetupCard renders sport type displayName, locationName, and remaining time',
      (tester) async {
        final random = Random(42); // fixed seed for reproducibility
        const types = MeetupType.values;
        const locations = [
          'Caddebostan Sahil',
          'Moda Parkı',
          'Fenerbahçe Stadı',
          'Beşiktaş Sahil',
          'Taksim Meydanı',
          'Kadıköy İskele',
          'Üsküdar Park',
          'Ataşehir Spor',
          'Bostancı Sahil',
          'Maltepe Park',
          'Kartal Arena',
          'Pendik Sahil',
        ];

        for (var i = 0; i < 100; i++) {
          final type = types[random.nextInt(types.length)];
          final location = locations[random.nextInt(locations.length)];
          final minutes = random.nextInt(301); // 0–300 minutes

          final meetup = MeetupModel(
            id: 'pbt-$i',
            title: 'Meetup $i',
            description: 'Test',
            imageUrl: 'https://example.com/img.jpg',
            type: type,
            date: DateTime(2025, 1, 1, 14, 0),
            locationName: location,
            locationAddress: 'Address',
            organizerId: 'org-1',
            organizerName: 'Organizer',
            currentParticipants: 1,
            maxParticipants: 10,
          );

          final duration = Duration(minutes: minutes);

          await tester.pumpWidget(
            MaterialApp(
              home: Scaffold(
                body: ActiveMeetupCard(
                  meetup: meetup,
                  remainingTime: duration,
                ),
              ),
            ),
          );

          // Verify sport type displayName is rendered
          expect(
            find.text(meetup.type.displayName),
            findsWidgets,
            reason:
                'Iteration $i: should display sport type displayName: ${meetup.type.displayName}',
          );

          // Verify locationName is rendered
          expect(
            find.text(meetup.locationName),
            findsOneWidget,
            reason:
                'Iteration $i: should display locationName: ${meetup.locationName}',
          );

          // Verify remaining time text is rendered
          final hours = duration.inHours;
          final mins = duration.inMinutes % 60;
          final expectedTimeText = hours > 0
              ? '${hours}s ${mins}dk kaldı'
              : '${mins}dk kaldı';

          expect(
            find.text(expectedTimeText),
            findsOneWidget,
            reason:
                'Iteration $i: should display remaining time: $expectedTimeText',
          );
        }
      },
    );
  });
}
