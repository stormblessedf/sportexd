import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Utility to recalculate all user rating statistics
/// This should be run once to fix existing data
Future<void> recalculateAllUserRatings() async {
  final firestore = FirebaseFirestore.instance;
  
  try {
    debugPrint('=== STARTING RATING RECALCULATION ===');
    
    // Get all ratings
    final ratingsSnapshot = await firestore.collection('ratings').get();
    debugPrint('Found ${ratingsSnapshot.docs.length} ratings');
    
    // Group ratings by ratedUserId
    final Map<String, List<double>> userRatings = {};
    
    for (final ratingDoc in ratingsSnapshot.docs) {
      final data = ratingDoc.data();
      final ratedUserId = data['ratedUserId'] as String?;
      final rating = (data['rating'] ?? 0.0) as num;
      
      if (ratedUserId != null) {
        if (!userRatings.containsKey(ratedUserId)) {
          userRatings[ratedUserId] = [];
        }
        userRatings[ratedUserId]!.add(rating.toDouble());
      }
    }
    
    debugPrint('Found ${userRatings.length} users with ratings');
    
    // Update each user's stats
    int updatedCount = 0;
    for (final entry in userRatings.entries) {
      final userId = entry.key;
      final ratings = entry.value;
      
      if (ratings.isEmpty) continue;
      
      final totalRatings = ratings.length;
      final sum = ratings.reduce((a, b) => a + b);
      final average = sum / totalRatings;
      final roundedAverage = (average * 10).round() / 10;
      
      try {
        await firestore.collection('users').doc(userId).update({
          'averageRating': roundedAverage,
          'totalRatings': totalRatings,
        });
        
        updatedCount++;
        debugPrint('Updated user $userId: $roundedAverage ($totalRatings ratings)');
      } catch (e) {
        debugPrint('Error updating user $userId: $e');
      }
    }
    
    debugPrint('=== RECALCULATION COMPLETE ===');
    debugPrint('Updated $updatedCount users');
    
  } catch (e) {
    debugPrint('Error recalculating ratings: $e');
    rethrow;
  }
}
