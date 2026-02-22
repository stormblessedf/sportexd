/// İlerleme hesaplama ve süre formatlama saf fonksiyonları.
///
/// Bu fonksiyonlar canlı etkinlik sayfasındaki ilerleme sayacı
/// tarafından kullanılır.

/// Etkinliğin ilerleme yüzdesini hesaplar.
///
/// [start] etkinlik başlangıç zamanı, [end] bitiş zamanı, [now] şimdiki zaman.
/// Sonuç [0.0, 1.0] aralığında clamp edilir.
/// Toplam süre 0 veya negatifse 1.0 döner (tamamlanmış kabul edilir).
double calculateProgress(DateTime start, DateTime end, DateTime now) {
  final total = end.difference(start).inSeconds;
  if (total <= 0) return 1.0;
  final elapsed = now.difference(start).inSeconds;
  return (elapsed / total).clamp(0.0, 1.0);
}

/// Kalan süreyi HH:MM:SS formatında döndürür.
///
/// Negatif [remaining] değeri için '00:00:00' döner.
String formatRemainingTime(Duration remaining) {
  if (remaining.isNegative) return '00:00:00';
  final hours = remaining.inHours.toString().padLeft(2, '0');
  final minutes = (remaining.inMinutes % 60).toString().padLeft(2, '0');
  final seconds = (remaining.inSeconds % 60).toString().padLeft(2, '0');
  return '$hours:$minutes:$seconds';
}
