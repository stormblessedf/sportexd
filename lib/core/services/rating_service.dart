import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart' hide Badge;
import '../models/rating_model.dart';
import '../models/user_model.dart';
import '../models/rating_distribution.dart';
import '../models/eligible_meetup.dart';
import 'badge_award_service.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BadgeAwardService _badgeAwardService;

  RatingService({BadgeAwardService? badgeAwardService})
      : _badgeAwardService = badgeAwardService ?? BadgeAwardService();

  String _buildRatingDocId(String meetupId, String raterId, String ratedUserId) {
    return '${meetupId}_${raterId}_$ratedUserId';
  }

  /// Validates rating value (1.0 - 5.0)
  void validateRating(double rating) {
    if (rating < 1.0 || rating > 5.0) {
      throw ArgumentError('Rating must be between 1.0 and 5.0');
    }
  }

  /// Submits a new rating with validation and transaction support
  Future<void> submitRating(RatingModel rating) async {
    try {
      // Validation
      if (rating.rating < 1.0 || rating.rating > 5.0) {
        throw ArgumentError('Rating must be between 1.0 and 5.0');
      }

      if (rating.raterId == rating.ratedUserId) {
        throw ArgumentError('Users cannot rate themselves');
      }

      if (rating.comment != null && rating.comment!.length > 200) {
        throw ArgumentError('Comment must be 200 characters or less');
      }

      // Validate both users participated in the meetup
      final meetupDoc = await _firestore
          .collection('meetups')
          .doc(rating.meetupId)
          .get();
      if (!meetupDoc.exists) {
        throw StateError('Buluşma bulunamadı');
      }
      final participantIds = List<String>.from(
        meetupDoc.data()?['participantIds'] ?? [],
      );
      if (!participantIds.contains(rating.raterId) ||
          !participantIds.contains(rating.ratedUserId)) {
        throw StateError('Her iki kullanıcı da bu buluşmaya katılmış olmalı');
      }

      final ratingDocId = _buildRatingDocId(
        rating.meetupId,
        rating.raterId,
        rating.ratedUserId,
      );

      // Backward-compatibility check for pre-existing legacy documents.
      // New writes use deterministic IDs and are protected in transaction below.
      final legacyDuplicate = await _firestore
          .collection('ratings')
          .where('raterId', isEqualTo: rating.raterId)
          .where('ratedUserId', isEqualTo: rating.ratedUserId)
          .where('meetupId', isEqualTo: rating.meetupId)
          .limit(1)
          .get();

      if (legacyDuplicate.docs.isNotEmpty) {
        throw StateError(
          'User has already rated this participant for this meetup',
        );
      }

      // Fetch rater info to store with rating
      String? raterName;
      String? raterPhotoUrl;
      try {
        final raterDoc = await _firestore
            .collection('users')
            .doc(rating.raterId)
            .get();
        if (raterDoc.exists) {
          final raterData = raterDoc.data()!;
          raterName =
              raterData['username'] as String? ?? raterData['name'] as String?;
          raterPhotoUrl = raterData['profileImageUrl'] as String?;
        }
      } catch (e) {
        debugPrint('Error fetching rater info: $e');
      }

      // Fetch meetup info
      String? meetupTitle;
      String? sportType;
      try {
        final meetupDoc = await _firestore
            .collection('meetups')
            .doc(rating.meetupId)
            .get();
        if (meetupDoc.exists) {
          final meetupData = meetupDoc.data()!;
          meetupTitle = meetupData['title'] as String?;
          sportType = meetupData['type'] as String?;
        }
      } catch (e) {
        debugPrint('Error fetching meetup info: $e');
      }

      // Create rating with all info
      final ratingWithInfo = rating.copyWith(
        id: ratingDocId,
        raterName: raterName,
        raterPhotoUrl: raterPhotoUrl,
        meetupTitle: meetupTitle,
        sportType: sportType,
      );

      final ratingRef = _firestore.collection('ratings').doc(ratingDocId);

      await _firestore.runTransaction((transaction) async {
        final existingRatingDoc = await transaction.get(ratingRef);
        if (existingRatingDoc.exists) {
          throw StateError(
            'User has already rated this participant for this meetup',
          );
        }

        // User rating aggregates (averageRating/totalRatings) are updated server-side
        // by Cloud Function to avoid cross-user client writes.
        transaction.set(ratingRef, ratingWithInfo.toJson());
      });

      debugPrint('Rating submitted successfully');

      // Fire-and-forget badge evaluation for the rated user
      _badgeAwardService.evaluateAndAwardBadges(rating.ratedUserId).catchError((e) {
        debugPrint('Badge evaluation failed: $e');
        return <Badge>[];
      });
    } catch (e) {
      debugPrint('Error submitting rating: $e');
      rethrow;
    }
  }

  /// Creates a new rating
  Future<void> createRating({
    required String meetupId,
    required String raterId,
    required String ratedUserId,
    required double rating,
    String? comment,
  }) async {
    // Validation
    validateRating(rating);

    if (raterId == ratedUserId) {
      throw ArgumentError('Users cannot rate themselves');
    }

    final ratingModel = RatingModel(
      id: _buildRatingDocId(meetupId, raterId, ratedUserId),
      meetupId: meetupId,
      raterId: raterId,
      ratedUserId: ratedUserId,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    try {
      await submitRating(ratingModel);
    } catch (e) {
      debugPrint('Error creating rating: $e');
      rethrow;
    }
  }

  /// Gets all ratings received by a user (ratings where they are the ratedUserId)
  Future<List<RatingModel>> getRatingsForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final ratings = <RatingModel>[];

      for (final doc in snapshot.docs) {
        final ratingData = doc.data();
        var rating = RatingModel.fromJson(ratingData);

        // If raterName is missing, fetch from user doc
        if (rating.raterName == null || rating.raterName!.isEmpty) {
          try {
            final raterDoc = await _firestore
                .collection('users')
                .doc(rating.raterId)
                .get();
            if (raterDoc.exists) {
              final raterData = raterDoc.data()!;
              rating = rating.copyWith(
                raterName:
                    raterData['username'] as String? ??
                    raterData['name'] as String?,
                raterPhotoUrl: raterData['profileImageUrl'] as String?,
              );
            }
          } catch (e) {
            debugPrint('Error fetching rater info: $e');
          }
        }

        // If meetupTitle is missing, fetch from meetup doc
        if (rating.meetupTitle == null) {
          try {
            final meetupDoc = await _firestore
                .collection('meetups')
                .doc(rating.meetupId)
                .get();
            if (meetupDoc.exists) {
              final meetupData = meetupDoc.data()!;
              rating = rating.copyWith(
                meetupTitle: meetupData['title'] as String?,
                sportType: meetupData['type'] as String?,
              );
            }
          } catch (e) {
            debugPrint('Error fetching meetup details: $e');
          }
        }

        ratings.add(rating);
      }

      return ratings;
    } catch (e) {
      debugPrint('Error getting ratings for user: $e');
      return [];
    }
  }

  /// Gets all ratings given by a user (ratings where they are the raterId)
  Future<List<RatingModel>> getRatingsGivenByUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('raterId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      final ratings = <RatingModel>[];

      for (final doc in snapshot.docs) {
        final ratingData = doc.data();
        var rating = RatingModel.fromJson(ratingData);

        // Fetch rated user info
        try {
          final ratedUserDoc = await _firestore
              .collection('users')
              .doc(rating.ratedUserId)
              .get();
          if (ratedUserDoc.exists) {
            final ratedUserData = ratedUserDoc.data()!;
            rating = rating.copyWith(
              raterName:
                  ratedUserData['username'] as String? ??
                  ratedUserData['name'] as String?,
              raterPhotoUrl: ratedUserData['profileImageUrl'] as String?,
            );
          }
        } catch (e) {
          debugPrint('Error fetching rated user info: $e');
        }

        // Fetch meetup info if missing
        if (rating.meetupTitle == null) {
          try {
            final meetupDoc = await _firestore
                .collection('meetups')
                .doc(rating.meetupId)
                .get();
            if (meetupDoc.exists) {
              final meetupData = meetupDoc.data()!;
              rating = rating.copyWith(
                meetupTitle: meetupData['title'] as String?,
                sportType: meetupData['type'] as String?,
              );
            }
          } catch (e) {
            debugPrint('Error fetching meetup details: $e');
          }
        }

        ratings.add(rating);
      }

      return ratings;
    } catch (e) {
      debugPrint('Error getting ratings given by user: $e');
      return [];
    }
  }

  /// Gets all ratings for a user
  Future<List<RatingModel>> getUserRatings(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => RatingModel.fromJson(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting user ratings: $e');
      return [];
    }
  }

  /// Gets rating distribution for a user
  Future<RatingDistribution> getRatingDistribution(String userId) async {
    try {
      final ratings = await getUserRatings(userId);

      if (ratings.isEmpty) {
        return RatingDistribution.empty();
      }

      int fiveStarCount = 0;
      int fourStarCount = 0;
      int threeStarCount = 0;
      int twoStarCount = 0;
      int oneStarCount = 0;

      for (final rating in ratings) {
        final ratingValue = rating.rating.round();
        switch (ratingValue) {
          case 5:
            fiveStarCount++;
            break;
          case 4:
            fourStarCount++;
            break;
          case 3:
            threeStarCount++;
            break;
          case 2:
            twoStarCount++;
            break;
          case 1:
            oneStarCount++;
            break;
        }
      }

      return RatingDistribution(
        fiveStarCount: fiveStarCount,
        fourStarCount: fourStarCount,
        threeStarCount: threeStarCount,
        twoStarCount: twoStarCount,
        oneStarCount: oneStarCount,
      );
    } catch (e) {
      debugPrint('Error getting rating distribution: $e');
      return RatingDistribution.empty();
    }
  }

  /// Calculates average rating from a list of ratings
  double calculateAverage(List<double> ratings) {
    if (ratings.isEmpty) return 0.0;
    final sum = ratings.reduce((a, b) => a + b);
    return sum / ratings.length;
  }

  /// Calculates average rating for a user
  Future<double> calculateAverageRating(String userId) async {
    final ratings = await getUserRatings(userId);
    if (ratings.isEmpty) return 0.0;

    final ratingValues = ratings.map((r) => r.rating).toList();
    return calculateAverage(ratingValues);
  }

  /// Gets eligible meetups for rating between two users
  Future<List<EligibleMeetup>> getEligibleMeetups(
    String currentUserId,
    String profileOwnerId,
  ) async {
    try {
      debugPrint('=== GET ELIGIBLE MEETUPS ===');
      debugPrint('Current User: $currentUserId');
      debugPrint('Profile Owner: $profileOwnerId');

      final now = DateTime.now();

      // Get all past meetups where both users participated
      final meetupsSnapshot = await _firestore
          .collection('meetups')
          .where('participantIds', arrayContains: currentUserId)
          .get();

      debugPrint(
        'Found ${meetupsSnapshot.docs.length} meetups with current user',
      );

      final eligibleMeetups = <EligibleMeetup>[];

      for (final meetupDoc in meetupsSnapshot.docs) {
        final meetupData = meetupDoc.data();
        final participantIds = List<String>.from(
          meetupData['participantIds'] ?? [],
        );

        debugPrint('Checking meetup: ${meetupData['title']}');
        debugPrint('  Participants: $participantIds');

        // Check if profile owner also participated
        if (!participantIds.contains(profileOwnerId)) {
          debugPrint('  ❌ Profile owner not in this meetup');
          continue;
        }

        // Parse meetup date
        DateTime meetupDate;
        final dateValue = meetupData['date'];
        if (dateValue is Timestamp) {
          meetupDate = dateValue.toDate();
        } else if (dateValue is String) {
          meetupDate = DateTime.tryParse(dateValue) ?? DateTime.now();
        } else {
          debugPrint('  ❌ Invalid date format');
          continue;
        }

        debugPrint('  Date: $meetupDate');
        debugPrint('  Is past: ${meetupDate.isBefore(now)}');

        // Check if meetup is in the past
        if (!meetupDate.isBefore(now)) {
          debugPrint('  ❌ Meetup is not in the past');
          continue;
        }

        // Check if current user has already rated profile owner for this meetup
        final hasRated = await hasRatedUserInMeetup(
          currentUserId,
          profileOwnerId,
          meetupDoc.id,
        );

        debugPrint('  Has rated: $hasRated');

        if (!hasRated) {
          debugPrint('  ✅ Eligible!');
          eligibleMeetups.add(
            EligibleMeetup(
              meetupId: meetupDoc.id,
              title: meetupData['title'] ?? 'Untitled Meetup',
              date: meetupDate,
              sportType: meetupData['type'] ?? 'other',
              hasRated: false,
            ),
          );
        } else {
          debugPrint('  ❌ Already rated');
        }
      }

      // Sort by date descending (most recent first)
      eligibleMeetups.sort((a, b) => b.date.compareTo(a.date));

      debugPrint('Total eligible meetups: ${eligibleMeetups.length}');

      return eligibleMeetups;
    } catch (e) {
      debugPrint('Error getting eligible meetups: $e');
      return [];
    }
  }

  /// Checks if user has rated another user in a specific meetup
  Future<bool> hasRatedUserInMeetup(
    String raterId,
    String ratedUserId,
    String meetupId,
  ) async {
    try {
      final deterministicDoc = await _firestore
          .collection('ratings')
          .doc(_buildRatingDocId(meetupId, raterId, ratedUserId))
          .get();
      if (deterministicDoc.exists) return true;

      // Fallback query for legacy random-ID rating docs.
      final snapshot = await _firestore
          .collection('ratings')
          .where('raterId', isEqualTo: raterId)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .where('meetupId', isEqualTo: meetupId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user has rated in meetup: $e');
      return false;
    }
  }

  /// Checks if a rating already exists
  Future<bool> hasRated({
    required String meetupId,
    required String raterId,
    required String ratedUserId,
  }) async {
    try {
      final deterministicDoc = await _firestore
          .collection('ratings')
          .doc(_buildRatingDocId(meetupId, raterId, ratedUserId))
          .get();
      if (deterministicDoc.exists) return true;

      // Fallback query for legacy random-ID rating docs.
      final snapshot = await _firestore
          .collection('ratings')
          .where('meetupId', isEqualTo: meetupId)
          .where('raterId', isEqualTo: raterId)
          .where('ratedUserId', isEqualTo: ratedUserId)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      debugPrint('Error checking if user has rated: $e');
      return false;
    }
  }

  /// Gets participants of a meetup for rating
  Future<List<UserModel>> getMeetupParticipants(
    String meetupId,
    String currentUserId,
  ) async {
    try {
      final meetupDoc = await _firestore
          .collection('meetups')
          .doc(meetupId)
          .get();
      if (!meetupDoc.exists) return [];

      final participantIds = List<String>.from(
        meetupDoc.data()?['participantIds'] ?? [],
      );

      // Remove current user from list
      participantIds.remove(currentUserId);

      if (participantIds.isEmpty) return [];

      final participants = <UserModel>[];
      for (final id in participantIds) {
        final userDoc = await _firestore.collection('users').doc(id).get();
        if (userDoc.exists) {
          participants.add(UserModel.fromJson(userDoc.data()!));
        }
      }

      return participants;
    } catch (e) {
      debugPrint('Error getting meetup participants: $e');
      return [];
    }
  }

  /// Gets pending ratings for a user (meetups they haven't rated yet)
  Future<List<String>> getPendingRatings(String userId) async {
    try {
      // Get meetups where user participated and are completed
      final meetupsSnapshot = await _firestore
          .collection('meetups')
          .where('participantIds', arrayContains: userId)
          .where('date', isLessThan: Timestamp.fromDate(DateTime.now()))
          .get();

      final pendingMeetupIds = <String>[];

      for (final meetup in meetupsSnapshot.docs) {
        final meetupId = meetup.id;
        final participantIds = List<String>.from(
          meetup.data()['participantIds'] ?? [],
        );
        participantIds.remove(userId);

        // Check if user has rated all participants
        bool hasRatedAll = true;
        for (final participantId in participantIds) {
          final hasRatedParticipant = await hasRated(
            meetupId: meetupId,
            raterId: userId,
            ratedUserId: participantId,
          );
          if (!hasRatedParticipant) {
            hasRatedAll = false;
            break;
          }
        }

        if (!hasRatedAll && participantIds.isNotEmpty) {
          pendingMeetupIds.add(meetupId);
        }
      }

      return pendingMeetupIds;
    } catch (e) {
      debugPrint('Error getting pending ratings: $e');
      return [];
    }
  }

  /// Recalculates rating stats for a single user from all their ratings
  /// This is useful for fixing inconsistencies or after data migration
  Future<void> recalculateUserRating(String userId) async {
    try {
      debugPrint('Recalculating ratings for user: $userId');

      // Get all ratings for this user
      final ratingsSnapshot = await _firestore
          .collection('ratings')
          .where('ratedUserId', isEqualTo: userId)
          .get();

      final ratings = ratingsSnapshot.docs;
      final totalRatings = ratings.length;

      double averageRating = 0.0;
      if (totalRatings > 0) {
        double sum = 0.0;
        for (final doc in ratings) {
          final data = doc.data();
          sum += (data['rating'] ?? 0.0).toDouble();
        }
        averageRating = sum / totalRatings;
        averageRating = (averageRating * 10).round() / 10; // Round to 1 decimal
      }

      // Update user document
      await _firestore.collection('users').doc(userId).update({
        'averageRating': averageRating,
        'totalRatings': totalRatings,
      });

      debugPrint(
        'User $userId: $totalRatings ratings, average: $averageRating',
      );
    } catch (e) {
      debugPrint('Error recalculating user rating: $e');
      rethrow;
    }
  }

  /// Recalculates rating stats for ALL users
  /// Use this after migrating data or to fix any inconsistencies
  Future<Map<String, dynamic>> recalculateAllUserRatings() async {
    try {
      debugPrint('=== RECALCULATING ALL USER RATINGS ===');

      // Get all ratings
      final ratingsSnapshot = await _firestore.collection('ratings').get();
      debugPrint('Total ratings in database: ${ratingsSnapshot.docs.length}');

      // Group ratings by ratedUserId
      final Map<String, List<double>> userRatings = {};

      for (final doc in ratingsSnapshot.docs) {
        final data = doc.data();
        final ratedUserId = data['ratedUserId'] as String?;
        final rating = (data['rating'] ?? 0.0).toDouble();

        if (ratedUserId != null && rating > 0) {
          userRatings.putIfAbsent(ratedUserId, () => []);
          userRatings[ratedUserId]!.add(rating);
        }
      }

      debugPrint('Users with ratings: ${userRatings.length}');

      // Update each user (chunked to 500 per batch - Firestore limit)
      int updatedCount = 0;
      WriteBatch batch = _firestore.batch();
      int batchCount = 0;

      for (final entry in userRatings.entries) {
        final userId = entry.key;
        final ratings = entry.value;
        final totalRatings = ratings.length;
        final sum = ratings.reduce((a, b) => a + b);
        final averageRating = (sum / totalRatings * 10).round() / 10;

        final userRef = _firestore.collection('users').doc(userId);
        batch.update(userRef, {
          'averageRating': averageRating,
          'totalRatings': totalRatings,
        });

        debugPrint('  $userId: $totalRatings ratings, avg: $averageRating');
        updatedCount++;
        batchCount++;

        // Firestore batch limit is 500 writes
        if (batchCount >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchCount = 0;
        }
      }

      // Commit remaining
      if (batchCount > 0) {
        await batch.commit();
      }

      debugPrint('=== RECALCULATION COMPLETE: $updatedCount users updated ===');

      return {
        'success': true,
        'totalRatings': ratingsSnapshot.docs.length,
        'usersUpdated': updatedCount,
      };
    } catch (e) {
      debugPrint('Error recalculating all user ratings: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
