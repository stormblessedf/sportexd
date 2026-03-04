import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image/image.dart' as img;

import '../models/profile_photo_model.dart';

class ProfilePhotoService {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;

  ProfilePhotoService({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  /// Görseli 1080x1080 / %85 JPEG olarak sıkıştırır.
  /// Web'de `image` paketi çok yavaş/sorunlu olduğundan sıkıştırma atlanır.
  Uint8List compressImage(Uint8List imageBytes) {
    if (kIsWeb) return imageBytes;

    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    img.Image resized = decoded;
    if (decoded.width > 1080 || decoded.height > 1080) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: 1080);
      } else {
        resized = img.copyResize(decoded, height: 1080);
      }
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  /// Fotoğraf yükler: Storage'a upload + Firestore doküman oluşturma.
  /// Firestore yazımı başarısız olursa, Storage'daki orphan dosya silinir (rollback).
  Future<ProfilePhotoModel> uploadPhoto({
    required String userId,
    required Uint8List imageBytes,
  }) async {
    if (userId.isEmpty) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    Reference? uploadedRef;
    try {
      final compressed = compressImage(imageBytes);

      final photoId =
          _firestore.collection('profile_photos').doc().id;

      final ref = _storage.ref('profile_photos/$userId/$photoId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId},
      );
      final uploadTask = ref.putData(compressed, metadata);
      final snapshot = await uploadTask;
      uploadedRef = snapshot.ref;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      final now = DateTime.now();
      final storagePath = 'profile_photos/$userId/$photoId.jpg';
      final photo = ProfilePhotoModel(
        photoId: photoId,
        userId: userId,
        photoUrl: downloadUrl,
        storagePath: storagePath,
        createdAt: now,
      );

      await _firestore.collection('profile_photos').doc(photoId).set({
        ...photo.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return photo;
    } catch (e) {
      if (uploadedRef != null) {
        try {
          await uploadedRef.delete();
        } catch (_) {}
      }
      throw Exception('Fotoğraf yüklenirken bir hata oluştu: $e');
    }
  }

  /// Kullanıcının fotoğraflarını createdAt desc sıralı stream olarak döner.
  Stream<List<ProfilePhotoModel>> getPhotosForUser(String userId) {
    return _firestore
        .collection('profile_photos')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ProfilePhotoModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Fotoğrafı hem Storage'dan hem Firestore'dan siler.
  Future<void> deletePhoto({
    required String photoId,
    required String storagePath,
  }) async {
    if (photoId.isEmpty || storagePath.isEmpty) {
      throw Exception('Kullanıcı oturumu bulunamadı');
    }

    try {
      await _firestore.collection('profile_photos').doc(photoId).delete();
      await _storage.ref(storagePath).delete();
    } catch (e) {
      throw Exception('Fotoğraf silinirken bir hata oluştu: $e');
    }
  }
}
