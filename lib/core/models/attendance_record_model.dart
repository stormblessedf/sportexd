import 'package:cloud_firestore/cloud_firestore.dart';

/// GPS proximity-based attendance record for a participant in a meetup.
/// Stored at: meetups/{meetupId}/attendance_records/{userId}
class AttendanceRecordModel {
  final String userId;
  final String status; // "attended" or "not_attended"
  final DateTime detectedAt;
  final double? distanceMeters; // Only for "attended"
  final String method; // "gps_proximity"

  const AttendanceRecordModel({
    required this.userId,
    required this.status,
    required this.detectedAt,
    this.distanceMeters,
    this.method = 'gps_proximity',
  });

  bool get didAttend => status == 'attended';

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'status': status,
      'detectedAt': detectedAt.toIso8601String(),
      'distanceMeters': distanceMeters,
      'method': method,
    };
  }

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    DateTime detectedAt;
    final detectedAtValue = json['detectedAt'];
    if (detectedAtValue is Timestamp) {
      detectedAt = detectedAtValue.toDate();
    } else if (detectedAtValue is String) {
      detectedAt = DateTime.tryParse(detectedAtValue) ?? DateTime.now();
    } else {
      detectedAt = DateTime.now();
    }

    return AttendanceRecordModel(
      userId: json['userId'] ?? '',
      status: json['status'] ?? 'not_attended',
      detectedAt: detectedAt,
      distanceMeters: (json['distanceMeters'] as num?)?.toDouble(),
      method: json['method'] ?? 'gps_proximity',
    );
  }

  AttendanceRecordModel copyWith({
    String? userId,
    String? status,
    DateTime? detectedAt,
    double? distanceMeters,
    String? method,
  }) {
    return AttendanceRecordModel(
      userId: userId ?? this.userId,
      status: status ?? this.status,
      detectedAt: detectedAt ?? this.detectedAt,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      method: method ?? this.method,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttendanceRecordModel &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          status == other.status &&
          detectedAt == other.detectedAt &&
          distanceMeters == other.distanceMeters &&
          method == other.method;

  @override
  int get hashCode =>
      userId.hashCode ^
      status.hashCode ^
      detectedAt.hashCode ^
      distanceMeters.hashCode ^
      method.hashCode;

  @override
  String toString() =>
      'AttendanceRecordModel(userId: $userId, status: $status, detectedAt: $detectedAt, distanceMeters: $distanceMeters, method: $method)';
}
