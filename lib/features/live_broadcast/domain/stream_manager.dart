import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/live_broadcast_service.dart';
import 'broadcast_permission_handler.dart';
import 'models/models.dart';

/// Yayın yaşam döngüsünü yöneten ana bileşen
class StreamManager extends ChangeNotifier {
  final LiveBroadcastService _service;
  final BroadcastPermissionHandler _permissionHandler;

  StreamSession? _currentStream;
  StreamStatus _status = StreamStatus.ended;
  String? _errorMessage;
  bool _isLoading = false;

  StreamSubscription<StreamSession?>? _streamSubscription;
  Timer? _durationTimer;

  StreamManager({
    LiveBroadcastService? service,
    BroadcastPermissionHandler? permissionHandler,
  })  : _service = service ?? LiveBroadcastService(),
        _permissionHandler = permissionHandler ?? BroadcastPermissionHandler();

  // Getters
  StreamSession? get currentStream => _currentStream;
  StreamStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isBroadcasting =>
      _status == StreamStatus.live || _status == StreamStatus.starting;
  bool get isLive => _status == StreamStatus.live;

  /// Yayın başlat
  Future<StreamSession?> startBroadcast({
    required String eventId,
    required String eventName,
    StreamQuality quality = StreamQuality.auto,
    PrivacyLevel privacy = PrivacyLevel.public,
    bool isRecordingEnabled = false,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      debugPrint('[StreamManager] Checking permissions...');

      // İzinleri kontrol et
      final permissionResult =
          await _permissionHandler.requestAllPermissions();

      debugPrint('[StreamManager] Permission result: ${permissionResult.allGranted}');

      if (!permissionResult.allGranted) {
        _setError(_permissionHandler.getErrorMessage(permissionResult));
        debugPrint('[StreamManager] Permission denied: ${_permissionHandler.getErrorMessage(permissionResult)}');
        return null;
      }

      // Yayını oluştur
      _status = StreamStatus.starting;
      notifyListeners();

      debugPrint('[StreamManager] Creating stream in Firestore...');

      final stream = await _service.createStream(
        eventId: eventId,
        eventName: eventName,
        quality: quality,
        privacy: privacy,
        isRecordingEnabled: isRecordingEnabled,
      );

      debugPrint('[StreamManager] Stream created: ${stream.id}');
      _currentStream = stream;

      // Yayını başlat
      debugPrint('[StreamManager] Starting stream (setting status to live)...');
      final liveStream = await _service.startStream(stream.id);
      _currentStream = liveStream;
      _status = StreamStatus.live;

      debugPrint('[StreamManager] Stream is now LIVE: ${liveStream.id}, status: ${liveStream.status}');

      // Yayın güncellemelerini dinle
      _subscribeToStream(stream.id);

      // Süre sayacını başlat
      _startDurationTimer();

      notifyListeners();
      return liveStream;
    } catch (e, stackTrace) {
      debugPrint('[StreamManager] ERROR: $e');
      debugPrint('[StreamManager] Stack trace: $stackTrace');
      _setError('Yayın başlatılamadı: ${e.toString()}');
      _status = StreamStatus.error;
      notifyListeners();
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Yayını sonlandır
  Future<StreamStatistics?> stopBroadcast() async {
    if (_currentStream == null) return null;

    _setLoading(true);

    try {
      final statistics = await _service.endStream(_currentStream!.id);

      _status = StreamStatus.ended;
      _cancelSubscriptions();

      final endedStream = _currentStream!.copyWith(
        status: StreamStatus.ended,
        endedAt: DateTime.now(),
      );
      _currentStream = endedStream;

      notifyListeners();
      return statistics;
    } catch (e) {
      _setError('Yayın sonlandırılamadı: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Yayına katıl (izleyici olarak)
  Future<StreamSession?> joinStream(String streamId) async {
    _setLoading(true);
    _clearError();

    try {
      // Erişim kontrolü
      final canAccess = await _service.canAccessStream(streamId);
      if (!canAccess) {
        _setError('Bu yayına erişim izniniz yok');
        return null;
      }

      // İzleyici olarak katıl
      await _service.joinAsViewer(streamId);

      // Yayını al
      final stream = await _service.getStream(streamId);
      if (stream == null) {
        _setError('Yayın bulunamadı');
        return null;
      }

      _currentStream = stream;
      _status = stream.status;

      // Yayın güncellemelerini dinle
      _subscribeToStream(streamId);

      notifyListeners();
      return stream;
    } catch (e) {
      _setError('Yayına katılınamadı: ${e.toString()}');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Yayından ayrıl
  Future<void> leaveStream() async {
    if (_currentStream == null) return;

    try {
      await _service.leaveAsViewer(_currentStream!.id);
      _cancelSubscriptions();
      _currentStream = null;
      _status = StreamStatus.ended;
      notifyListeners();
    } catch (e) {
      debugPrint('Yayından ayrılırken hata: $e');
    }
  }

  /// Kaliteyi değiştir
  Future<void> changeQuality(StreamQuality quality) async {
    if (_currentStream == null) return;

    try {
      await _service.updateQuality(_currentStream!.id, quality);
      _currentStream = _currentStream!.copyWith(quality: quality);
      notifyListeners();
    } catch (e) {
      _setError('Kalite değiştirilemedi');
    }
  }

  /// Gizliliği değiştir
  Future<void> changePrivacy(PrivacyLevel privacy) async {
    if (_currentStream == null) return;

    try {
      await _service.updatePrivacy(_currentStream!.id, privacy);
      _currentStream = _currentStream!.copyWith(privacy: privacy);
      notifyListeners();
    } catch (e) {
      _setError('Gizlilik ayarı değiştirilemedi');
    }
  }

  /// Aktif yayınları getir
  Future<List<StreamSession>> getActiveStreams() async {
    return await _service.getActiveStreams();
  }

  /// Aktif yayınları dinle
  Stream<List<StreamSession>> watchActiveStreams() {
    return _service.watchActiveStreams();
  }

  /// Belirli bir yayını dinle
  Stream<StreamSession?> watchStream(String streamId) {
    return _service.watchStream(streamId);
  }

  /// Kullanıcının yayın geçmişini getir
  Future<List<StreamSession>> getUserStreamHistory(String userId) async {
    return await _service.getUserStreamHistory(userId);
  }

  /// İzleyici sayısını dinle
  Stream<int> watchViewerCount(String streamId) {
    return _service.watchViewerCount(streamId);
  }

  // Private methods

  void _subscribeToStream(String streamId) {
    _cancelSubscriptions();

    _streamSubscription = _service.watchStream(streamId).listen(
      (stream) {
        if (stream != null) {
          _currentStream = stream;
          _status = stream.status;
          notifyListeners();
        }
      },
      onError: (e) {
        _setError('Yayın bağlantısı kesildi');
      },
    );
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners(); // UI'ı güncelle (süre için)
    });
  }

  void _cancelSubscriptions() {
    _streamSubscription?.cancel();
    _streamSubscription = null;
    _durationTimer?.cancel();
    _durationTimer = null;
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  /// Hatayı temizle
  void clearError() {
    _clearError();
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelSubscriptions();
    super.dispose();
  }
}
