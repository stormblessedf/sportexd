import 'position_slot.dart';

/// Futbol pozisyon türleri
enum FootballPosition {
  goalkeeper,
  defender,
  midfielder,
  forward;

  /// Pozisyonun Türkçe görünen adı
  String get displayName {
    switch (this) {
      case FootballPosition.goalkeeper:
        return 'Kaleci';
      case FootballPosition.defender:
        return 'Defans';
      case FootballPosition.midfielder:
        return 'Orta Saha';
      case FootballPosition.forward:
        return 'Forvet';
    }
  }

  /// Pozisyonun kısa adı
  String get shortName {
    switch (this) {
      case FootballPosition.goalkeeper:
        return 'K';
      case FootballPosition.defender:
        return 'D';
      case FootballPosition.midfielder:
        return 'O';
      case FootballPosition.forward:
        return 'F';
    }
  }
}

/// Bir diziliş yapılandırmasını temsil eder
class FormationConfig {
  final String format; // "4v4", "5v5", "6v6", "7v7"
  final String formation; // "1-2-1-1" (kaleci-defans-ortasaha-forvet)
  final Map<FootballPosition, int> positionCounts;

  const FormationConfig({
    required this.format,
    required this.formation,
    required this.positionCounts,
  });

  /// Dizilişin görünen adı (örn. "1-2-1-1")
  String get displayName => formation;

  /// Toplam oyuncu sayısını döner
  int get playerCount {
    return positionCounts.values.fold(0, (sum, count) => sum + count);
  }

  /// Dizilişten pozisyon slotları listesi üretir
  List<PositionSlot> generateSlots() {
    final slots = <PositionSlot>[];

    // Pozisyon sırasına göre slot oluştur: Kaleci -> Defans -> Orta Saha -> Forvet
    for (final position in FootballPosition.values) {
      final count = positionCounts[position] ?? 0;
      for (int i = 0; i < count; i++) {
        slots.add(PositionSlot(position: position.name));
      }
    }

    return slots;
  }
}

/// Tüm desteklenen formatlar ve dizilişler
class FormationData {
  FormationData._(); // Private constructor - static only

  /// Tüm maç formatları
  static const List<String> formats = ['4v4', '5v5', '6v6', '7v7'];

  /// Varsayılan format
  static const String defaultFormat = '5v5';

  /// Tüm diziliş yapılandırmaları
  static const Map<String, List<FormationConfig>> formations = {
    // 4v4 dizilişleri
    '4v4': [
      FormationConfig(
        format: '4v4',
        formation: '1-1-1-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '4v4',
        formation: '1-2-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 0,
        },
      ),
      FormationConfig(
        format: '4v4',
        formation: '1-1-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 0,
        },
      ),
      FormationConfig(
        format: '4v4',
        formation: '1-0-2-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 0,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '4v4',
        formation: '1-0-1-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 0,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 2,
        },
      ),
    ],

    // 5v5 dizilişleri
    '5v5': [
      FormationConfig(
        format: '5v5',
        formation: '1-2-1-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '5v5',
        formation: '1-1-2-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '5v5',
        formation: '1-2-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 0,
        },
      ),
      FormationConfig(
        format: '5v5',
        formation: '1-1-1-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 2,
        },
      ),
      FormationConfig(
        format: '5v5',
        formation: '1-3-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 3,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 0,
        },
      ),
      FormationConfig(
        format: '5v5',
        formation: '1-0-3-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 0,
          FootballPosition.midfielder: 3,
          FootballPosition.forward: 1,
        },
      ),
    ],

    // 6v6 dizilişleri
    '6v6': [
      FormationConfig(
        format: '6v6',
        formation: '1-2-2-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '6v6',
        formation: '1-3-1-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 3,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '6v6',
        formation: '1-2-1-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 2,
        },
      ),
      FormationConfig(
        format: '6v6',
        formation: '1-1-3-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 3,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '6v6',
        formation: '1-2-3',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 3,
          FootballPosition.forward: 0,
        },
      ),
      FormationConfig(
        format: '6v6',
        formation: '1-1-2-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 2,
        },
      ),
    ],

    // 7v7 dizilişleri
    '7v7': [
      FormationConfig(
        format: '7v7',
        formation: '1-2-3-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 3,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '7v7',
        formation: '1-3-2-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 3,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 1,
        },
      ),
      FormationConfig(
        format: '7v7',
        formation: '1-2-2-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 2,
          FootballPosition.forward: 2,
        },
      ),
      FormationConfig(
        format: '7v7',
        formation: '1-3-1-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 3,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 2,
        },
      ),
      FormationConfig(
        format: '7v7',
        formation: '1-1-3-2',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 3,
          FootballPosition.forward: 2,
        },
      ),
      FormationConfig(
        format: '7v7',
        formation: '1-2-1-3',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 2,
          FootballPosition.midfielder: 1,
          FootballPosition.forward: 3,
        },
      ),
      FormationConfig(
        format: '7v7',
        formation: '1-3-3',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 3,
          FootballPosition.midfielder: 3,
          FootballPosition.forward: 0,
        },
      ),
      FormationConfig(
        format: '7v7',
        formation: '1-1-4-1',
        positionCounts: {
          FootballPosition.goalkeeper: 1,
          FootballPosition.defender: 1,
          FootballPosition.midfielder: 4,
          FootballPosition.forward: 1,
        },
      ),
    ],
  };

  /// Format string'inden takım başına oyuncu sayısını parse eder
  /// Örn: "5v5" -> 5
  static int playersPerTeam(String format) {
    final parts = format.toLowerCase().split('v');
    if (parts.length != 2) return 0;
    return int.tryParse(parts[0]) ?? 0;
  }

  /// Format string'inden toplam oyuncu sayısını hesaplar
  /// Örn: "5v5" -> 10
  static int totalPlayers(String format) {
    return playersPerTeam(format) * 2;
  }

  /// Verilen format için varsayılan dizilişi döner
  static FormationConfig? getDefaultFormation(String format) {
    final formatFormations = formations[format];
    if (formatFormations == null || formatFormations.isEmpty) return null;
    return formatFormations.first;
  }

  /// Verilen format ve diziliş adı için yapılandırmayı döner
  static FormationConfig? getFormation(String format, String formation) {
    final formatFormations = formations[format];
    if (formatFormations == null) return null;

    for (final config in formatFormations) {
      if (config.formation == formation) {
        return config;
      }
    }
    return null;
  }
}
