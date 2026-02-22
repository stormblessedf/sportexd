import 'package:sporsal/core/models/user_model.dart';
import 'package:sporsal/core/models/meetup_model.dart';
import 'package:sporsal/core/models/position_slot.dart';
import 'package:sporsal/core/models/route_data.dart';

/// Builder pattern for creating [UserModel] instances in tests.
/// Provides sensible defaults for all fields with chainable setters.
class TestUserBuilder {
  String _id = 'test-user-1';
  String _username = 'TestUser';
  String _email = 'test@sporsal.com';
  String? _profileImageUrl;
  String? _bio;
  List<Certificate> _certificates = const [];
  List<Badge> _badges = const [];
  int _partnersCount = 0;
  List<String> _partners = const [];
  String? _location;
  String? _gender;
  DateTime? _birthDate;
  int? _height;
  int? _weight;
  List<SportType>? _interestedSports;
  Level? _level;
  List<PreferredTime>? _preferredTimes;
  PlayStyle? _playStyle;
  String? _teamPreference;
  double _reliabilityScore = 100.0;
  int _totalMeetupsJoined = 0;
  int _totalMeetupsRegistered = 0;
  double _averageRating = 0.0;
  int _totalRatings = 0;
  DateTime? _lastSeen;
  bool _isOnline = false;

  TestUserBuilder withId(String id) {
    _id = id;
    return this;
  }

  TestUserBuilder withUsername(String username) {
    _username = username;
    return this;
  }

  TestUserBuilder withEmail(String email) {
    _email = email;
    return this;
  }

  TestUserBuilder withProfileImageUrl(String? url) {
    _profileImageUrl = url;
    return this;
  }

  TestUserBuilder withBio(String? bio) {
    _bio = bio;
    return this;
  }

  TestUserBuilder withCertificates(List<Certificate> certificates) {
    _certificates = certificates;
    return this;
  }

  TestUserBuilder withBadges(List<Badge> badges) {
    _badges = badges;
    return this;
  }

  TestUserBuilder withPartnersCount(int count) {
    _partnersCount = count;
    return this;
  }

  TestUserBuilder withPartners(List<String> partners) {
    _partners = partners;
    return this;
  }

  TestUserBuilder withLocation(String? location) {
    _location = location;
    return this;
  }

  TestUserBuilder withGender(String? gender) {
    _gender = gender;
    return this;
  }

  TestUserBuilder withBirthDate(DateTime? birthDate) {
    _birthDate = birthDate;
    return this;
  }

  TestUserBuilder withHeight(int? height) {
    _height = height;
    return this;
  }

  TestUserBuilder withWeight(int? weight) {
    _weight = weight;
    return this;
  }

  TestUserBuilder withInterestedSports(List<SportType>? sports) {
    _interestedSports = sports;
    return this;
  }

  TestUserBuilder withLevel(Level? level) {
    _level = level;
    return this;
  }

  TestUserBuilder withPreferredTimes(List<PreferredTime>? times) {
    _preferredTimes = times;
    return this;
  }

  TestUserBuilder withPlayStyle(PlayStyle? style) {
    _playStyle = style;
    return this;
  }

  TestUserBuilder withTeamPreference(String? pref) {
    _teamPreference = pref;
    return this;
  }

  TestUserBuilder withReliabilityScore(double score) {
    _reliabilityScore = score;
    return this;
  }

  TestUserBuilder withTotalMeetupsJoined(int count) {
    _totalMeetupsJoined = count;
    return this;
  }

  TestUserBuilder withTotalMeetupsRegistered(int count) {
    _totalMeetupsRegistered = count;
    return this;
  }

  TestUserBuilder withAverageRating(double rating) {
    _averageRating = rating;
    return this;
  }

  TestUserBuilder withTotalRatings(int count) {
    _totalRatings = count;
    return this;
  }

  TestUserBuilder withLastSeen(DateTime? lastSeen) {
    _lastSeen = lastSeen;
    return this;
  }

  TestUserBuilder withIsOnline(bool isOnline) {
    _isOnline = isOnline;
    return this;
  }

  UserModel build() => UserModel(
        id: _id,
        username: _username,
        email: _email,
        profileImageUrl: _profileImageUrl,
        bio: _bio,
        certificates: _certificates,
        badges: _badges,
        partnersCount: _partnersCount,
        partners: _partners,
        location: _location,
        gender: _gender,
        birthDate: _birthDate,
        height: _height,
        weight: _weight,
        interestedSports: _interestedSports,
        level: _level,
        preferredTimes: _preferredTimes,
        playStyle: _playStyle,
        teamPreference: _teamPreference,
        reliabilityScore: _reliabilityScore,
        totalMeetupsJoined: _totalMeetupsJoined,
        totalMeetupsRegistered: _totalMeetupsRegistered,
        averageRating: _averageRating,
        totalRatings: _totalRatings,
        lastSeen: _lastSeen,
        isOnline: _isOnline,
      );
}

