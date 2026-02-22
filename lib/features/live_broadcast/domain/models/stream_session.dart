import 'package:cloud_firestore/cloud_firestore.dart';
import 'stream_enums.dart';

/// Canlı yayın oturumunu temsil eden model
class StreamSession {
  final String id;
  final String broadcasterId;
  final String broadcasterName;
  final String broadcasterAvatar;
  final String eventId;
  final String eventName;
  final String? streamUrl;
  final StreamQuality quality;
  final PrivacyLevel privacy;
  final StreamStatus status;
  final DateTime startedAt;
  final DateTime? endedAt;
  final int currentViewers;
  final int peakViewers;
  final int totalReactions;
  final bool isRecordingEnabled;
  final String? recordingUrl;
  final String? thumbnailUrl;

  const StreamSession({
    required this.id,
    required this.broadcasterId,
    required this.broadcasterName,
    required this.broadcasterAvatar,
    required this.eventId,
    required this.eventName,
    this.streamUrl,
    required this.quality,
    required this.privacy,
    required this.status,
    required this.startedAt,
    this.endedAt,
    this.currentViewers = 0,
    this.peakViewers = 0,
    this.totalReactions = 0,
    this.isRecordingEnabled = false,
    this.recordingUrl,
    this.thumbnailUrl,
  });

  /// Yayın canlı mı kontrol et
  bool get isLive => status == StreamStatus.live;

  /// Yayın süresi
  Duration get duration {
    final end = endedAt ?? DateTime.now();
    return end.difference(startedAt);
  }

  /// Formatlanmış süre
  String get formattedDuration {
    final d = duration;
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  StreamSession copyWith({
    String? id,
    String? broadcasterId,
    String? broadcasterName,
    String? broadcasterAvatar,
    String? eventId,
    String? eventName,
    String? streamUrl,
    StreamQuality? quality,
    PrivacyLevel? privacy,
    StreamStatus? status,
    DateTime? startedAt,
    DateTime? endedAt,
    int? currentViewers,
    int? peakViewers,
    int? totalReactions,
    bool? isRecordingEnabled,
    String? recordingUrl,
    String? thumbnailUrl,
  }) {
    return StreamSession(
      id: id ?? this.id,
      broadcasterId: broadcasterId ?? this.broadcasterId,
      broadcasterName: broadcasterName ?? this.broadcasterName,
      broadcasterAvatar: broadcasterAvatar ?? this.broadcasterAvatar,
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      streamUrl: streamUrl ?? this.streamUrl,
      quality: quality ?? this.quality,
      privacy: privacy ?? this.privacy,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      currentViewers: currentViewers ?? this.currentViewers,
      peakViewers: peakViewers ?? this.peakViewers,
      totalReactions: totalReactions ?? this.totalReactions,
      isRecordingEnabled: isRecordingEnabled ?? this.isRecordingEnabled,
      recordingUrl: recordingUrl ?? this.recordingUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  factory StreamSession.fromJson(Map<String, dynamic> json) {
    final statusStr = json['status'] as String?;
    final parsedStatus = StreamStatus.values.firstWhere(
      (e) => e.name == statusStr,
      orElse: () => StreamStatus.ended,
    );

    return StreamSession(
      id: json['id'] as String,
      broadcasterId: json['broadcasterId'] as String,
      broadcasterName: json['broadcasterName'] as String,
      broadcasterAvatar: json['broadcasterAvatar'] as String? ?? '',
      eventId: json['eventId'] as String,
      eventName: json['eventName'] as String,
      streamUrl: json['streamUrl'] as String?,
      quality: StreamQuality.values.firstWhere(
        (e) => e.name == json['quality'],
        orElse: () => StreamQuality.auto,
      ),
      privacy: PrivacyLevel.values.firstWhere(
        (e) => e.name == json['privacy'],
        orElse: () => PrivacyLevel.public,
      ),
      status: parsedStatus,
      startedAt: _parseDateTime(json['startedAt']),
      endedAt: json['endedAt'] != null ? _parseDateTime(json['endedAt']) : null,
      currentViewers: json['currentViewers'] as int? ?? 0,
      peakViewers: json['peakViewers'] as int? ?? 0,
      totalReactions: json['totalReactions'] as int? ?? 0,
      isRecordingEnabled: json['isRecordingEnabled'] as bool? ?? false,
      recordingUrl: json['recordingUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'broadcasterId': broadcasterId,
      'broadcasterName': broadcasterName,
      'broadcasterAvatar': broadcasterAvatar,
      'eventId': eventId,
      'eventName': eventName,
      'streamUrl': streamUrl,
      'quality': quality.name,
      'privacy': privacy.name,
      'status': status.name,
      'startedAt': Timestamp.fromDate(startedAt),
      'endedAt': endedAt != null ? Timestamp.fromDate(endedAt!) : null,
      'currentViewers': currentViewers,
      'peakViewers': peakViewers,
      'totalReactions': totalReactions,
      'isRecordingEnabled': isRecordingEnabled,
      'recordingUrl': recordingUrl,
      'thumbnailUrl': thumbnailUrl,
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
    return 'StreamSession(id: $id, broadcaster: $broadcasterName, event: $eventName, status: $status)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is StreamSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
