import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, group, test;
import 'package:sporsal/core/services/badge_criteria_evaluator.dart';

/// Reference implementation for max streak calculation.
int referenceMaxStreak(List<bool> list) {
  int max = 0, current = 0;
  for (final b in list) {
    if (b) {
      current++;
      if (current > max) max = current;
    } else {
      current = 0;
    }
  }
  return max;
}

void main() {
  final evaluator = BadgeCriteriaEvaluator();

  /// **Validates: Requirements 2.2, 2.3**
  /// Property 2: Organizer threshold — evaluateOrganizer(n) ↔ n >= 10
  Glados<int>().test(
    'organizer threshold: evaluateOrganizer(n) iff n >= 10',
    (n) {
      expect(evaluator.evaluateOrganizer(n), equals(n >= 10));
    },
  );

  /// **Validates: Requirements 4.1, 4.2, 4.3**
  /// Property 3: Max streak calculation matches reference implementation
  Glados<List<bool>>().test(
    'max streak: calculateMaxStreak equals longest consecutive true series',
    (list) {
      expect(evaluator.calculateMaxStreak(list), equals(referenceMaxStreak(list)));
    },
  );

  /// **Validates: Requirements 3.2, 3.3**
  /// Property 4: Loyal player — evaluateLoyal(flags) ↔ flags.length >= 5 && first 5 all true
  Glados<List<bool>>().test(
    'loyal player: evaluateLoyal(flags) iff length >= 5 and first 5 all true',
    (flags) {
      final expected = flags.length >= 5 && flags.take(5).every((a) => a);
      expect(evaluator.evaluateLoyal(flags), equals(expected));
    },
  );

  /// **Validates: Requirements 5.2**
  /// Property 5: Social threshold — evaluateSocial(n) ↔ n >= 20
  Glados<int>().test(
    'social threshold: evaluateSocial(n) iff n >= 20',
    (n) {
      expect(evaluator.evaluateSocial(n), equals(n >= 20));
    },
  );

  /// **Validates: Requirements 6.2, 6.3**
  /// Property 6: Five star compound threshold — evaluateFivestar(r, t) ↔ t >= 3 && r >= 4.8
  Glados2<double, int>().test(
    'five star: evaluateFivestar(r, t) iff t >= 3 and r >= 4.8',
    (rating, totalRatings) {
      final expected = totalRatings >= 3 && rating >= 4.8;
      expect(evaluator.evaluateFivestar(rating, totalRatings), equals(expected));
    },
  );

  /// **Validates: Requirements 9.2, 9.3**
  /// Property 7: Reliable compound threshold — evaluateReliable(s, r) ↔ r >= 5 && s >= 95
  Glados2<double, int>().test(
    'reliable: evaluateReliable(s, r) iff r >= 5 and s >= 95',
    (score, registered) {
      final expected = registered >= 5 && score >= 95;
      expect(evaluator.evaluateReliable(score, registered), equals(expected));
    },
  );

  /// **Validates: Requirements 7.2**
  /// Property 8: Versatile threshold — evaluateVersatile(n) ↔ n >= 5
  Glados<int>().test(
    'versatile threshold: evaluateVersatile(n) iff n >= 5',
    (n) {
      expect(evaluator.evaluateVersatile(n), equals(n >= 5));
    },
  );

  /// **Validates: Requirements 8.2**
  /// Property 10a: Earlybird threshold — evaluateEarlybird(n) ↔ n >= 10
  Glados<int>().test(
    'earlybird threshold: evaluateEarlybird(n) iff n >= 10',
    (n) {
      expect(evaluator.evaluateEarlybird(n), equals(n >= 10));
    },
  );

  /// **Validates: Requirements 10.2**
  /// Property 10b: Focused threshold — evaluateFocused(n) ↔ n >= 50
  Glados<int>().test(
    'focused threshold: evaluateFocused(n) iff n >= 50',
    (n) {
      expect(evaluator.evaluateFocused(n), equals(n >= 50));
    },
  );
}
