import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/meetup_model.dart';
import '../models/position_slot.dart';
import '../models/route_data.dart';
import '../utils/meetup_placeholder_images.dart';

class MeetupService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference get _meetupsRef => _firestore.collection('meetups');

  String _participantStateFor(int currentParticipants, int maxParticipants) {
    return MeetupModel.computeParticipantState(
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
    );
  }

  // Create Meetup
  Future<MeetupModel> createMeetup({
    required String title,
    required String description,
    String? rules,
    required MeetupType type,
    required DateTime date,
    DateTime? endDate,
    required String locationName,
    required String locationAddress,
    required int maxParticipants,
    bool hideFromFeedUntilAccepted = false,
    required String organizerId,
    required String organizerName,
    String? organizerImageUrl,
    String? imageUrl,
    double? latitude,
    double? longitude,
    // Football-specific parameters
    String? teamFormat,
    String? formation,
    List<PositionSlot>? teamASlots,
    List<PositionSlot>? teamBSlots,
    // Route-specific parameter
    RouteData? routeData,
  }) async {
    final docRef = _meetupsRef.doc(); // Generate ID

    // Use provided imageUrl or get random placeholder based on category
    final finalImageUrl = imageUrl ?? MeetupPlaceholderImages.getRandom(type);

    // Keep participant counters and football slots consistent from day one.
    final normalizedTeamASlots = teamASlots?.toList(growable: false);
    final normalizedTeamBSlots = teamBSlots?.toList(growable: false);

    if (type == MeetupType.football &&
        normalizedTeamASlots != null &&
        normalizedTeamBSlots != null) {
      final organizerAlreadyAssigned =
          normalizedTeamASlots.any(
            (slot) => slot.assignedUserId == organizerId,
          ) ||
          normalizedTeamBSlots.any(
            (slot) => slot.assignedUserId == organizerId,
          );

      if (!organizerAlreadyAssigned) {
        final teamAIndex = normalizedTeamASlots.indexWhere(
          (slot) => slot.isEmpty,
        );
        if (teamAIndex != -1) {
          normalizedTeamASlots[teamAIndex] = normalizedTeamASlots[teamAIndex]
              .assignUser(
                userId: organizerId,
                userName: organizerName,
                userImageUrl: organizerImageUrl,
              );
        } else {
          final teamBIndex = normalizedTeamBSlots.indexWhere(
            (slot) => slot.isEmpty,
          );
          if (teamBIndex != -1) {
            normalizedTeamBSlots[teamBIndex] = normalizedTeamBSlots[teamBIndex]
                .assignUser(
                  userId: organizerId,
                  userName: organizerName,
                  userImageUrl: organizerImageUrl,
                );
          }
        }
      }
    }

    final meetup = MeetupModel(
      id: docRef.id,
      title: title,
      description: description,
      rules: rules ?? '',
      imageUrl: finalImageUrl,
      type: type,
      date: date,
      endDate: endDate,
      locationName: locationName,
      locationAddress: locationAddress,
      organizerId: organizerId,
      organizerName: organizerName,
      organizerImageUrl: organizerImageUrl,
      currentParticipants: 1, // Organizer joins automatically
      maxParticipants: maxParticipants,
      hideFromFeedUntilAccepted: hideFromFeedUntilAccepted,
      participantIds: [organizerId],
      latitude: latitude,
      longitude: longitude,
      teamFormat: teamFormat,
      formation: formation,
      teamASlots: normalizedTeamASlots,
      teamBSlots: normalizedTeamBSlots,
      routeData: routeData,
    );

    await docRef.set(meetup.toJson());
    return meetup;
  }

  // Get Upcoming Meetups (Future events only)
  Stream<List<MeetupModel>> getUpcomingMeetups() {
    final now = DateTime.now();

    return _meetupsRef
        .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(now))
        .orderBy('date', descending: false)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) {
                return MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
              })
              .where((meetup) => meetup.isFeedVisible)
              .toList();
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
    final effectiveEnd = getEffectiveEndDate(meetup);
    return effectiveEnd.isBefore(DateTime.now());
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

  // Alias for getMeetup (for consistency)
  Future<MeetupModel?> getMeetupById(String id) async {
    return getMeetup(id);
  }

  // Join Meetup (Bonus for Phase 2)
  Future<void> joinMeetup(String meetupId, String userId) async {
    // Transaction returns whether user was newly added
    final isNewJoin = await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);
      final participantSnapshot = await transaction.get(participantRef);

      if (!snapshot.exists) throw Exception('Meetup not found');
      if (participantSnapshot.exists) return false; // Already joined

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      // Double-check: Also verify participantIds array for consistency
      if (meetup.participantIds.contains(userId)) {
        return false; // Already in participantIds, skip to avoid counter inflation
      }

      if (meetup.isFootballWithTeams) {
        throw Exception(
          'Bu futbol etkinligine katilmak icin pozisyon secmelisiniz',
        );
      }

      if (meetup.currentParticipants >= meetup.maxParticipants) {
        throw Exception('Meetup is full');
      }

      // Add user to participants subcollection
      transaction.set(participantRef, {
        'joinedAt': FieldValue.serverTimestamp(),
      });

      // Increment counter and add to participantIds array
      transaction.update(docRef, {
        'currentParticipants': FieldValue.increment(1),
        'isFull': (meetup.currentParticipants + 1) >= meetup.maxParticipants,
        'participantState': _participantStateFor(
          meetup.currentParticipants + 1,
          meetup.maxParticipants,
        ),
        'availableSpots': (meetup.maxParticipants - (meetup.currentParticipants + 1))
            .clamp(0, meetup.maxParticipants),
        'participantIds': FieldValue.arrayUnion([userId]),
        'waitlistUserIds': FieldValue.arrayRemove([
          userId,
        ]), // Remove from waitlist if present
      });
      return true;
    });

    // isNewJoin is intentionally kept to preserve transaction semantics.
    // Registered counters are synced server-side from participant documents.
    if (!isNewJoin) return;
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

  // Join Waitlist - Add user to waitlist when event is full
  Future<void> joinWaitlist(String meetupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('Meetup not found');

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      // Don't allow joining waitlist if user is already a participant
      if (meetup.participantIds.contains(userId)) {
        throw Exception('You are already a participant');
      }

      // Don't allow joining waitlist if already on it
      if (meetup.waitlistUserIds.contains(userId)) {
        return; // Already on waitlist
      }

      // Add user to waitlist
      transaction.update(docRef, {
        'waitlistUserIds': FieldValue.arrayUnion([userId]),
      });
    });
  }

  // Leave Waitlist - Remove user from waitlist
  Future<void> leaveWaitlist(String meetupId, String userId) async {
    await _meetupsRef.doc(meetupId).update({
      'waitlistUserIds': FieldValue.arrayRemove([userId]),
    });
  }

  // Check if user is on waitlist
  Future<bool> isOnWaitlist(String meetupId, String userId) async {
    final doc = await _meetupsRef.doc(meetupId).get();
    if (!doc.exists) return false;

    final meetup = MeetupModel.fromJson(doc.data() as Map<String, dynamic>);
    return meetup.waitlistUserIds.contains(userId);
  }

  // Leave Meetup - Remove user from meetup participants
  Future<void> leaveMeetup(String meetupId, String userId) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);

      if (!snapshot.exists) throw Exception('Meetup not found');

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      // Organizer cannot leave their own meetup
      if (meetup.organizerId == userId) {
        throw Exception('Organizatör kendi etkinliğinden ayrılamaz');
      }

      // Check if user is actually a participant
      if (!meetup.participantIds.contains(userId)) {
        throw Exception('Bu etkinliğe katılmadınız');
      }

      // Remove user from participants subcollection
      transaction.delete(participantRef);

      // Prepare update data
      final updateData = <String, dynamic>{
        'currentParticipants': FieldValue.increment(-1),
        'isFull': false, // No longer full since someone left
        'participantState': _participantStateFor(
          meetup.currentParticipants - 1,
          meetup.maxParticipants,
        ),
        'availableSpots': (meetup.maxParticipants - (meetup.currentParticipants - 1))
            .clamp(0, meetup.maxParticipants),
        'participantIds': FieldValue.arrayRemove([userId]),
      };

      // If football meetup with teams, clear the user's position slot
      if (meetup.isFootballWithTeams) {
        // Find and clear user's slot in Team A
        if (meetup.teamASlots != null) {
          final hasUserInTeamA = meetup.teamASlots!.any(
            (slot) => slot.assignedUserId == userId,
          );
          if (hasUserInTeamA) {
            final updatedTeamASlots = meetup.teamASlots!.map((slot) {
              if (slot.assignedUserId == userId) {
                return slot.clearUser();
              }
              return slot;
            }).toList();
            updateData['teamASlots'] = updatedTeamASlots
                .map((s) => s.toJson())
                .toList();
          }
        }

        // Find and clear user's slot in Team B
        if (meetup.teamBSlots != null) {
          final hasUserInTeamB = meetup.teamBSlots!.any(
            (slot) => slot.assignedUserId == userId,
          );
          if (hasUserInTeamB) {
            final updatedTeamBSlots = meetup.teamBSlots!.map((slot) {
              if (slot.assignedUserId == userId) {
                return slot.clearUser();
              }
              return slot;
            }).toList();
            updateData['teamBSlots'] = updatedTeamBSlots
                .map((s) => s.toJson())
                .toList();
          }
        }
      }

      // Decrement counter and remove from participantIds array
      transaction.update(docRef, updateData);
    });
  }

  /// Join a football meetup with position selection
  Future<void> joinMeetupWithPosition({
    required String meetupId,
    required String userId,
    required String userName,
    required String team, // "A" or "B"
    required int slotIndex,
    String? userImageUrl,
  }) async {
    await _firestore.runTransaction((transaction) async {
      final docRef = _meetupsRef.doc(meetupId);
      final participantRef = docRef.collection('participants').doc(userId);

      final snapshot = await transaction.get(docRef);
      final participantSnapshot = await transaction.get(participantRef);

      if (!snapshot.exists) throw Exception('Etkinlik bulunamadı');

      final meetup = MeetupModel.fromJson(
        snapshot.data() as Map<String, dynamic>,
      );

      // Check if already a participant
      if (participantSnapshot.exists ||
          meetup.participantIds.contains(userId)) {
        throw Exception('Zaten bu etkinliğe katıldınız');
      }

      // Check if meetup is full
      if (meetup.currentParticipants >= meetup.maxParticipants) {
        throw Exception('Etkinlik dolu');
      }

      // Validate team and slot
      List<PositionSlot>? slots;
      String slotsField;

      if (team == 'A') {
        slots = meetup.teamASlots;
        slotsField = 'teamASlots';
      } else if (team == 'B') {
        slots = meetup.teamBSlots;
        slotsField = 'teamBSlots';
      } else {
        throw Exception('Geçersiz takım seçimi');
      }

      if (slots == null || slotIndex < 0 || slotIndex >= slots.length) {
        throw Exception('Geçersiz pozisyon seçimi');
      }

      final selectedSlot = slots[slotIndex];

      // Check if slot is already taken (concurrent access protection)
      if (selectedSlot.isFilled) {
        throw Exception(
          'Bu pozisyon zaten dolu. Lütfen başka bir pozisyon seçin.',
        );
      }

      // Assign user to the slot
      final updatedSlots = List<PositionSlot>.from(slots);
      updatedSlots[slotIndex] = selectedSlot.assignUser(
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
      );

      // Add user to participants subcollection
      transaction.set(participantRef, {
        'joinedAt': FieldValue.serverTimestamp(),
        'team': team,
        'slotIndex': slotIndex,
        'position': selectedSlot.position,
      });

      // Update meetup document
      transaction.update(docRef, {
        'currentParticipants': FieldValue.increment(1),
        'isFull': (meetup.currentParticipants + 1) >= meetup.maxParticipants,
        'participantState': _participantStateFor(
          meetup.currentParticipants + 1,
          meetup.maxParticipants,
        ),
        'availableSpots': (meetup.maxParticipants - (meetup.currentParticipants + 1))
            .clamp(0, meetup.maxParticipants),
        'participantIds': FieldValue.arrayUnion([userId]),
        'waitlistUserIds': FieldValue.arrayRemove([userId]),
        slotsField: updatedSlots.map((s) => s.toJson()).toList(),
      });
    });
  }

  // ── Active Meetup Methods ──────────────────────────────────────────

  /// Etkinliğin efektif bitiş zamanını hesaplar.
  /// endDate varsa onu döndürür, yoksa date + 2 saat.
  DateTime getEffectiveEndDate(MeetupModel meetup) {
    return meetup.endDate ?? meetup.date.add(const Duration(hours: 2));
  }

  /// Etkinliğin aktif olup olmadığını kontrol eder.
  /// date <= now < effectiveEndDate ise true döner.
  bool isMeetupActive(MeetupModel meetup, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final effectiveEnd = getEffectiveEndDate(meetup);
    return !meetup.date.isAfter(currentTime) &&
        currentTime.isBefore(effectiveEnd);
  }

  /// Kullanıcının aktif etkinliklerini getirir.
  Future<List<MeetupModel>> getActiveMeetupsForUser(String userId) async {
    final now = DateTime.now();
    final snapshot =
        await _meetupsRef
            .where('participantIds', arrayContains: userId)
            .get();

    return snapshot.docs
        .map((doc) => MeetupModel.fromJson(doc.data() as Map<String, dynamic>))
        .where((meetup) => isMeetupActive(meetup, now: now))
        .toList();
  }

  /// Tüm aktif etkinlikleri stream olarak getirir.
  Stream<List<MeetupModel>> getActiveMeetupsStream() {
    return _meetupsRef.snapshots().map((snapshot) {
      final now = DateTime.now();
      return snapshot.docs
          .map(
            (doc) =>
                MeetupModel.fromJson(doc.data() as Map<String, dynamic>),
          )
          .where((meetup) => isMeetupActive(meetup, now: now))
          .toList();
    });
  }
}
