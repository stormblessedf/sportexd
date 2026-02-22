import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/live_event/utils/progress_utils.dart';

void main() {
  group('calculateProgress', () {
    test('returns 0.0 at start time', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 12, 0);
      expect(calculateProgress(start, end, start), 0.0);
    });

    test('returns 1.0 at end time', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 12, 0);
      expect(calculateProgress(start, end, end), 1.0);
    });

    test('returns 0.5 at midpoint', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 12, 0);
      final mid = DateTime(2024, 1, 1, 11, 0);
      expect(calculateProgress(start, end, mid), 0.5);
    });

    test('clamps to 0.0 when now is before start', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 12, 0);
      final before = DateTime(2024, 1, 1, 9, 0);
      expect(calculateProgress(start, end, before), 0.0);
    });

    test('clamps to 1.0 when now is after end', () {
      final start = DateTime(2024, 1, 1, 10, 0);
      final end = DateTime(2024, 1, 1, 12, 0);
      final after = DateTime(2024, 1, 1, 13, 0);
      expect(calculateProgress(start, end, after), 1.0);
    });

    test('returns 1.0 when total duration is zero', () {
      final time = DateTime(2024, 1, 1, 10, 0);
      expect(calculateProgress(time, time, time), 1.0);
    });

    test('returns 1.0 when end is before start', () {
      final start = DateTime(2024, 1, 1, 12, 0);
      final end = DateTime(2024, 1, 1, 10, 0);
      expect(calculateProgress(start, end, start), 1.0);
    });
  });

  group('formatRemainingTime', () {
    test('formats zero duration', () {
      expect(formatRemainingTime(Duration.zero), '00:00:00');
    });

    test('formats hours, minutes, seconds', () {
      expect(
        formatRemainingTime(const Duration(hours: 1, minutes: 30, seconds: 45)),
        '01:30:45',
      );
    });

    test('pads single digits with zero', () {
      expect(
        formatRemainingTime(const Duration(hours: 2, minutes: 5, seconds: 3)),
        '02:05:03',
      );
    });

    test('handles 24+ hours', () {
      expect(
        formatRemainingTime(const Duration(hours: 25, minutes: 0, seconds: 0)),
        '25:00:00',
      );
    });

    test('returns 00:00:00 for negative duration', () {
      expect(
        formatRemainingTime(const Duration(seconds: -30)),
        '00:00:00',
      );
    });

    test('formats seconds only', () {
      expect(
        formatRemainingTime(const Duration(seconds: 59)),
        '00:00:59',
      );
    });

    test('formats minutes and seconds', () {
      expect(
        formatRemainingTime(const Duration(minutes: 10, seconds: 5)),
        '00:10:05',
      );
    });
  });
}
