import '../../../core/models/meetup_model.dart';

/// Abstract repository interface for meetup operations.
/// Concrete implementations can use Firestore, REST API, or mock data.
abstract class MeetupRepository {
  Future<void> createMeetup(MeetupModel meetup);
  Future<MeetupModel?> getMeetupById(String id);
  Stream<List<MeetupModel>> getUpcomingMeetups();
  Stream<List<MeetupModel>> getUserMeetups(String userId);
  Stream<List<MeetupModel>> getPastMeetupsForUser(String userId);
}
