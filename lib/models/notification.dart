import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String message;
  final String type; // 'staff', 'student', 'activity', 'system'
  final DateTime timestamp;
  final String schoolId;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    required this.timestamp,
    required this.schoolId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'message': message,
      'type': type,
      'timestamp': Timestamp.fromDate(timestamp),
      'schoolId': schoolId,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'system',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      schoolId: map['schoolId'] ?? '',
    );
  }
}
