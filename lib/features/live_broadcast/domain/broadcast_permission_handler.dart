import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:permission_handler/permission_handler.dart';

/// Canlı yayın için kamera ve mikrofon izinlerini yöneten sınıf
class BroadcastPermissionHandler {
  /// Kamera izni durumunu kontrol et
  Future<bool> checkCameraPermission() async {
    // Web'de izinler getUserMedia ile tarayıcı tarafından yönetilir
    if (kIsWeb) return true;

    final status = await Permission.camera.status;
    return status.isGranted;
  }

  /// Mikrofon izni durumunu kontrol et
  Future<bool> checkMicrophonePermission() async {
    // Web'de izinler getUserMedia ile tarayıcı tarafından yönetilir
    if (kIsWeb) return true;

    final status = await Permission.microphone.status;
    return status.isGranted;
  }

  /// Tüm gerekli izinleri kontrol et
  Future<BroadcastPermissionResult> checkAllPermissions() async {
    // Web'de izinler getUserMedia ile tarayıcı tarafından yönetilir
    if (kIsWeb) {
      return const BroadcastPermissionResult(
        cameraGranted: true,
        microphoneGranted: true,
        cameraDenied: false,
        microphoneDenied: false,
        cameraPermanentlyDenied: false,
        microphonePermanentlyDenied: false,
      );
    }

    final cameraStatus = await Permission.camera.status;
    final microphoneStatus = await Permission.microphone.status;

    return BroadcastPermissionResult(
      cameraGranted: cameraStatus.isGranted,
      microphoneGranted: microphoneStatus.isGranted,
      cameraDenied: cameraStatus.isDenied,
      microphoneDenied: microphoneStatus.isDenied,
      cameraPermanentlyDenied: cameraStatus.isPermanentlyDenied,
      microphonePermanentlyDenied: microphoneStatus.isPermanentlyDenied,
    );
  }

  /// Kamera iznini talep et
  Future<PermissionStatus> requestCameraPermission() async {
    // Web'de izinler getUserMedia ile tarayıcı tarafından yönetilir
    if (kIsWeb) return PermissionStatus.granted;

    return await Permission.camera.request();
  }

  /// Mikrofon iznini talep et
  Future<PermissionStatus> requestMicrophonePermission() async {
    // Web'de izinler getUserMedia ile tarayıcı tarafından yönetilir
    if (kIsWeb) return PermissionStatus.granted;

    return await Permission.microphone.request();
  }

  /// Tüm gerekli izinleri talep et
  Future<BroadcastPermissionResult> requestAllPermissions() async {
    // Web'de izinler getUserMedia ile tarayıcı tarafından yönetilir
    if (kIsWeb) {
      return const BroadcastPermissionResult(
        cameraGranted: true,
        microphoneGranted: true,
        cameraDenied: false,
        microphoneDenied: false,
        cameraPermanentlyDenied: false,
        microphonePermanentlyDenied: false,
      );
    }

    final results = await [
      Permission.camera,
      Permission.microphone,
    ].request();

    final cameraStatus = results[Permission.camera] ?? PermissionStatus.denied;
    final microphoneStatus =
        results[Permission.microphone] ?? PermissionStatus.denied;

    return BroadcastPermissionResult(
      cameraGranted: cameraStatus.isGranted,
      microphoneGranted: microphoneStatus.isGranted,
      cameraDenied: cameraStatus.isDenied,
      microphoneDenied: microphoneStatus.isDenied,
      cameraPermanentlyDenied: cameraStatus.isPermanentlyDenied,
      microphonePermanentlyDenied: microphoneStatus.isPermanentlyDenied,
    );
  }

  /// İzin ayarlarını aç
  Future<bool> openPermissionSettings() async {
    return await openAppSettings();
  }

  /// Yayın başlatmaya hazır mı kontrol et
  Future<bool> isReadyForBroadcast() async {
    final result = await checkAllPermissions();
    return result.allGranted;
  }

  /// Hata mesajı oluştur
  String getErrorMessage(BroadcastPermissionResult result) {
    if (result.allGranted) {
      return '';
    }

    final List<String> missing = [];

    if (!result.cameraGranted) {
      missing.add('kamera');
    }
    if (!result.microphoneGranted) {
      missing.add('mikrofon');
    }

    if (result.cameraPermanentlyDenied || result.microphonePermanentlyDenied) {
      return 'Canlı yayın için ${missing.join(' ve ')} erişimi gereklidir. '
          'Lütfen ayarlardan izinleri etkinleştirin.';
    }

    return 'Canlı yayın için ${missing.join(' ve ')} erişimi gereklidir.';
  }
}

/// İzin kontrol sonucu
class BroadcastPermissionResult {
  final bool cameraGranted;
  final bool microphoneGranted;
  final bool cameraDenied;
  final bool microphoneDenied;
  final bool cameraPermanentlyDenied;
  final bool microphonePermanentlyDenied;

  const BroadcastPermissionResult({
    required this.cameraGranted,
    required this.microphoneGranted,
    required this.cameraDenied,
    required this.microphoneDenied,
    required this.cameraPermanentlyDenied,
    required this.microphonePermanentlyDenied,
  });

  /// Tüm izinler verildi mi
  bool get allGranted => cameraGranted && microphoneGranted;

  /// Herhangi bir izin kalıcı olarak reddedildi mi
  bool get anyPermanentlyDenied =>
      cameraPermanentlyDenied || microphonePermanentlyDenied;

  /// Herhangi bir izin reddedildi mi
  bool get anyDenied => cameraDenied || microphoneDenied;

  @override
  String toString() {
    return 'BroadcastPermissionResult('
        'camera: ${cameraGranted ? "granted" : "denied"}, '
        'microphone: ${microphoneGranted ? "granted" : "denied"})';
  }
}
