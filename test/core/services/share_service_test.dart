import 'package:flutter_test/flutter_test.dart';
import 'package:glados/glados.dart' hide expect, group, test;
import 'package:sporsal/core/services/share_service.dart';

void main() {
  group('ShareService - Property-Based Tests', () {
    /// **Validates: Requirements 1.1**
    /// Property 1: generateProfileLink output is in correct URL format
    Glados(any.nonEmptyLetters).test(
      'generateProfileLink output starts with base URL and ends with userId',
      (userId) {
        final link = ShareService.generateProfileLink(userId);
        expect(
          link,
          equals('https://sportexd-1bb0e.web.app/user-profile/$userId'),
        );
        expect(
          link.startsWith('https://sportexd-1bb0e.web.app/user-profile/'),
          isTrue,
        );
        expect(link.endsWith(userId), isTrue);
      },
    );

    /// **Validates: Requirements 1.3**
    /// Property 2: Round-trip — userId can be extracted back from the generated URL
    Glados(any.nonEmptyLetters).test(
      'userId can be extracted back from generated profile link',
      (userId) {
        final link = ShareService.generateProfileLink(userId);
        final extracted = link.replaceFirst(
          'https://sportexd-1bb0e.web.app/user-profile/',
          '',
        );
        expect(extracted, equals(userId));
      },
    );

    /// **Validates: Requirements 1.2**
    /// Property 3: generateShareMessage output contains the profile link
    Glados(any.nonEmptyLetters).test(
      'generateShareMessage output contains the profile link',
      (userId) {
        final message = ShareService.generateShareMessage(userId);
        final link = ShareService.generateProfileLink(userId);
        expect(message.contains(link), isTrue);
      },
    );

    /// **Validates: Requirements 4.2**
    /// Property 4: Empty userId throws ArgumentError on shareProfile
    test('shareProfile throws ArgumentError for empty userId', () {
      expect(
        () => ShareService.shareProfile(''),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
