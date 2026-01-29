import 'package:hive/hive.dart';

part 'daily_attendance.g.dart';

@HiveType(typeId: 5)
class DailyAttendance {
  @HiveField(0)
  final String id; // Format: YYYY-MM-DD_schoolId_grade
  @HiveField(1)
  final String schoolId;
  @HiveField(2)
  final String grade;
  @HiveField(3)
  final DateTime date;
  @HiveField(4)
  final List<String> presentStudentIds;
  @HiveField(5)
  final DateTime timestamp;
  @HiveField(6)
  final String submittedBy;

  @HiveField(7)
  final String? arm;

  DailyAttendance({
    required this.id,
    required this.schoolId,
    required this.grade,
    this.arm,
    required this.date,
    required this.presentStudentIds,
    required this.timestamp,
    required this.submittedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'schoolId': schoolId,
      'grade': grade,
      'arm': arm,
      'date': date.toIso8601String(),
      'presentStudentIds': presentStudentIds,
      'timestamp': timestamp.toIso8601String(),
      'submittedBy': submittedBy,
    };
  }

  factory DailyAttendance.fromMap(Map<String, dynamic> map) {
    return DailyAttendance(
      id: map['id'] ?? '',
      schoolId: map['schoolId'] ?? '',
      grade: map['grade'] ?? '',
      arm: map['arm'],
      date: map['date'] != null ? DateTime.parse(map['date']) : DateTime.now(),
      presentStudentIds: List<String>.from(map['presentStudentIds'] ?? []),
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      submittedBy: map['submittedBy'] ?? '',
    );
  }
}
