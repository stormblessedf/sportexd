import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/core/models/user_model.dart';

void main() {
  group('SportTypeEmojiExtension', () {
    test('each SportType value returns a non-empty emoji string', () {
      for (final sport in SportType.values) {
        expect(
          sport.emoji.isNotEmpty,
          isTrue,
          reason: '${sport.name} should have a non-empty emoji',
        );
      }
    });

    test('label format is "emoji displayName" for each value', () {
      for (final sport in SportType.values) {
        expect(
          sport.label,
          equals('${sport.emoji} ${sport.displayName}'),
          reason: '${sport.name} label should be "\${emoji} \${displayName}"',
        );
      }
    });

    test('all emojis are unique across SportType values', () {
      final emojis = SportType.values.map((s) => s.emoji).toList();
      final uniqueEmojis = emojis.toSet();
      expect(
        uniqueEmojis.length,
        equals(emojis.length),
        reason: 'Each SportType should have a unique emoji',
      );
    });
  });
}
