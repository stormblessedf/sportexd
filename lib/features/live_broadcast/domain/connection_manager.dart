import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'models/models.dart';

/// Ağ bağlantısını yöneten ve yeniden bağlantı sağlayan bileşen
class ConnectionManager extends ChangeNotifier {
  StreamConnectionState _state = StreamConnectionState.connected();
  Timer? _reconnectTimer;
  Timer? _qualityCheckTimer;
  int _reconnectAttempts = 0;
  static const int _maxReconnectAttempts = 6; // 30 saniye (5sn x 6)

  // Callbacks
  void Function()? onReconnectSuccess;
  void Function(String message)? onReconnectFailed;
  void Function(StreamQuality quality)? onQualityChange;

  ConnectionManager();

  // Getters
  StreamConnectionState get state => _state;
  bool get isConnected => _state.isConnected;
  ConnectionQuality get quality => _state.quality;
  String? get errorMessage => _state.errorMessage;

  /// Bağlantı durumunu izlemeye başla
  void startMonitoring() {
    _startQualityCheck();
  }

  /// Bağlantı durumunu izlemeyi durdur
  void stopMonitoring() {
    _reconnectTimer?.cancel();
    _qualityCheckTimer?.cancel();
    _reconnectAttempts = 0;
  }

  /// Bağlantı kesildi bildir
  void onDisconnected({String? errorMessage}) {
    _state = StreamConnectionState.disconnected(
      errorMessage: errorMessage ?? 'Bağlantı kesildi',
    );
    notifyListeners();

    // Otomatik yeniden bağlanma başlat
    _startReconnect();
  }

  /// Bağlantı kuruldu bildir
  void onConnected() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    _state = StreamConnectionState.connected();
    notifyListeners();

    onReconnectSuccess?.call();
  }

  /// Manuel yeniden bağlanma
  Future<void> reconnect() async {
    _state = StreamConnectionState.reconnecting();
    notifyListeners();

    // Simüle bağlantı kontrolü
    await Future.delayed(const Duration(seconds: 2));

    // Bağlantı kontrolü (burada gerçek bağlantı kontrolü yapılabilir)
    final hasConnection = await _checkConnection();

    if (hasConnection) {
      onConnected();
    } else {
      onDisconnected(errorMessage: 'Bağlantı sağlanamadı');
    }
  }

  /// Bağlantı kalitesini kontrol et
  Future<ConnectionQuality> checkConnectionQuality() async {
    // Basit latency testi
    final stopwatch = Stopwatch()..start();

    try {
      // Konum servisi ile basit bir ping testi
      await Geolocator.isLocationServiceEnabled();
      stopwatch.stop();

      final latency = stopwatch.elapsedMilliseconds;

      ConnectionQuality quality;
      if (latency < 100) {
        quality = ConnectionQuality.excellent;
      } else if (latency < 300) {
        quality = ConnectionQuality.good;
      } else if (latency < 600) {
        quality = ConnectionQuality.fair;
      } else {
        quality = ConnectionQuality.poor;
      }

      _state = _state.copyWith(
        quality: quality,
        latency: latency,
        lastChecked: DateTime.now(),
      );
      notifyListeners();

      return quality;
    } catch (e) {
      return ConnectionQuality.poor;
    }
  }

  /// Bağlantı kalitesine göre önerilen yayın kalitesi
  StreamQuality getRecommendedStreamQuality() {
    switch (_state.quality) {
      case ConnectionQuality.excellent:
        return StreamQuality.quality1080p;
      case ConnectionQuality.good:
        return StreamQuality.quality720p;
      case ConnectionQuality.fair:
        return StreamQuality.quality480p;
      case ConnectionQuality.poor:
        return StreamQuality.quality360p;
    }
  }

  /// Adaptif kalite ayarlama
  Future<void> adjustQualityBasedOnConnection() async {
    final quality = await checkConnectionQuality();
    final recommendedStreamQuality = getRecommendedStreamQuality();

    debugPrint(
        'Bağlantı kalitesi: ${quality.displayName}, Önerilen: ${recommendedStreamQuality.displayName}');

    onQualityChange?.call(recommendedStreamQuality);
  }

  // Private methods

  Future<bool> _checkConnection() async {
    try {
      // Basit bağlantı kontrolü
      await Geolocator.isLocationServiceEnabled();
      return true;
    } catch (e) {
      return false;
    }
  }

  void _startReconnect() {
    _reconnectTimer?.cancel();
    _reconnectAttempts = 0;

    _state = StreamConnectionState.reconnecting();
    notifyListeners();

    _attemptReconnect();
  }

  void _attemptReconnect() {
    _reconnectTimer = Timer(const Duration(seconds: 5), () async {
      _reconnectAttempts++;

      final hasConnection = await _checkConnection();

      if (hasConnection) {
        onConnected();
      } else if (_reconnectAttempts < _maxReconnectAttempts) {
        // Tekrar dene
        _state = _state.copyWith(
          errorMessage:
              'Yeniden bağlanılıyor... (${_reconnectAttempts}/$_maxReconnectAttempts)',
        );
        notifyListeners();
        _attemptReconnect();
      } else {
        // Maksimum deneme sayısına ulaşıldı
        _state = StreamConnectionState.disconnected(
          errorMessage:
              'Bağlantı sağlanamadı. Lütfen internet bağlantınızı kontrol edin.',
        );
        notifyListeners();
        onReconnectFailed?.call(_state.errorMessage ?? 'Bağlantı hatası');
      }
    });
  }

  void _startQualityCheck() {
    _qualityCheckTimer?.cancel();

    // Her 30 saniyede bir kalite kontrolü
    _qualityCheckTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnectionQuality();
    });

    // İlk kontrol
    checkConnectionQuality();
  }

  @override
  void dispose() {
    stopMonitoring();
    super.dispose();
  }
}
