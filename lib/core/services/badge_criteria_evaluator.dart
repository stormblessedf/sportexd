/// Rozet kriter değerlendirme mantığı — saf fonksiyonlar, Firestore bağımlılığı yok.
class BadgeCriteriaEvaluator {
  /// organizer: totalOrganized >= 10
  bool evaluateOrganizer(int totalOrganized) => totalOrganized >= 10;

  /// loyal: son 5 kayıtlı etkinliğe eksiksiz katılım
  bool evaluateLoyal(List<bool> attendedFlags) =>
      attendedFlags.length >= 5 && attendedFlags.take(5).every((a) => a);

  /// Yardımcı: en uzun ardışık katılım serisini hesapla
  int calculateMaxStreak(List<bool> attended) {
    int maxStreak = 0;
    int current = 0;
    for (final a in attended) {
      if (a) {
        current++;
        if (current > maxStreak) maxStreak = current;
      } else {
        current = 0;
      }
    }
    return maxStreak;
  }

  /// streak10: üst üste 10+ etkinliğe katılım
  bool evaluateStreak10(List<bool> attended) =>
      calculateMaxStreak(attended) >= 10;

  /// social: partnersCount >= 20
  bool evaluateSocial(int partnersCount) => partnersCount >= 20;

  /// fivestar: averageRating >= 4.8 ve totalRatings >= 3
  bool evaluateFivestar(double averageRating, int totalRatings) =>
      totalRatings >= 3 && averageRating >= 4.8;

  /// versatile: 5+ farklı spor dalında katılım
  bool evaluateVersatile(int uniqueSportsCount) => uniqueSportsCount >= 5;

  /// earlybird: 10+ etkinlikte ilk 3 kaydolan
  bool evaluateEarlybird(int earlyBirdCount) => earlyBirdCount >= 10;

  /// reliable: reliabilityScore >= 95 ve totalMeetupsRegistered >= 5
  bool evaluateReliable(double reliabilityScore, int totalMeetupsRegistered) =>
      totalMeetupsRegistered >= 5 && reliabilityScore >= 95;

  /// focused: totalMeetupsJoined >= 50
  bool evaluateFocused(int totalMeetupsJoined) => totalMeetupsJoined >= 50;
}
