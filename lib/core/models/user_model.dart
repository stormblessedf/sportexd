import 'package:cloud_firestore/cloud_firestore.dart';

enum BadgeType { organizer, participant, achievement, milestone }

class Badge {
  final String id;
  final String name;
  final String description;
  final String iconPath; // Asset path or icon code
  final BadgeType type;

  const Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.iconPath,
    required this.type,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconPath': iconPath,
      'type': type.name,
    };
  }

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      iconPath: json['iconPath'] ?? '',
      type: BadgeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BadgeType.participant,
      ),
    );
  }
}

enum Level { beginner, intermediate, advanced }

enum PreferredTime {
  weekdayMorning,
  weekdayEvening,
  weekendMorning,
  weekendEvening,
}

enum PlayStyle { competitive, casual }

class Certificate {
  final String id;
  final String title;
  final String issuer;
  final String imageUrl;
  final DateTime dateDate;

  const Certificate({
    required this.id,
    required this.title,
    required this.issuer,
    required this.imageUrl,
    required this.dateDate,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'issuer': issuer,
      'imageUrl': imageUrl,
      'dateDate': dateDate.toIso8601String(),
    };
  }

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      issuer: json['issuer'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      dateDate: json['dateDate'] != null
          ? DateTime.parse(json['dateDate'])
          : DateTime.now(),
    );
  }
}

// Spor dallarÄ± enum
enum SportType {
  football,
  basketball,
  volleyball,
  tennis,
  swimming,
  running,
  cycling,
  yoga,
  fitness,
  boxing,
  tableTennis,
  badminton,
  other,
}

extension SportTypeExtension on SportType {
  String get displayName {
    switch (this) {
      case SportType.football:
        return 'Futbol';
      case SportType.basketball:
        return 'Basketbol';
      case SportType.volleyball:
        return 'Voleybol';
      case SportType.tennis:
        return 'Tenis';
      case SportType.swimming:
        return 'Y\u00FCzme';
      case SportType.running:
        return 'Ko\u015Fu';
      case SportType.cycling:
        return 'Bisiklet';
      case SportType.yoga:
        return 'Yoga';
      case SportType.fitness:
        return 'Fitness';
      case SportType.boxing:
        return 'Boks';
      case SportType.tableTennis:
        return 'Masa Tenisi';
      case SportType.badminton:
        return 'Badminton';
      case SportType.other:
        return 'Di\u011Fer';
    }
  }
}

extension SportTypeEmojiExtension on SportType {
  String get emoji {
    switch (this) {
      case SportType.football:
        return '\u{26BD}';
      case SportType.basketball:
        return '\u{1F3C0}';
      case SportType.volleyball:
        return '\u{1F3D0}';
      case SportType.tennis:
        return '\u{1F3BE}';
      case SportType.swimming:
        return '\u{1F3CA}';
      case SportType.running:
        return '\u{1F3C3}';
      case SportType.cycling:
        return '\u{1F6B4}';
      case SportType.yoga:
        return '\u{1F9D8}';
      case SportType.fitness:
        return '\u{1F4AA}';
      case SportType.boxing:
        return '\u{1F94A}';
      case SportType.tableTennis:
        return '\u{1F3D3}';
      case SportType.badminton:
        return '\u{1F3F8}';
      case SportType.other:
        return '\u{1F3C5}';
    }
  }

