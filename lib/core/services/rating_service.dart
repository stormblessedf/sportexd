import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/rating_model.dart';
import '../models/user_model.dart';

class RatingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Validates rating value (1.0 - 5.0)
  void validateRating(double rating) {
    if (rating < 1.0 || rating > 5.0) {
      throw ArgumentError('Rating must be between 1.0 and 5.0');
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

    // Check for duplicate rating
    final exists = await hasRated(
      meetupId: meetupId,
      raterId: raterId,
      ratedUserId: ratedUserId,
    );
    if (exists) {
      throw StateError('User has already rated this participant');
    }

    try {
      final ratingId = _firestore.collection('ratings').doc().id;
      final ratingModel = RatingModel(
        id: ratingId,
        meetupId: meetupId,
        raterId: raterId,
        ratedUserId: ratedUserId,
        rating: rating,
        comment: comment,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('ratings').doc(ratingId).set(ratingModel.toJson());

      // Update the rated user's average rating
      await updateUserAverageRating(ratedUserId);
    } catch (e) {
      debugPrint('Error creating rating: $e');
      rethrow;
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

  /// Updates user's average rating in Firestore
  Future<void> updateUserAverageRating(String userId) async {
    try {
      final ratings = await getUserRatings(userId);
      final totalRatings = ratings.length;
      final averageRating = totalRatings > 0
          ? calculateAverage(ratings.map((r) => r.rating).toList())
          : 0.0;

      await _firestore.collection('users').doc(userId).update({
        'averageRating': averageRating,
        'totalRatings': totalRatings,
      });
    } catch (e) {
      debugPrint('Error updating user average rating: $e');
      rethrow;
    }
  }

  /// Checks if a rating already exists
  Future<bool> hasRated({
    required String meetupId,
    required String raterId,
    required String ratedUserId,
  }) async {
    try {
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
  Future<List<UserModel>> getMeetupParticipants(String meetupId, String currentUserId) async {
    try {
      final meetupDoc = await _firestore.collection('meetups').doc(meetupId).get();
      if (!meetupDoc.exists) return [];

      final participantIds = List<String>.from(meetupDoc.data()?['participantIds'] ?? []);

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
          .where('date', isLessThan: DateTime.now().toIso8601String())
          .get();

      final pendingMeetupIds = <String>[];

      for (final meetup in meetupsSnapshot.docs) {
        final meetupId = meetup.id;
        final participantIds = List<String>.from(meetup.data()['participantIds'] ?? []);
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
}