/// Builder pattern for creating [MeetupModel] instances in tests.
/// Provides sensible defaults for all fields with chainable setters.
/// The [build] method enforces currentParticipants <= maxParticipants.
class TestMeetupBuilder {
  String _id = 'test-meetup-1';
  String _title = 'Test Etkinlik';
  String _description = 'Test açıklama';
  String _rules = '';
  String _imageUrl = 'https://example.com/image.jpg';
  MeetupType _type = MeetupType.football;
  DateTime? _date;
  DateTime? _endDate;
  String _locationName = 'Test Saha';
  String _locationAddress = 'Test Adres, İstanbul';
  String _organizerId = 'organizer-1';
  String _organizerName = 'Test Organizer';
  String? _organizerImageUrl;
  double? _organizerRating;
  int _currentParticipants = 1;
  int _maxParticipants = 10;
  bool _isFull = false;
  List<String> _participantIds = const ['organizer-1'];
  List<String> _waitlistUserIds = const [];
  double? _latitude;
  double? _longitude;
  bool _isOrganizerOnlyChat = false;
  DateTime? _createdAt;
  String? _teamFormat;
  String? _formation;
  List<PositionSlot>? _teamASlots;
  List<PositionSlot>? _teamBSlots;
  RouteData? _routeData;

  TestMeetupBuilder withId(String id) {
    _id = id;
    return this;
  }

  TestMeetupBuilder withTitle(String title) {
    _title = title;
    return this;
  }

  TestMeetupBuilder withDescription(String description) {
    _description = description;
    return this;
  }

  TestMeetupBuilder withRules(String rules) {
    _rules = rules;
    return this;
  }

  TestMeetupBuilder withImageUrl(String url) {
    _imageUrl = url;
    return this;
  }

  TestMeetupBuilder withType(MeetupType type) {
    _type = type;
    return this;
  }

  TestMeetupBuilder withDate(DateTime date) {
    _date = date;
    return this;
  }

  TestMeetupBuilder withEndDate(DateTime? endDate) {
    _endDate = endDate;
    return this;
  }

  TestMeetupBuilder withLocationName(String name) {
    _locationName = name;
    return this;
  }

  TestMeetupBuilder withLocationAddress(String address) {
    _locationAddress = address;
    return this;
  }

  TestMeetupBuilder withOrganizerId(String id) {
    _organizerId = id;
    return this;
  }

  TestMeetupBuilder withOrganizerName(String name) {
    _organizerName = name;
    return this;
  }

  TestMeetupBuilder withOrganizerImageUrl(String? url) {
    _organizerImageUrl = url;
    return this;
  }

  TestMeetupBuilder withOrganizerRating(double? rating) {
    _organizerRating = rating;
    return this;
  }

  TestMeetupBuilder withCurrentParticipants(int count) {
    _currentParticipants = count;
    return this;
  }

  TestMeetupBuilder withMaxParticipants(int max) {
    _maxParticipants = max;
    return this;
  }

  TestMeetupBuilder withIsFull(bool isFull) {
    _isFull = isFull;
    return this;
  }

  TestMeetupBuilder withParticipantIds(List<String> ids) {
    _participantIds = ids;
    return this;
  }

  TestMeetupBuilder withWaitlistUserIds(List<String> ids) {
    _waitlistUserIds = ids;
    return this;
  }

  TestMeetupBuilder withLatitude(double? lat) {
    _latitude = lat;
    return this;
  }

  TestMeetupBuilder withLongitude(double? lng) {
    _longitude = lng;
    return this;
  }

  TestMeetupBuilder withIsOrganizerOnlyChat(bool value) {
    _isOrganizerOnlyChat = value;
    return this;
  }

  TestMeetupBuilder withCreatedAt(DateTime? createdAt) {
    _createdAt = createdAt;
    return this;
  }

  TestMeetupBuilder withTeamFormat(String? format) {
    _teamFormat = format;
    return this;
  }

  TestMeetupBuilder withFormation(String? formation) {
    _formation = formation;
    return this;
  }

  TestMeetupBuilder withTeamASlots(List<PositionSlot>? slots) {
    _teamASlots = slots;
    return this;
  }

  TestMeetupBuilder withTeamBSlots(List<PositionSlot>? slots) {
    _teamBSlots = slots;
    return this;
  }

  TestMeetupBuilder withRouteData(RouteData? routeData) {
    _routeData = routeData;
    return this;
  }

  MeetupModel build() {
    // Enforce invariant: currentParticipants <= maxParticipants
    final clampedCurrent = _currentParticipants > _maxParticipants
        ? _maxParticipants
        : _currentParticipants;

    return MeetupModel(
      id: _id,
      title: _title,
      description: _description,
      rules: _rules,
      imageUrl: _imageUrl,
      type: _type,
      date: _date ?? DateTime.now().add(const Duration(hours: 2)),
      endDate: _endDate,
      locationName: _locationName,
      locationAddress: _locationAddress,
      organizerId: _organizerId,
      organizerName: _organizerName,
      organizerImageUrl: _organizerImageUrl,
      organizerRating: _organizerRating,
      currentParticipants: clampedCurrent,
      maxParticipants: _maxParticipants,
      isFull: _isFull,
      participantIds: _participantIds,
      waitlistUserIds: _waitlistUserIds,
      latitude: _latitude,
      longitude: _longitude,
      isOrganizerOnlyChat: _isOrganizerOnlyChat,
      createdAt: _createdAt,
      teamFormat: _teamFormat,
      formation: _formation,
      teamASlots: _teamASlots,
      teamBSlots: _teamBSlots,
      routeData: _routeData,
    );
  }
}
