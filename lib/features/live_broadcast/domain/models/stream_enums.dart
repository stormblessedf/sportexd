/// Canlı Yayın Sistemi için enum tanımları

/// Yayın durumunu temsil eder
enum StreamStatus {
  /// Yayın başlatılıyor
  starting,

  /// Yayın canlı
  live,

  /// Yayın duraklatıldı
  paused,

  /// Yayın sona erdi
  ended,

  /// Yayın hatası
  error,
}

/// Yayın kalite seçenekleri
enum StreamQuality {
  /// Otomatik kalite (ağ hızına göre)
  auto,

  /// 1080p Full HD
  quality1080p,

  /// 720p HD
  quality720p,

  /// 480p SD
  quality480p,

  /// 360p Low
  quality360p,
}

/// Yayın gizlilik seviyeleri
enum PrivacyLevel {
  /// Herkese açık
  public,

  /// Sadece takipçiler
  followersOnly,

  /// Sadece etkinlik katılımcıları
  participantsOnly,
}

/// Tepki türleri
enum ReactionType {
  /// Kalp
  heart,

  /// Beğeni
  like,

  /// Ateş
  fire,

  /// Alkış
  clap,
}

/// Bağlantı kalitesi
enum ConnectionQuality {
  /// Mükemmel
  excellent,

  /// İyi
  good,

  /// Orta
  fair,

  /// Zayıf
  poor,
}

// Extension methods for display names
extension StreamStatusExtension on StreamStatus {
  String get displayName {
    switch (this) {
      case StreamStatus.starting:
        return 'Başlatılıyor';
      case StreamStatus.live:
        return 'Canlı';
      case StreamStatus.paused:
        return 'Duraklatıldı';
      case StreamStatus.ended:
        return 'Sona Erdi';
      case StreamStatus.error:
        return 'Hata';
    }
  }
}

extension StreamQualityExtension on StreamQuality {
  String get displayName {
    switch (this) {
      case StreamQuality.auto:
        return 'Otomatik';
      case StreamQuality.quality1080p:
        return '1080p';
      case StreamQuality.quality720p:
        return '720p';
      case StreamQuality.quality480p:
        return '480p';
      case StreamQuality.quality360p:
        return '360p';
    }
  }

  int get bitrate {
    switch (this) {
      case StreamQuality.auto:
        return 0; // Dinamik
      case StreamQuality.quality1080p:
        return 4500;
      case StreamQuality.quality720p:
        return 2500;
      case StreamQuality.quality480p:
        return 1000;
      case StreamQuality.quality360p:
        return 500;
    }
  }
}

extension PrivacyLevelExtension on PrivacyLevel {
  String get displayName {
    switch (this) {
      case PrivacyLevel.public:
        return 'Herkese Açık';
      case PrivacyLevel.followersOnly:
        return 'Sadece Takipçiler';
      case PrivacyLevel.participantsOnly:
        return 'Sadece Katılımcılar';
    }
  }

  String get description {
    switch (this) {
      case PrivacyLevel.public:
        return 'Herkes bu yayını izleyebilir';
      case PrivacyLevel.followersOnly:
        return 'Sadece sizi takip edenler izleyebilir';
      case PrivacyLevel.participantsOnly:
        return 'Sadece etkinlik katılımcıları izleyebilir';
    }
  }
}

extension ReactionTypeExtension on ReactionType {
  String get emoji {
    switch (this) {
      case ReactionType.heart:
        return '❤️';
      case ReactionType.like:
        return '👍';
      case ReactionType.fire:
        return '🔥';
      case ReactionType.clap:
        return '👏';
    }
  }
}

extension ConnectionQualityExtension on ConnectionQuality {
  String get displayName {
    switch (this) {
      case ConnectionQuality.excellent:
        return 'Mükemmel';
      case ConnectionQuality.good:
        return 'İyi';
      case ConnectionQuality.fair:
        return 'Orta';
      case ConnectionQuality.poor:
        return 'Zayıf';
    }
  }
}
