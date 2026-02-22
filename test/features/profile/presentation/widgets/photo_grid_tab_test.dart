import 'package:flutter_test/flutter_test.dart';
import 'package:sporsal/features/profile/presentation/widgets/photo_grid_tab.dart';
import 'package:sporsal/features/profile/presentation/controllers/photo_upload_controller.dart';

/// PhotoGridTab widget testleri.
///
/// Not: PhotoGridTab dahili olarak ProfilePhotoService oluşturur ve bu servis
/// Firebase Storage/Firestore gerektirir. Tam widget testleri için
/// Firebase mock altyapısı (fake_cloud_firestore, firebase_storage_mocks)
/// gereklidir. Bu testler yalnızca birim seviyesinde doğrulama yapar.
void main() {
  group('PhotoUploadController', () {
    late PhotoUploadController controller;

    setUp(() {
      controller = PhotoUploadController();
    });

    test('initial state is not uploading and no trigger', () {
      expect(controller.isUploading, isFalse);
      expect(controller.shouldTriggerUpload, isFalse);
    });

    test('triggerUpload sets shouldTriggerUpload to true', () {
      controller.triggerUpload();
      expect(controller.shouldTriggerUpload, isTrue);
    });

    test('consumeTrigger resets shouldTriggerUpload to false', () {
      controller.triggerUpload();
      controller.consumeTrigger();
      expect(controller.shouldTriggerUpload, isFalse);
    });

    test('setUploading updates isUploading state', () {
      controller.setUploading(true);
      expect(controller.isUploading, isTrue);

      controller.setUploading(false);
      expect(controller.isUploading, isFalse);
    });

    test('triggerUpload notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.triggerUpload();
      expect(notified, isTrue);
    });

    test('setUploading notifies listeners', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.setUploading(true);
      expect(notified, isTrue);
    });

    test('consumeTrigger does not notify listeners', () {
      controller.triggerUpload();
      var notified = false;
      controller.addListener(() => notified = true);
      controller.consumeTrigger();
      expect(notified, isFalse);
    });
  });

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
