import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'staff_attendance.g.dart';

@HiveType(typeId: 13)
class StaffAttendance extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String staffId;

  @HiveField(2)
  final String staffName;

  @HiveField(3)
  final String schoolId;

  @HiveField(4)
  final DateTime timestamp;

  StaffAttendance({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.schoolId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'staffId': staffId,
      'staffName': staffName,
      'schoolId': schoolId,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }

  factory StaffAttendance.fromMap(Map<String, dynamic> map) {
    return StaffAttendance(
      id: map['id'] ?? '',
      staffId: map['staffId'] ?? '',
      staffName: map['staffName'] ?? '',
      schoolId: map['schoolId'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
