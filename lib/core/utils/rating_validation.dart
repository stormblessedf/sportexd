// Validation utilities for rating submissions
class RatingValidation {
  /// Validates rating value is between 1 and 5
  static bool validateRatingValue(double rating) {
    return rating >= 1.0 && rating <= 5.0;
  }

  /// Validates comment length is 200 characters or less
  static bool validateCommentLength(String? comment) {
    if (comment == null) return true;
    return comment.length <= 200;
  }

  /// Validates user is not rating themselves
  static bool validateSelfRating(String raterId, String ratedUserId) {
    return raterId != ratedUserId;
  }

  /// Validates users have shared meetup participation
  static bool validateSharedMeetup(
    List<String> meetupParticipants,
    String raterId,
    String ratedUserId,
  ) {
    return meetupParticipants.contains(raterId) &&
        meetupParticipants.contains(ratedUserId);
  }

  /// Validates no duplicate rating exists
  static bool validateDuplicateRating(bool hasExistingRating) {
    return !hasExistingRating;
  }

  /// Get error message for rating value validation
  static String getRatingValueError() {
    return 'Please select a rating between 1 and 5 stars';
  }

  /// Get error message for comment length validation
  static String getCommentLengthError() {
    return 'Comment must be 200 characters or less';
  }

  /// Get error message for self-rating validation
  static String getSelfRatingError() {
    return 'You cannot rate yourself';
  }

  /// Get error message for shared meetup validation
  static String getSharedMeetupError() {
    return 'You can only rate users you\'ve participated with in past meetups';
  }

  /// Get error message for duplicate rating validation
  static String getDuplicateRatingError() {
    return 'You have already rated this user for this meetup';
  }
}
