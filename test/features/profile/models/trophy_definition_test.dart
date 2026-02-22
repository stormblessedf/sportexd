import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/models/trophy_definition.dart';

void main() {
  group('TrophyDefinition - allTrophyDefinitions', () {
    /// **Validates: Requirements 2.1**
    test('Property 1: contains exactly 9 elements', () {
      expect(allTrophyDefinitions.length, equals(9));
    });

    /// **Validates: Requirements 3.1**
    test('Property 2: all id values are unique', () {
      final ids = allTrophyDefinitions.map((t) => t.id).toSet();
      expect(ids.length, equals(allTrophyDefinitions.length));
    });

    /// **Validates: Requirements 3.2, 3.3, 3.4, 3.5**
    test('Property 3: all entries have non-empty id, emoji, name, description, criteria', () {
      for (final trophy in allTrophyDefinitions) {
        expect(trophy.id, isNotEmpty, reason: 'id should not be empty for ${trophy.name}');
        expect(trophy.emoji, isNotEmpty, reason: 'emoji should not be empty for ${trophy.name}');
        expect(trophy.name, isNotEmpty, reason: 'name should not be empty for ${trophy.name}');
        expect(trophy.description, isNotEmpty, reason: 'description should not be empty for ${trophy.name}');
        expect(trophy.criteria, isNotEmpty, reason: 'criteria should not be empty for ${trophy.name}');
      }
    });
  });
}
