import 'package:cloud_firestore/cloud_firestore.dart';
import 'stream_enums.dart';

/// Canlı yayın tepkisini temsil eden model
class Reaction {
  final String id;
  final String streamId;
  final String userId;
  final ReactionType type;
  final DateTime timestamp;

  const Reaction({
    required this.id,
    required this.streamId,
    required this.userId,
    required this.type,
    required this.timestamp,
  });

  Reaction copyWith({
    String? id,
    String? streamId,
    String? userId,
    ReactionType? type,
    DateTime? timestamp,
  }) {
    return Reaction(
      id: id ?? this.id,
      streamId: streamId ?? this.streamId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as String,
      streamId: json['streamId'] as String,
      userId: json['userId'] as String,
      type: ReactionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ReactionType.heart,
      ),
      timestamp: _parseDateTime(json['timestamp']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'streamId': streamId,
      'userId': userId,
      'type': type.name,
      'timestamp': Timestamp.fromDate(timestamp),
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
    return 'Reaction(id: $id, type: $type, userId: $userId)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Reaction && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}
