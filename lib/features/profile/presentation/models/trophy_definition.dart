/// Bir rozet/kupa tanımını temsil eden immutable veri modeli.
class TrophyDefinition {
  final String id;
  final String emoji;
  final String name;
  final String description;
  final String criteria;

  const TrophyDefinition({
    required this.id,
    required this.emoji,
    required this.name,
    required this.description,
    required this.criteria,
  });
}

/// Uygulamadaki tüm rozet tanımlarını içeren sabit liste.
const List<TrophyDefinition> allTrophyDefinitions = [
  TrophyDefinition(
    id: 'organizer',
    emoji: '🏆',
    name: 'Maç Organizatörü',
    description: '10+ etkinlik organize eden',
    criteria: 'totalOrganized >= 10',
  ),
  TrophyDefinition(
    id: 'loyal',
    emoji: '⚡',
    name: 'Sadık Oyuncu',
    description: 'Son 5 etkinliğe eksiksiz katılan',
    criteria: 'lastFiveAttended == 5',
  ),
  TrophyDefinition(
    id: 'streak10',
    emoji: '🔥',
    name: '10 Maç Serisi',
    description: '10 etkinliğe üst üste katılan',
    criteria: 'consecutiveAttended >= 10',
  ),
  TrophyDefinition(
    id: 'social',
    emoji: '🤝',
    name: 'Sosyal Kelebek',
    description: '20+ farklı spor partneri olan',
    criteria: 'partnersCount >= 20',
  ),
  TrophyDefinition(
    id: 'fivestar',
    emoji: '⭐',
    name: '5 Yıldız',
    description: 'Ortalama puanı 4.8+ olan',
    criteria: 'averageRating >= 4.8',
  ),
  TrophyDefinition(
    id: 'versatile',
    emoji: '🏅',
    name: 'Çok Yönlü',
    description: '5+ farklı spor dalında etkinliğe katılan',
    criteria: 'uniqueSportsCount >= 5',
  ),
  TrophyDefinition(
    id: 'earlybird',
    emoji: '📅',
    name: 'Erken Kuş',
    description: '10+ etkinliğe ilk kaydolan',
    criteria: 'earlyBirdCount >= 10',
  ),
  TrophyDefinition(
    id: 'reliable',
    emoji: '💯',
    name: 'Güvenilir',
    description: 'Güvenilirlik skoru %95+ olan',
    criteria: 'reliabilityScore >= 95',
  ),
  TrophyDefinition(
    id: 'focused',
    emoji: '🎯',
    name: 'Hedef Odaklı',
    description: '50+ etkinliğe katılan',
    criteria: 'totalMeetupsJoined >= 50',
  ),
];
