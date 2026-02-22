import 'package:cloud_firestore/cloud_firestore.dart';

/// Yayın istatistiklerini temsil eden model
class StreamStatistics {
  final String streamId;
  final Duration duration;
  final int totalViewers;
  final int peakViewers;
  final int totalMessages;
  final int totalReactions;
  final Map<String, int> viewersByMinute;
  final DateTime? recordedAt;

  const StreamStatistics({
    required this.streamId,
    required this.duration,
    required this.totalViewers,
    required this.peakViewers,
    required this.totalMessages,
    required this.totalReactions,
    required this.viewersByMinute,
    this.recordedAt,
  });

  /// Boş istatistik
  factory StreamStatistics.empty(String streamId) {
    return StreamStatistics(
      streamId: streamId,
      duration: Duration.zero,
      totalViewers: 0,
      peakViewers: 0,
      totalMessages: 0,
      totalReactions: 0,
      viewersByMinute: {},
    );
  }

  /// Formatlanmış süre
  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours}s ${minutes}dk';
    }
    if (minutes > 0) {
      return '${minutes}dk ${seconds}sn';
    }
    return '${seconds}sn';
  }

  /// Ortalama izleyici sayısı
  double get averageViewers {
    if (viewersByMinute.isEmpty) return 0;
    final total = viewersByMinute.values.reduce((a, b) => a + b);
    return total / viewersByMinute.length;
  }

  StreamStatistics copyWith({
    String? streamId,
    Duration? duration,
    int? totalViewers,
    int? peakViewers,
    int? totalMessages,
    int? totalReactions,
    Map<String, int>? viewersByMinute,
    DateTime? recordedAt,
  }) {
    return StreamStatistics(
      streamId: streamId ?? this.streamId,
      duration: duration ?? this.duration,
      totalViewers: totalViewers ?? this.totalViewers,
      peakViewers: peakViewers ?? this.peakViewers,
      totalMessages: totalMessages ?? this.totalMessages,
      totalReactions: totalReactions ?? this.totalReactions,
      viewersByMinute: viewersByMinute ?? this.viewersByMinute,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  factory StreamStatistics.fromJson(Map<String, dynamic> json) {
    return StreamStatistics(
      streamId: json['streamId'] as String,
      duration: Duration(seconds: json['durationSeconds'] as int? ?? 0),
      totalViewers: json['totalViewers'] as int? ?? 0,
      peakViewers: json['peakViewers'] as int? ?? 0,
      totalMessages: json['totalMessages'] as int? ?? 0,
      totalReactions: json['totalReactions'] as int? ?? 0,
      viewersByMinute: Map<String, int>.from(json['viewersByMinute'] ?? {}),
      recordedAt: json['recordedAt'] != null
          ? _parseDateTime(json['recordedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'streamId': streamId,
      'durationSeconds': duration.inSeconds,
      'totalViewers': totalViewers,
      'peakViewers': peakViewers,
      'totalMessages': totalMessages,
      'totalReactions': totalReactions,
      'viewersByMinute': viewersByMinute,
      'recordedAt':
          recordedAt != null ? Timestamp.fromDate(recordedAt!) : null,
    };
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    return DateTime.now();
  }

  @override
  String toString() {
    return 'StreamStatistics(streamId: $streamId, duration: $formattedDuration, peakViewers: $peakViewers)';
  }
}
