import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/event_photo_model.dart';
import 'package:sporsal/features/live_event/utils/live_feed_utils.dart';

EventPhotoModel _photo({
  required String meetupId,
  required DateTime createdAt,
  String id = '',
}) {
  return EventPhotoModel(
    id: id.isEmpty ? 'photo_${meetupId}_${createdAt.millisecondsSinceEpoch}' : id,
    meetupId: meetupId,
    userId: 'user1',
    userName: 'Test User',
    photoUrl: 'https://example.com/photo.jpg',
    createdAt: createdAt,
  );
}

void main() {
  group('filterLivePhotos', () {
    test('returns only photos with meetupId in activeMeetupIds', () {
      final photos = [
        _photo(meetupId: 'a', createdAt: DateTime(2024, 1, 1)),
        _photo(meetupId: 'b', createdAt: DateTime(2024, 1, 2)),
        _photo(meetupId: 'c', createdAt: DateTime(2024, 1, 3)),
      ];
      final result = filterLivePhotos(photos, {'a', 'c'});
      expect(result.length, 2);
      expect(result.map((p) => p.meetupId).toSet(), {'a', 'c'});
    });

    test('returns empty list when no meetupIds match', () {
      final photos = [
        _photo(meetupId: 'a', createdAt: DateTime(2024, 1, 1)),
      ];
      final result = filterLivePhotos(photos, {'x', 'y'});
      expect(result, isEmpty);
    });

    test('returns empty list when photos list is empty', () {
      final result = filterLivePhotos([], {'a'});
      expect(result, isEmpty);
    });

    test('returns empty list when activeMeetupIds is empty', () {
      final photos = [
        _photo(meetupId: 'a', createdAt: DateTime(2024, 1, 1)),
      ];
      final result = filterLivePhotos(photos, {});
      expect(result, isEmpty);
    });
  });

  group('groupPhotosByMeetup', () {
    test('groups photos by meetupId', () {
      final photos = [
        _photo(meetupId: 'a', createdAt: DateTime(2024, 1, 1)),
        _photo(meetupId: 'b', createdAt: DateTime(2024, 1, 2)),
        _photo(meetupId: 'a', createdAt: DateTime(2024, 1, 3)),
      ];
      final result = groupPhotosByMeetup(photos);
      expect(result.keys.toSet(), {'a', 'b'});
      expect(result['a']!.length, 2);
      expect(result['b']!.length, 1);
    });

    test('sorts each group by createdAt descending', () {
      final t1 = DateTime(2024, 1, 1);
      final t2 = DateTime(2024, 1, 2);
      final t3 = DateTime(2024, 1, 3);
      final photos = [
        _photo(meetupId: 'a', createdAt: t1, id: 'p1'),
        _photo(meetupId: 'a', createdAt: t3, id: 'p3'),
        _photo(meetupId: 'a', createdAt: t2, id: 'p2'),
      ];
      final result = groupPhotosByMeetup(photos);
      final group = result['a']!;
      expect(group[0].id, 'p3'); // newest first
      expect(group[1].id, 'p2');
      expect(group[2].id, 'p1');
    });

    test('returns empty map for empty list', () {
      final result = groupPhotosByMeetup([]);
      expect(result, isEmpty);
    });
  });
}
