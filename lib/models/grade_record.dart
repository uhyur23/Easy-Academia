import 'package:hive/hive.dart';

part 'grade_record.g.dart';

@HiveType(typeId: 4)
class GradeRecord {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String studentId;
  @HiveField(2)
  final String schoolId;
  @HiveField(3)
  final String subject;
  @HiveField(4)
  final double caScore; // Continuous Assessment (e.g., 30)
  @HiveField(5)
  final double examScore; // Examination (e.g., 70)
  @HiveField(6)
  final double totalScore; // caScore + examScore
  @HiveField(7)
  final String grade; // A, B, C, D, E, F
  @HiveField(8)
  final DateTime timestamp;
  @HiveField(9)
  final String term; // 1st, 2nd, 3rd
  @HiveField(10)
  final String session; // e.g., 2023/2024
  @HiveField(11)
  final String classLevel; // e.g., Basic 1, SS 1
  @HiveField(12)
  final String? arm;

  GradeRecord({
    required this.id,
    required this.studentId,
    required this.schoolId,
    required this.subject,
    required this.caScore,
    required this.examScore,
    required this.totalScore,
    required this.grade,
    required this.timestamp,
    required this.term,
    required this.session,
    required this.classLevel,
    this.arm,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'studentId': studentId,
      'schoolId': schoolId,
      'subject': subject,
      'caScore': caScore,
      'examScore': examScore,
      'totalScore': totalScore,
      'grade': grade,
      'timestamp': timestamp.toIso8601String(),
      'term': term,
      'session': session,
      'classLevel': classLevel,
      'arm': arm,
    };
  }

  factory GradeRecord.fromMap(Map<String, dynamic> map) {
    return GradeRecord(
      id: map['id'] ?? '',
      studentId: map['studentId'] ?? '',
      schoolId: map['schoolId'] ?? '',
      subject: map['subject'] ?? '',
      caScore: (map['caScore'] ?? 0).toDouble(),
      examScore: (map['examScore'] ?? 0).toDouble(),
      totalScore: (map['totalScore'] ?? 0).toDouble(),
      grade: map['grade'] ?? 'F',
      timestamp: map['timestamp'] != null
          ? DateTime.parse(map['timestamp'])
          : DateTime.now(),
      term: map['term'] ?? '1st Term',
      session: map['session'] ?? '2023/2024',
      classLevel: map['classLevel'] ?? '',
      arm: map['arm'],
    );
  }
}

class GradingUtils {
  static String getLetterGrade(double total) {
    if (total >= 70) return 'A';
    if (total >= 60) return 'B';
    if (total >= 50) return 'C';
    if (total >= 45) return 'D';
    if (total >= 40) return 'E';
    return 'F';
  }

  static String getGradeRemarks(String grade) {
    switch (grade) {
      case 'A':
        return 'Excellent';
      case 'B':
        return 'Very Good';
      case 'C':
        return 'Good';
      case 'D':
        return 'Pass';
      case 'E':
        return 'Fair';
      default:
        return 'Fail';
    }
  }
}
