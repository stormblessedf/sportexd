import 'package:glados/glados.dart';
import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/features/profile/presentation/models/trophy_definition.dart';

// --- Enum Arbitraries ---

extension SportTypeArbitrary on Any {
  Generator<SportType> get sportType => choose(SportType.values);
}

extension MeetupTypeArbitrary on Any {
  Generator<MeetupType> get meetupType => choose(MeetupType.values);
}

extension BadgeTypeArbitrary on Any {
  Generator<BadgeType> get badgeType => choose(BadgeType.values);
}

extension LevelArbitrary on Any {
  Generator<Level> get level => choose(Level.values);
}

extension PlayStyleArbitrary on Any {
  Generator<PlayStyle> get playStyle => choose(PlayStyle.values);
}

extension PreferredTimeArbitrary on Any {
  Generator<PreferredTime> get preferredTime => choose(PreferredTime.values);
}

// --- Badge Arbitrary ---

extension BadgeArbitrary on Any {
  Generator<Badge> get badge => combine3(
        nonEmptyLetterOrDigits,
        nonEmptyLetterOrDigits,
        badgeType,
        (String id, String name, BadgeType type) => Badge(
          id: id,
          name: name,
          description: 'Test badge $name',
          iconPath: 'assets/badges/$id.png',
          type: type,
        ),
      );
}

// --- UserModel Arbitrary ---

extension UserModelArbitrary on Any {
  Generator<UserModel> get userModel => combine5(
        nonEmptyLetterOrDigits, // id
        nonEmptyLetterOrDigits, // username
        nonEmptyLetterOrDigits, // email prefix
        doubleInRange(0.0, 100.0), // reliabilityScore
        doubleInRange(0.0, 5.0), // averageRating
        (String id, String username, String emailPrefix, double reliability,
            double rating) {
          // Generate constrained values inline
          final totalRegistered = id.length % 50; // 0-49
          final totalJoined =
              totalRegistered > 0 ? username.length % totalRegistered : 0;
          final totalRatings = (id.length * username.length) % 1001; // 0-1000
          final partners = <String>[
            for (var i = 0; i < (id.length % 5); i++) 'partner_$i'
          ];

          return UserModel(
            id: id,
            username: username,
            email: '$emailPrefix@test.com',
            reliabilityScore: reliability,
            averageRating: rating,
            totalRatings: totalRatings,
            totalMeetupsJoined: totalJoined,
            totalMeetupsRegistered: totalRegistered,
            partners: partners,
            partnersCount: partners.length,
          );
        },
      );
}

// --- MeetupModel Arbitrary ---

extension MeetupModelArbitrary on Any {
  Generator<MeetupModel> get meetupModel => combine5(
        nonEmptyLetterOrDigits, // id
        nonEmptyLetterOrDigits, // title
        nonEmptyLetterOrDigits, // organizerId
        nonEmptyLetterOrDigits, // organizerName
        meetupType, // type
        (String id, String title, String orgId, String orgName,
            MeetupType type) {
          // maxParticipants: 2-100, currentParticipants: 0..maxParticipants
          final maxP = 2 + (id.length % 99); // 2-100
          final currentP = title.length % (maxP + 1); // 0..maxP
          final participantIds = <String>[
            for (var i = 0; i < currentP; i++) 'participant_$i'
          ];

          return MeetupModel(
            id: id,
            title: title,
            description: 'Test meetup description',
            imageUrl: 'https://example.com/img.jpg',
            type: type,
            date: DateTime(2025, 6, 15),
            locationName: 'Test Location',
            locationAddress: 'Test Address',
            organizerId: orgId,
            organizerName: orgName,
            currentParticipants: currentP,
            maxParticipants: maxP,
            participantIds: participantIds,
          );
        },
      );
}

// --- TrophyDefinition Arbitrary ---

extension TrophyDefinitionArbitrary on Any {
  Generator<TrophyDefinition> get trophyDefinition => combine5(
        nonEmptyLetterOrDigits, // id
        nonEmptyLetters, // emoji
        nonEmptyLetterOrDigits, // name
        nonEmptyLetterOrDigits, // description
        nonEmptyLetterOrDigits, // criteria
        (String id, String emoji, String name, String description,
                String criteria) =>
            TrophyDefinition(
          id: id,
          emoji: emoji,
          name: name,
          description: description,
          criteria: criteria,
        ),
      );
}

// --- Register defaults for Glados<T>() usage ---

void registerArbitraryDefaults() {
  Any.setDefault(any.sportType);
  Any.setDefault(any.meetupType);
  Any.setDefault(any.badgeType);
  Any.setDefault(any.level);
  Any.setDefault(any.playStyle);
  Any.setDefault(any.preferredTime);
  Any.setDefault(any.badge);
  Any.setDefault(any.userModel);
  Any.setDefault(any.meetupModel);
  Any.setDefault(any.trophyDefinition);
}
