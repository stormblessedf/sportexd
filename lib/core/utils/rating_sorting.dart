import '../models/rating_model.dart';

/// Sorting utilities for ratings

class RatingSorting {
  /// Sort ratings by most recent (descending date order)
  static List<RatingModel> sortByMostRecent(List<RatingModel> ratings) {
    final sorted = List<RatingModel>.from(ratings);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  /// Sort ratings by highest rating (descending rating order)
  static List<RatingModel> sortByHighest(List<RatingModel> ratings) {
    final sorted = List<RatingModel>.from(ratings);
    sorted.sort((a, b) => b.rating.compareTo(a.rating));
    return sorted;
  }

  /// Sort ratings by lowest rating (ascending rating order)
  static List<RatingModel> sortByLowest(List<RatingModel> ratings) {
    final sorted = List<RatingModel>.from(ratings);
    sorted.sort((a, b) => a.rating.compareTo(b.rating));
    return sorted;
  }
}
