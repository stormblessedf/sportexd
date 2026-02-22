import 'package:sporsal/core/models/meetup_model.dart';

/// Factory functions for creating test data.
class TestFactory {
  static MeetupModel meetup({
    String id = 'test-meetup-1',
    String title = 'Test Futbol Maçı',
    String description = 'Test açıklama',
    MeetupType type = MeetupType.football,
    DateTime? date,
    String locationName = 'Test Saha',
    String locationAddress = 'Test Adres',
    String organizerId = 'user-1',
    String organizerName = 'Test User',
    int maxParticipants = 10,
    int currentParticipants = 1,
    List<String>? participantIds,
  }) {
    return MeetupModel(
      id: id,
      title: title,
      description: description,
      rules: '',
      imageUrl: 'https://example.com/image.jpg',
      type: type,
      date: date ?? DateTime.now().add(const Duration(hours: 2)),
      locationName: locationName,
      locationAddress: locationAddress,
      organizerId: organizerId,
      organizerName: organizerName,
      currentParticipants: currentParticipants,
      maxParticipants: maxParticipants,
      participantIds: participantIds ?? [organizerId],
    );
  }
}
