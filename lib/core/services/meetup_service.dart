import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meetup_model.dart';

class MeetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection Reference
  CollectionReference get _meetupsRef => _firestore.collection('meetups');

  // Create Meetup
  Future<void> createMeetup({
    required String title,
    required String description,
    required MeetupType type,
    required DateTime date,
    required String locationName,
    required String locationAddress,
    required int maxParticipants,
    required String organizerId,
    required String organizerName,
    String? organizerImageUrl,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    final docRef = _meetupsRef.doc(); // Generate ID

    // Use provided imageUrl or default placeholder
    final finalImageUrl = imageUrl ??
        'https://images.unsplash.com/photo-1579952363873-27f3bde9be2d?auto=format&fit=crop&q=80';

    final meetup = MeetupModel(
      id: docRef.id,
      title: title,
      description: description,
      imageUrl: finalImageUrl,
      type: type,
      date: date,
      locationName: locationName,
      locationAddress: locationAddress,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerImageUrl: organizerImageUrl,
      currentParticipants: 1, // Organizer joins automatically
      maxParticipants: maxParticipants,
      participantIds: [organizerId],
      latitude: latitude,
      longitude: longitude,
    );

    await docRef.set(meetup.toJson());
  }

  // Get Meetups Stream (All meetups - deprecated, use getUpcomingMeetups instead)
  @Deprecated('Use getUpcomingMeetups() to show only upcoming events')
  Stream<List<MeetupModel>> getMeetups() {
    return _meetupsRef
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get Upcoming Meetups (Future events only)
  Stream<List<MeetupModel>> getUpcomingMeetups() {
    final now = DateTime.now();
    
    return _meetupsRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get Past Meetups for User (Events user participated in that are now past)
  Stream<List<MeetupModel>> getPastMeetupsForUser(String userId) {
    final now = DateTime.now();
    
    return _meetupsRef
        .where('participantIds', arrayContains: userId)
        .where('date', isLessThan: Timestamp.fromDate(now))
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Check if meetup is in the past
  bool isMeetupPast(MeetupModel meetup) {
    return meetup.date.isBefore(DateTime.now());
  }

  // Get User Meetups (My Chats)
  Stream<List<MeetupModel>> getUserMeetups(String userId) {
    return _meetupsRef
        .where('participantIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get Single Meetup
  Future<MeetupModel?> getMeetup(String id) async {
    final doc = await _meetupsRef.doc(id).get();
    if (!doc.exists) return null;
    return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
  }
  
  // Join Meetup (Bonus for Phase 2)
  Future<void> joinMeetup(String meetupId, String userId) async {
      // Transaction to ensure atomic update of participant count
      await _firestore.runTransaction((transaction) async {
          final docRef = _meetupsRef.doc(meetupId);
          final participantRef = docRef.collection('participants').doc(userId);

          final snapshot = await transaction.get(docRef);
          final participantSnapshot = await transaction.get(participantRef);
          
          if (!snapshot.exists) throw Exception("Meetup not found");
          if (participantSnapshot.exists) return; // Already joined
          
          final meetup = MeetupModel.fromJson(snapshot.data() as Map<String, dynamic>);
          
          if (meetup.currentParticipants >= meetup.maxParticipants) {
              throw Exception("Meetup is full");
          }
          
          // Add user to participants subcollection
          transaction.set(participantRef, {
            'joinedAt': FieldValue.serverTimestamp(),
          });
          
          // Increment counter and add to participantIds array
          transaction.update(docRef, {
              'currentParticipants': FieldValue.increment(1),
              'isFull': (meetup.currentParticipants + 1) >= meetup.maxParticipants,
              'participantIds': FieldValue.arrayUnion([userId]),
          });
      });
  }

  // Check if user is participant
  Future<bool> isParticipant(String meetupId, String userId) async {
    final doc = await _meetupsRef
        .doc(meetupId)
        .collection('participants')
        .doc(userId)
        .get();
    return doc.exists;
  }
}
