import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/live_broadcast_service.dart';

/// İzleyici sayısını takip eden bileşen
class ViewerTracker extends ChangeNotifier {
  final LiveBroadcastService _service;

  String? _currentStreamId;
  int _currentViewerCount = 0;
  int _peakViewerCount = 0;

  StreamSubscription<int>? _viewerCountSubscription;

  ViewerTracker({LiveBroadcastService? service})
      : _service = service ?? LiveBroadcastService();

  // Getters
  int get currentViewerCount => _currentViewerCount;
  int get peakViewerCount => _peakViewerCount;
  String? get currentStreamId => _currentStreamId;

  /// İzleyici takibine başla
  void startTracking(String streamId) {
    _currentStreamId = streamId;
    _currentViewerCount = 0;
    _peakViewerCount = 0;

    _subscribeToViewerCount(streamId);
  }

  /// İzleyici takibini durdur
  void stopTracking() {
    _viewerCountSubscription?.cancel();
    _viewerCountSubscription = null;
    _currentStreamId = null;
    _currentViewerCount = 0;
    notifyListeners();
  }

  /// İzleyici sayısını manuel güncelle
  void updateViewerCount(int count) {
    _currentViewerCount = count;

    // Peak'i güncelle (asla azalmaz)
    if (count > _peakViewerCount) {
      _peakViewerCount = count;
    }

    notifyListeners();
  }

  /// Formatlanmış izleyici sayısı
  String get formattedViewerCount {
    if (_currentViewerCount >= 1000000) {
      return '${(_currentViewerCount / 1000000).toStringAsFixed(1)}M';
    } else if (_currentViewerCount >= 1000) {
      return '${(_currentViewerCount / 1000).toStringAsFixed(1)}K';
    }
    return _currentViewerCount.toString();
  }

  // Private methods

  void _subscribeToViewerCount(String streamId) {
    _viewerCountSubscription?.cancel();

    _viewerCountSubscription = _service.watchViewerCount(streamId).listen(
      (count) {
        updateViewerCount(count);
      },
      onError: (e) {
        debugPrint('İzleyici sayısı dinleme hatası: $e');
      },
    );
  }

  @override
  void dispose() {
    _viewerCountSubscription?.cancel();
    super.dispose();
  }
}
