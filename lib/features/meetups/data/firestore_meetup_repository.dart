import '../../../core/services/meetup_service.dart';
import '../../../core/models/meetup_model.dart';
import '../domain/meetup_repository.dart';

/// Firestore-backed implementation of [MeetupRepository].
/// Delegates to the existing MeetupService for now.
class FirestoreMeetupRepository implements MeetupRepository {
  final MeetupService _service;

  FirestoreMeetupRepository(this._service);

  @override
  Future<void> createMeetup(MeetupModel meetup) async {
    // Delegate to service — full createMeetup params handled at service level
    throw UnimplementedError('Use MeetupService.createMeetup directly for now');
  }

  @override
  Future<MeetupModel?> getMeetupById(String id) => _service.getMeetupById(id);

  @override
  Stream<List<MeetupModel>> getUpcomingMeetups() => _service.getUpcomingMeetups();

  @override
  Stream<List<MeetupModel>> getUserMeetups(String userId) => _service.getUserMeetups(userId);

  @override
  Stream<List<MeetupModel>> getPastMeetupsForUser(String userId) => _service.getPastMeetupsForUser(userId);
}
