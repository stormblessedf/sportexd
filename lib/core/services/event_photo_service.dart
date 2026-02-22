import 'dart:async';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image/image.dart' as img;

import '../models/event_photo_model.dart';
import 'meetup_service.dart';

class EventPhotoService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final MeetupService _meetupService;

  EventPhotoService({required MeetupService meetupService})
      : _meetupService = meetupService;

  /// Fotoğrafı sıkıştırır: maksimum 1024x1024, %85 JPEG kalitesi.
  Uint8List compressImage(Uint8List imageBytes) {
    final decoded = img.decodeImage(imageBytes);
    if (decoded == null) return imageBytes;

    img.Image resized = decoded;
    if (decoded.width > 1024 || decoded.height > 1024) {
      if (decoded.width >= decoded.height) {
        resized = img.copyResize(decoded, width: 1024);
      } else {
        resized = img.copyResize(decoded, height: 1024);
      }
    }

    return Uint8List.fromList(img.encodeJpg(resized, quality: 85));
  }

  /// Fotoğraf yükle: Firebase Storage'a yükler, Firestore'a kayıt oluşturur.
  /// Firestore yazımı başarısız olursa, Storage'daki orphan dosya silinir.
  Future<EventPhotoModel> uploadPhoto({
    required String meetupId,
    required String userId,
    required String userName,
    String? userImageUrl,
    required Uint8List imageBytes,
  }) async {
    Reference? uploadedRef;
    try {
      // Sıkıştır
      final compressed = compressImage(imageBytes);

      // Benzersiz ID oluştur
      final photoId = _firestore
          .collection('meetups')
          .doc(meetupId)
          .collection('photos')
          .doc()
          .id;

      // Firebase Storage'a yükle
      final ref = _storage.ref('event_photos/$meetupId/$photoId.jpg');
      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {'uploadedBy': userId, 'meetupId': meetupId},
      );
      final uploadTask = ref.putData(compressed, metadata);
      final snapshot = await uploadTask;
      uploadedRef = snapshot.ref; // Track for potential rollback
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Firestore kaydı oluştur
      final now = DateTime.now();
      final photo = EventPhotoModel(
        id: photoId,
        meetupId: meetupId,
        userId: userId,
        userName: userName,
        userImageUrl: userImageUrl,
        photoUrl: downloadUrl,
        createdAt: now,
      );

      await _firestore
          .collection('meetups')
          .doc(meetupId)
          .collection('photos')
          .doc(photoId)
          .set({
        ...photo.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      return photo;
    } catch (e) {
      // Rollback: If Firestore write failed but Storage upload succeeded, delete orphan file
      if (uploadedRef != null) {
        try {
          await uploadedRef.delete();
        } catch (_) {
          // Ignore rollback errors - orphan cleanup can happen later
        }
      }
      throw Exception('Fotoğraf yüklenirken bir hata oluştu: $e');
    }
  }

  /// Belirli etkinliğin fotoğraflarını stream olarak getirir (createdAt azalan sıra).
  /// [limit] parametresi ile döndürülecek maksimum fotoğraf sayısı belirlenebilir (varsayılan: 50).
  Stream<List<EventPhotoModel>> getPhotosForMeetup(String meetupId, {int limit = 50}) {
    return _firestore
        .collection('meetups')
        .doc(meetupId)
        .collection('photos')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              EventPhotoModel.fromJson(doc.data()))
          .toList();
    });
  }

  /// Tüm aktif etkinliklerin fotoğraflarını birleşik stream olarak getirir.
  Stream<List<EventPhotoModel>> getLivePhotosStream() {
    final controller = StreamController<List<EventPhotoModel>>.broadcast();
    StreamSubscription? activeMeetupsSubscription;
    final innerSubscriptions = <StreamSubscription>[];
    var latestValues = <String, List<EventPhotoModel>>{};

    void cancelInnerSubscriptions() {
      for (final sub in innerSubscriptions) {
        sub.cancel();
      }
      innerSubscriptions.clear();
      latestValues.clear();
    }

    void emitCombined() {
      final combined = latestValues.values.expand((list) => list).toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      controller.add(combined);
    }

    activeMeetupsSubscription =
        _meetupService.getActiveMeetupsStream().listen((activeMeetups) {
      cancelInnerSubscriptions();

      if (activeMeetups.isEmpty) {
        controller.add(<EventPhotoModel>[]);
        return;
      }

      for (final meetup in activeMeetups) {
        innerSubscriptions.add(
          getPhotosForMeetup(meetup.id).listen(
            (photos) {
              latestValues[meetup.id] = photos;
              emitCombined();
            },
            onError: controller.addError,
          ),
        );
      }
    }, onError: controller.addError);

    controller.onCancel = () {
      cancelInnerSubscriptions();
      activeMeetupsSubscription?.cancel();
    };

    return controller.stream;
  }
}
