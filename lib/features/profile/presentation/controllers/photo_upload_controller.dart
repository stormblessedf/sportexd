import 'package:flutter/foundation.dart';

/// MainShell ile PhotoGridTab arasında fotoğraf yükleme iletişimini sağlayan controller.
///
/// MainShell butona basıldığında [triggerUpload] çağırır;
/// PhotoGridTab bunu dinleyerek yükleme akışını başlatır.
/// [isUploading] durumu MainShell'deki butonun devre dışı olmasını sağlar.
class PhotoUploadController extends ChangeNotifier {
  /// Singleton instance for cross-widget communication.
  static final instance = PhotoUploadController();

  bool _isUploading = false;
  bool _shouldTriggerUpload = false;

  bool get isUploading => _isUploading;
  bool get shouldTriggerUpload => _shouldTriggerUpload;

  /// Fotoğraf yükleme akışını tetikler.
  /// PhotoGridTab bu değişikliği dinleyerek _pickAndUploadPhoto() başlatır.
  void triggerUpload() {
    _shouldTriggerUpload = true;
    notifyListeners();
  }

  /// Tetikleme sinyalini tüketir (PhotoGridTab tarafından çağrılır).
  /// notifyListeners çağırmaz çünkü bu bir iç durum sıfırlamasıdır.
  void consumeTrigger() {
    _shouldTriggerUpload = false;
  }

  /// Yükleme durumunu günceller.
  /// [value] true ise yükleme devam ediyor, false ise tamamlandı.
  void setUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }
}
