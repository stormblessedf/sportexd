import 'profile_photo_model.dart';
import 'user_model.dart';

class SwipeCandidateModel {
  final UserModel user;
  final List<ProfilePhotoModel> photos;
  final int commonSportsCount;
  final double score;

  const SwipeCandidateModel({
    required this.user,
    this.photos = const [],
    this.commonSportsCount = 0,
    this.score = 0,
  });

  String? get primaryPhotoUrl {
    if (photos.isNotEmpty) {
      final url = photos.first.photoUrl;
      if (url.isNotEmpty) return url;
    }

    if (user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty) {
      return user.profileImageUrl;
    }

    return null;
  }
}
