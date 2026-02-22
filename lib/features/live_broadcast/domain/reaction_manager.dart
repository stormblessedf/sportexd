import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/live_broadcast_service.dart';
import 'models/models.dart';

/// Tepki sistemini yöneten bileşen
class ReactionManager extends ChangeNotifier {
  final LiveBroadcastService _service;

  String? _currentStreamId;
  final List<Reaction> _recentReactions = [];
  int _totalReactions = 0;
  bool _isLoading = false;

  StreamSubscription<List<Reaction>>? _reactionsSubscription;

  // Animasyon için callback
  void Function(Reaction reaction)? onReactionReceived;

  ReactionManager({LiveBroadcastService? service})
      : _service = service ?? LiveBroadcastService();

  // Getters
  List<Reaction> get recentReactions => List.unmodifiable(_recentReactions);
  int get totalReactions => _totalReactions;
  bool get isLoading => _isLoading;
  String? get currentStreamId => _currentStreamId;

  /// Tepki sistemine katıl
  void joinStream(String streamId) {
    _currentStreamId = streamId;
    _recentReactions.clear();
    _totalReactions = 0;

    _subscribeToReactions(streamId);
  }

  /// Tepki sisteminden ayrıl
  void leaveStream() {
    _reactionsSubscription?.cancel();
    _reactionsSubscription = null;
    _currentStreamId = null;
    _recentReactions.clear();
    notifyListeners();
  }

  /// Tepki gönder
  Future<bool> sendReaction({ReactionType type = ReactionType.heart}) async {
    if (_currentStreamId == null) return false;

    _setLoading(true);

    try {
      final reaction = await _service.sendReaction(
        streamId: _currentStreamId!,
        type: type,
      );

      // Kendi tepkimiz için animasyon tetikle
      onReactionReceived?.call(reaction);

      return true;
    } catch (e) {
      debugPrint('Tepki gönderme hatası: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toplam tepki sayısını güncelle
  void updateTotalReactions(int count) {
    _totalReactions = count;
    notifyListeners();
  }

  // Private methods

  void _subscribeToReactions(String streamId) {
    _reactionsSubscription?.cancel();

    _reactionsSubscription = _service.watchReactions(streamId).listen(
      (reactions) {
        // Yeni tepkileri bul ve animasyon tetikle
        for (final reaction in reactions) {
          if (!_recentReactions.any((r) => r.id == reaction.id)) {
            onReactionReceived?.call(reaction);
          }
        }

        _recentReactions.clear();
        _recentReactions.addAll(reactions);
        notifyListeners();
      },
      onError: (e) {
        debugPrint('Tepki dinleme hatası: $e');
      },
    );
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  @override
  void dispose() {
    _reactionsSubscription?.cancel();
    super.dispose();
  }
}
