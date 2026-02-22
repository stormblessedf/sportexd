import 'package:sporsal/core/models/event_photo_model.dart';

/// Sadece aktif etkinliklere ait fotoğrafları filtreler.
List<EventPhotoModel> filterLivePhotos(
  List<EventPhotoModel> photos,
  Set<String> activeMeetupIds,
) {
  return photos.where((photo) => activeMeetupIds.contains(photo.meetupId)).toList();
}

/// Fotoğrafları meetupId bazında gruplar, her grup içinde createdAt azalan sırada sıralar.
Map<String, List<EventPhotoModel>> groupPhotosByMeetup(
  List<EventPhotoModel> photos,
) {
  final map = <String, List<EventPhotoModel>>{};
  for (final photo in photos) {
    map.putIfAbsent(photo.meetupId, () => []).add(photo);
  }
  for (final list in map.values) {
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }
  return map;
}
