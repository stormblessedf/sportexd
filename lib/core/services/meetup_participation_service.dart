import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meetup_model.dart';
import '../models/position_slot.dart';

/// Handles meetup join/leave/waitlist operations,
/// extracted from MeetupService for SRP compliance.
class MeetupParticipationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  CollectionReference get _meetupsRef => _firestore.collection('meetups');

  Future<void> joinMeetup(String meetupId, String userId) async {
    final isNewJoin = await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);
      final participantSnapshot = await transaction.get(participantRef);

      if (!snapshot.exists) throw Exception("Meetup not found");
      if (participantSnapshot.exists) return false;

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      if (meetup.participantIds.contains(userId)) return false;

      if (meetup.isFootballWithTeams) {
        throw Exception(
          "Bu futbol etkinligine katilmak icin pozisyon secmelisiniz",
        );
      }

      if (meetup.currentParticipants >= meetup.maxParticipants) {
        throw Exception("Meetup is full");
      }

      transaction.set(participantRef, {
        'joinedAt': FieldValue.serverTimestamp(),
      });

      transaction.update(docRef, {
        'currentParticipants': FieldValue.increment(1),
        'isFull': (meetup.currentParticipants + 1) >= meetup.maxParticipants,
        'participantIds': FieldValue.arrayUnion([userId]),
        'waitlistUserIds': FieldValue.arrayRemove([userId]),
      });
      return true;
    });

    if (!isNewJoin) return;
  }

  Future<bool> isParticipant(String meetupId, String userId) async {
    final doc = await _meetupsRef
        .doc(meetupId)
        .collection('participants')
        .doc(userId)
        .get();
    return doc.exists;
  }

  Future<void> joinWaitlist(String meetupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception("Meetup not found");

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      if (meetup.participantIds.contains(userId)) {
        throw Exception("You are already a participant");
      }
      if (meetup.waitlistUserIds.contains(userId)) return;

      transaction.update(docRef, {
        'waitlistUserIds': FieldValue.arrayUnion([userId]),
      });
    });
  }

  Future<void> leaveWaitlist(String meetupId, String userId) async {
    await _meetupsRef.doc(meetupId).update({
      'waitlistUserIds': FieldValue.arrayRemove([userId]),
    });
  }

  Future<bool> isOnWaitlist(String meetupId, String userId) async {
    final doc = await _meetupsRef.doc(meetupId).get();
    if (!doc.exists) return false;
    final meetup = MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
    return meetup.waitlistUserIds.contains(userId);
  }

  Future<void> leaveMeetup(String meetupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception("Meetup not found");

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      if (meetup.organizerId == userId) {
        throw Exception("Organizatör kendi etkinliğinden ayrılamaz");
      }
      if (!meetup.participantIds.contains(userId)) {
        throw Exception("Bu etkinliğe katılmadınız");
      }

      transaction.delete(participantRef);

      final updateData = <String, dynamic>{
        'currentParticipants': FieldValue.increment(-1),
        'isFull': false,
        'participantIds': FieldValue.arrayRemove([userId]),
      };

      if (meetup.isFootballWithTeams) {
        if (meetup.teamASlots != null) {
          final hasUser = meetup.teamASlots!.any((s) => s.assignedUserId == userId);
          if (hasUser) {
            final updated = meetup.teamASlots!.map((s) =>
              s.assignedUserId == userId ? s.clearUser() : s).toList();
            updateData['teamASlots'] = updated.map((s) => s.toJson()).toList();
          }
        }
        if (meetup.teamBSlots != null) {
          final hasUser = meetup.teamBSlots!.any((s) => s.assignedUserId == userId);
          if (hasUser) {
            final updated = meetup.teamBSlots!.map((s) =>
              s.assignedUserId == userId ? s.clearUser() : s).toList();
            updateData['teamBSlots'] = updated.map((s) => s.toJson()).toList();
          }
        }
      }

      transaction.update(docRef, updateData);
    });
  }

  Future<void> joinMeetupWithPosition({
    required String meetupId,
    required String userId,
    required String userName,
    required String team,
    required int slotIndex,
    String? userImageUrl,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);
      final participantSnapshot = await transaction.get(participantRef);

      if (!snapshot.exists) throw Exception("Etkinlik bulunamadı");

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      if (participantSnapshot.exists || meetup.participantIds.contains(userId)) {
        throw Exception("Zaten bu etkinliğe katıldınız");
      }
      if (meetup.currentParticipants >= meetup.maxParticipants) {
        throw Exception("Etkinlik dolu");
      }

      List<PositionSlot>? slots;
      String slotsField;

      if (team == 'A') {
        slots = meetup.teamASlots;
        slotsField = 'teamASlots';
      } else if (team == 'B') {
        slots = meetup.teamBSlots;
        slotsField = 'teamBSlots';
      } else {
        throw Exception("Geçersiz takım seçimi");
      }

      if (slots == null || slotIndex < 0 || slotIndex >= slots.length) {
        throw Exception("Geçersiz pozisyon seçimi");
      }

      final selectedSlot = slots[slotIndex];
      if (selectedSlot.isFilled) {
        throw Exception("Bu pozisyon zaten dolu. Lütfen başka bir pozisyon seçin.");
      }

      final updatedSlots = List<PositionSlot>.from(slots);
      updatedSlots[slotIndex] = selectedSlot.assignUser(
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
      );

      transaction.set(participantRef, {
        'joinedAt': FieldValue.serverTimestamp(),
        'team': team,
        'slotIndex': slotIndex,
        'position': selectedSlot.position,
      });

      transaction.update(docRef, {
        'currentParticipants': FieldValue.increment(1),
        'isFull': (meetup.currentParticipants + 1) >= meetup.maxParticipants,
        'participantIds': FieldValue.arrayUnion([userId]),
        'waitlistUserIds': FieldValue.arrayRemove([userId]),
        slotsField: updatedSlots.map((s) => s.toJson()).toList(),
      });
    });
  }
}
