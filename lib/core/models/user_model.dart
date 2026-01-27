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
enum PreferredTime { weekdayMorning, weekdayEvening, weekendMorning, weekendEvening }
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

class UserModel {
  final String id;
  final String username;
  final String email;
  final String? profileImageUrl;
  final String? bio;
  final List<Certificate> certificates;
  final List<Badge> badges;
  final int followersCount;
  final int followingCount;
  final String? location;
  final String? gender;
  final DateTime? birthDate;
  final Level? level;
  final List<PreferredTime>? preferredTimes;
  final PlayStyle? playStyle;
  final String? teamPreference;
  final List<String>? followers;
  final List<String>? following;

  const UserModel({
    required this.id,
    required this.username,
    required this.email,
    this.profileImageUrl,
    this.bio,
    this.certificates = const [],
    this.badges = const [],
    this.followersCount = 0,
    this.followingCount = 0,
    this.location,
    this.gender,
    this.birthDate,
    this.level,
    this.preferredTimes,
    this.playStyle,
    this.teamPreference,
    this.followers,
    this.following,
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
      'followersCount': followersCount,
      'followingCount': followingCount,
      'location': location,
      'gender': gender,
      'birthDate': birthDate?.toIso8601String(),
      'level': level?.name,
      'preferredTimes': preferredTimes?.map((e) => e.name).toList(),
      'playStyle': playStyle?.name,
      'teamPreference': teamPreference,
      'followers': followers,
      'following': following,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profileImageUrl: json['profileImageUrl'],
      bio: json['bio'],
      certificates: (json['certificates'] as List<dynamic>?)
              ?.map((e) => Certificate.fromJson(e))
              .toList() ??
          [],
      badges: (json['badges'] as List<dynamic>?)
              ?.map((e) => Badge.fromJson(e))
              .toList() ??
          [],
      followersCount: json['followersCount'] ?? 0,
      followingCount: json['followingCount'] ?? 0,
      location: json['location'],
      gender: json['gender'],
      birthDate: json['birthDate'] != null
          ? DateTime.parse(json['birthDate'])
          : null,
      level: Level.values.firstWhere(
        (e) => e.name == json['level'],
        orElse: () => Level.beginner,
      ),
      preferredTimes: (json['preferredTimes'] as List<dynamic>?)
          ?.map((e) => PreferredTime.values.firstWhere(
                (element) => element.name == e,
                orElse: () => PreferredTime.weekdayMorning,
              ))
          .toList() ??
          [],
      playStyle: PlayStyle.values.firstWhere(
        (e) => e.name == json['playStyle'],
        orElse: () => PlayStyle.casual,
      ),
      teamPreference: json['teamPreference'],
      followers: (json['followers'] as List<dynamic>?)?.cast<String>() ?? [],
      following: (json['following'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  // Factory to create a mock user for UI testing
  factory UserModel.mock() {
    return UserModel(
      id: 'mock_1',
      username: 'Kaan Sportif',
      email: 'kaan@sporsal.com',
      bio: 'Futbol ve CrossFit tutkunu. Haftada 3 gün antrenman!',
      followersCount: 128,
      followingCount: 45,
      badges: [
        const Badge(
          id: 'b1',
          name: 'Maç Organizatörü',
          description: '10 maç organize etti',
          iconPath: 'assets/badges/organizer_gold.png',
          type: BadgeType.organizer,
        ),
        const Badge(
          id: 'b2',
          name: 'Sadık Oyuncu',
          description: 'Son 5 maça eksiksiz katıldı',
          iconPath: 'assets/badges/player_silver.png',
          type: BadgeType.participant,
        ),
      ],
      certificates: [
        Certificate(
          id: 'c1',
          title: 'CrossFit Level 1',
          issuer: 'CrossFit Inc.',
          imageUrl: '', // TODO: Placeholder
          dateDate: DateTime(2025, 5, 20),
        ),
      ],
    );
  }
}
