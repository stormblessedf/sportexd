import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/photo_grid_tab.dart';

void main() {
  group('PhotoGridTab', () {
    test('can be constructed with required parameters', () {
      const widget = PhotoGridTab(
        userId: 'test-user',
        isOwnProfile: true,
      );

      expect(widget.userId, 'test-user');
      expect(widget.isOwnProfile, isTrue);
    });

    test('can be constructed for other user profile', () {
      const widget = PhotoGridTab(
        userId: 'other-user',
        isOwnProfile: false,
      );

      expect(widget.userId, 'other-user');
      expect(widget.isOwnProfile, isFalse);
    });
  });
}
