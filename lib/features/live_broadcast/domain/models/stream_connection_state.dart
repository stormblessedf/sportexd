import 'stream_enums.dart';

/// Yayın bağlantı durumunu temsil eden model
class StreamConnectionState {
  final bool isConnected;
  final ConnectionQuality quality;
  final int latency;
  final DateTime lastChecked;
  final String? errorMessage;

  const StreamConnectionState({
    required this.isConnected,
    required this.quality,
    required this.latency,
    required this.lastChecked,
    this.errorMessage,
  });

  /// Varsayılan bağlı durum
  factory StreamConnectionState.connected() {
    return StreamConnectionState(
      isConnected: true,
      quality: ConnectionQuality.good,
      latency: 50,
      lastChecked: DateTime.now(),
    );
  }

  /// Varsayılan bağlantı kesildi durumu
  factory StreamConnectionState.disconnected({String? errorMessage}) {
    return StreamConnectionState(
      isConnected: false,
      quality: ConnectionQuality.poor,
      latency: 0,
      lastChecked: DateTime.now(),
      errorMessage: errorMessage,
    );
  }

  /// Yeniden bağlanıyor durumu
  factory StreamConnectionState.reconnecting() {
    return StreamConnectionState(
      isConnected: false,
      quality: ConnectionQuality.poor,
      latency: 0,
      lastChecked: DateTime.now(),
      errorMessage: 'Yeniden bağlanılıyor...',
    );
  }

  StreamConnectionState copyWith({
    bool? isConnected,
    ConnectionQuality? quality,
    int? latency,
    DateTime? lastChecked,
    String? errorMessage,
  }) {
    return StreamConnectionState(
      isConnected: isConnected ?? this.isConnected,
      quality: quality ?? this.quality,
      latency: latency ?? this.latency,
      lastChecked: lastChecked ?? this.lastChecked,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() {
    return 'StreamConnectionState(connected: $isConnected, quality: $quality, latency: ${latency}ms)';
  }
}
