import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/live_broadcast_service.dart';
import 'models/models.dart';

/// Gerçek zamanlı sohbet işlemlerini yöneten bileşen
class ChatManager extends ChangeNotifier {
  final LiveBroadcastService _service;

  String? _currentStreamId;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  StreamSubscription<List<ChatMessage>>? _messagesSubscription;

  ChatManager({LiveBroadcastService? service})
      : _service = service ?? LiveBroadcastService();

  // Getters
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get currentStreamId => _currentStreamId;

  /// Sohbet odasına katıl
  Future<void> joinChatRoom(String streamId) async {
    debugPrint('[ChatManager] Joining chat room: $streamId');
    _currentStreamId = streamId;
    _messages.clear();
    _clearError();

    try {
      // Geçmiş mesajları yükle
      final history = await _service.loadChatHistory(streamId, limit: 50);
      debugPrint('[ChatManager] Loaded ${history.length} history messages');
      _messages.addAll(history);
      notifyListeners();

      // Gerçek zamanlı mesajları dinle
      _subscribeToMessages(streamId);
      debugPrint('[ChatManager] Subscribed to real-time messages');
    } catch (e) {
      debugPrint('[ChatManager] ERROR joining chat: $e');
      _setError('Sohbet yüklenemedi');
    }
  }

  /// Sohbet odasından ayrıl
  void leaveChatRoom() {
    _messagesSubscription?.cancel();
    _messagesSubscription = null;
    _currentStreamId = null;
    _messages.clear();
    notifyListeners();
  }

  /// Mesaj gönder (3 deneme ile retry)
  Future<bool> sendMessage(String message) async {
    debugPrint('[ChatManager] sendMessage called: "$message", streamId=$_currentStreamId');
    if (_currentStreamId == null) {
      debugPrint('[ChatManager] ERROR: No stream ID, not in a chat room');
      _setError('Sohbet odasına katılmadınız');
      return false;
    }

    // Boş mesaj kontrolü
    if (!ChatMessage.isValidMessage(message)) {
      debugPrint('[ChatManager] Invalid message (empty/whitespace)');
      return false; // Sessizce engelle
    }

    _setLoading(true);

    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await _service.sendMessage(
          streamId: _currentStreamId!,
          message: message,
        );
        debugPrint('[ChatManager] Message sent successfully');
        _setLoading(false);
        return true;
      } catch (e) {
        debugPrint('[ChatManager] Send failed (attempt $attempt/$maxRetries): $e');
        if (attempt == maxRetries) {
          _setError('Mesaj gönderilemedi. Tekrar deneyin.');
          _setLoading(false);
          return false;
        }
        // Wait before retry
        await Future.delayed(Duration(milliseconds: 500 * attempt));
      }
    }

    _setLoading(false);
    return false;
  }

  /// Daha fazla geçmiş mesaj yükle
  Future<void> loadMoreHistory() async {
    if (_currentStreamId == null || _messages.isEmpty) return;

    _setLoading(true);

    try {
      final oldestMessage = _messages.first;
      final moreMessages = await _service.loadChatHistory(
        _currentStreamId!,
        limit: 50,
      );

      // Sadece daha eski mesajları ekle
      final newMessages = moreMessages
          .where((m) => m.timestamp.isBefore(oldestMessage.timestamp))
          .toList();

      if (newMessages.isNotEmpty) {
        _messages.insertAll(0, newMessages);
        notifyListeners();
      }
    } catch (e) {
      _setError('Mesaj geçmişi yüklenemedi');
    } finally {
      _setLoading(false);
    }
  }

  // Private methods

  void _subscribeToMessages(String streamId) {
    _messagesSubscription?.cancel();

    _messagesSubscription = _service.watchMessages(streamId).listen(
      (messages) {
        debugPrint('[ChatManager] Received ${messages.length} messages from Firestore for stream: $streamId');
        _messages.clear();
        _messages.addAll(messages);
        notifyListeners();
      },
      onError: (e) {
        debugPrint('[ChatManager] Mesaj dinleme hatası: $e');
        _setError('Bağlantı kesildi. Yeniden bağlanılıyor...');
        // Otomatik yeniden bağlanma
        _reconnect(streamId);
      },
    );
  }

  Future<void> _reconnect(String streamId) async {
    const maxReconnectAttempts = 5;
    for (int i = 1; i <= maxReconnectAttempts; i++) {
      await Future.delayed(Duration(seconds: 2 * i));
      if (_currentStreamId != streamId) return; // User left

      try {
        debugPrint('[ChatManager] Reconnect attempt $i/$maxReconnectAttempts');
        _subscribeToMessages(streamId);
        _clearError();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('[ChatManager] Reconnect failed: $e');
      }
    }
    _setError('Bağlantı kurulamadı. Lütfen yeniden deneyin.');
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
    _messagesSubscription?.cancel();
    super.dispose();
  }
}
