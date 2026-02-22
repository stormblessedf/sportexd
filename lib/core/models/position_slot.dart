/// Bir takımdaki tek bir pozisyon slotunu temsil eder
class PositionSlot {
  /// Pozisyon adı: "goalkeeper", "defender", "midfielder", "forward"
  final String position;

  /// Atanmış kullanıcı ID (null = boş slot)
  final String? assignedUserId;

  /// Atanmış kullanıcı adı (null = boş slot)
  final String? assignedUserName;

  /// Atanmış kullanıcı profil fotoğrafı URL'i (opsiyonel)
  final String? assignedUserImageUrl;

  const PositionSlot({
    required this.position,
    this.assignedUserId,
    this.assignedUserName,
    this.assignedUserImageUrl,
  });

  /// Slot boş mu?
  bool get isEmpty => assignedUserId == null;

  /// Slot dolu mu?
  bool get isFilled => assignedUserId != null;

  /// Pozisyonun Türkçe görünen adı
  String get displayName {
    switch (position) {
      case 'goalkeeper':
        return 'Kaleci';
      case 'defender':
        return 'Defans';
      case 'midfielder':
        return 'Orta Saha';
      case 'forward':
        return 'Forvet';
      default:
        return position;
    }
  }

  /// Pozisyonun kısa adı
  String get shortName {
    switch (position) {
      case 'goalkeeper':
        return 'K';
      case 'defender':
        return 'D';
      case 'midfielder':
        return 'O';
      case 'forward':
        return 'F';
      default:
        return position[0].toUpperCase();
    }
  }

  /// JSON'a çevirme
  Map<String, dynamic> toJson() {
    return {
      'position': position,
      'assignedUserId': assignedUserId,
      'assignedUserName': assignedUserName,
      'assignedUserImageUrl': assignedUserImageUrl,
    };
  }

  /// JSON'dan oluşturma
  factory PositionSlot.fromJson(Map<String, dynamic> json) {
    return PositionSlot(
      position: json['position'] as String? ?? 'defender',
      assignedUserId: json['assignedUserId'] as String?,
      assignedUserName: json['assignedUserName'] as String?,
      assignedUserImageUrl: json['assignedUserImageUrl'] as String?,
    );
  }

  /// Kullanıcı atanmış kopyasını oluştur
  PositionSlot assignUser({
    required String userId,
    required String userName,
    String? userImageUrl,
  }) {
    return PositionSlot(
      position: position,
      assignedUserId: userId,
      assignedUserName: userName,
      assignedUserImageUrl: userImageUrl,
    );
  }

  /// Kullanıcı kaldırılmış (boş) kopyasını oluştur
  PositionSlot clearUser() {
    return PositionSlot(position: position);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PositionSlot &&
        other.position == position &&
        other.assignedUserId == assignedUserId &&
        other.assignedUserName == assignedUserName &&
        other.assignedUserImageUrl == assignedUserImageUrl;
  }

  @override
  int get hashCode {
    return Object.hash(
      position,
      assignedUserId,
      assignedUserName,
      assignedUserImageUrl,
    );
  }

  @override
  String toString() {
    return 'PositionSlot(position: $position, assignedUserId: $assignedUserId, assignedUserName: $assignedUserName)';
  }
}