  String get label => '$emoji $displayName';
}

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final List<Certificate> certificates;
  final List<Badge> badges;
  final int partnersCount;
  final List<String> partners;
  final String? location;
  final String? gender;
  final DateTime? birthDate;
  final int? height; // cm cinsinden
  final int? weight; // kg cinsinden
  final List<SportType>? interestedSports;
  final Level? level;
  final List<PreferredTime>? preferredTimes;
  final PlayStyle? playStyle;
  final String? teamPreference;
  final bool isPremium;
  final DateTime? premiumUntil;

  // New fields for reliability, rating and online status
  final double reliabilityScore;
  final int totalMeetupsJoined;
  final int totalMeetupsRegistered;
  final double averageRating;
  final int totalRatings;
  final DateTime? lastSeen;
  final bool isOnline;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.bio,
    this.certificates = const [],
    this.badges = const [],
    this.partnersCount = 0,
    this.partners = const [],
    this.location,
    this.gender,
    this.birthDate,
    this.height,
    this.weight,
    this.interestedSports,
    this.level,
    this.preferredTimes,
    this.playStyle,
    this.teamPreference,
    this.isPremium = false,
    this.premiumUntil,
    this.reliabilityScore = 100.0,
    this.totalMeetupsJoined = 0,
    this.totalMeetupsRegistered = 0,
    this.averageRating = 0.0,
    this.totalRatings = 0,
    this.lastSeen,
    this.isOnline = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'profileImageUrl': profileImageUrl,
      'bio': bio,
      'certificates': certificates.map((e) => e.toJson()).toList(),
      'badges': badges.map((e) => e.toJson()).toList(),
      'partnersCount': partnersCount,
      'partners': partners,
      'location': location,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
      'interestedSports': interestedSports?.map((e) => e.name).toList(),
      'level': level?.name,
      'preferredTimes': preferredTimes?.map((e) => e.name).toList(),
      'playStyle': playStyle?.name,
      'teamPreference': teamPreference,
      'isPremium': isPremium,
      'premiumUntil': premiumUntil != null
          ? Timestamp.fromDate(premiumUntil!)
          : null,
      'reliabilityScore': reliabilityScore,
      'totalMeetupsJoined': totalMeetupsJoined,
      'totalMeetupsRegistered': totalMeetupsRegistered,
      'averageRating': averageRating,
      'totalRatings': totalRatings,
      'lastSeen': lastSeen?.toIso8601String(),
      'isOnline': isOnline,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is String) return DateTime.tryParse(value);
      if (value is Timestamp) {
        return value.toDate();
      }
      return null;
    }

    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl:
          (json['profileImageUrl'] ?? json['imageUrl'] ?? json['photoUrl'])
              as String?,
      bio: json['bio'],
      certificates:
          (json['certificates'] as List<dynamic>?)
              ?.map((e) => Certificate.fromJson(e))
              .toList() ??
          [],
      badges:
          (json['badges'] as List<dynamic>?)
              ?.map((e) => Badge.fromJson(e))
              .toList() ??
          [],
      partnersCount: json['partnersCount'] ?? 0,
      partners: (json['partners'] as List<dynamic>?)?.cast<String>() ?? [],
      location: json['location'],
      gender: json['gender'],
      birthDate: parseDate(json['birthDate']),
      height: json['height'],
      weight: json['weight'],
      interestedSports: (json['interestedSports'] as List<dynamic>?)
          ?.map(
            (e) => SportType.values.firstWhere(
              (element) => element.name == e,
              orElse: () => SportType.other,
            ),
          )
          .toList(),
      level: Level.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => Level.beginner,
      ),
      preferredTimes:
          (json['preferredTimes'] as List<dynamic>?)
              ?.map(
                (e) => PreferredTime.values.firstWhere(
                  (element) => element.name == e,
                  orElse: () => PreferredTime.weekdayMorning,
                ),
              )
              .toList() ??
          [],
      playStyle: PlayStyle.values.firstWhere(
        (e) => e.name == json['playStyle'],
        orElse: () => PlayStyle.casual,
      ),
      teamPreference: json['teamPreference'],
      isPremium: json['isPremium'] ?? false,
      premiumUntil: parseDate(json['premiumUntil']),
      reliabilityScore: (json['reliabilityScore'] ?? 100.0).toDouble(),
      totalMeetupsJoined: json['totalMeetupsJoined'] ?? 0,
      totalMeetupsRegistered: json['totalMeetupsRegistered'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      totalRatings: json['totalRatings'] ?? 0,
      lastSeen: parseDate(json['lastSeen']),
      isOnline: json['isOnline'] ?? false,
    );
  }
  // Factory to create a mock user for UI testing
  factory UserModel.mock() {
    return UserModel(
      id: 'mock_1',
      username: 'Kaan Sportif',
      email: 'kaan@sporsal.com',
      bio:
          'Futbol ve CrossFit tutkunu. Haftada 3 gÃ¼n antrenman! \u{1F3C3}\u{1F3BE}',
      partnersCount: 12,
      location: 'Ä°stanbul, TÃ¼rkiye',
      birthDate: DateTime(1998, 5, 15),
      reliabilityScore: 98.0,
      totalMeetupsJoined: 13,
      totalMeetupsRegistered: 14,
      averageRating: 4.9,
      totalRatings: 8,
      lastSeen: DateTime.now(),
      isOnline: true,
      badges: [
        const Badge(
          id: 'b1',
          name: 'MaÃ§ OrganizatÃ¶rÃ¼',
          description: '10 maÃ§ organize etti',
          iconPath: 'assets/badges/organizer_gold.png',
          type: BadgeType.organizer,
        ),
        const Badge(
          id: 'b2',
          name: 'SadÄ±k Oyuncu',
          description: 'Son 5 maÃ§a eksiksiz katÄ±ldÄ±',
          iconPath: 'assets/badges/player_silver.png',
          type: BadgeType.participant,
        ),
      ],
      certificates: [
        Certificate(
          id: 'c1',
          title: 'CrossFit Level 1',
          issuer: 'CrossFit Inc.',
          imageUrl: '',
          dateDate: DateTime(2025, 5, 20),
        ),
      ],
    );
  }

  // Helper to calculate age from birthDate
  int? get age {
    if (birthDate == null) return null;
    final now = DateTime.now();
    int calculatedAge = now.year - birthDate!.year;
    if (now.month < birthDate!.month ||
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      calculatedAge--;
    }
    return calculatedAge;
  }

  // Check if user is considered online (last seen within 5 minutes)
  bool get isCurrentlyOnline {
    if (lastSeen == null) return false;
    final difference = DateTime.now().difference(lastSeen!);
    return difference.inMinutes <= 5;
  }
}
