import '../models/grade_record.dart';
import '../utils/position_calculator.dart';

class StudentReportData {
  final String studentId;
  final String studentName;
  final String? studentImageUrl;
  final String grade;
  final String arm;
  final String section;
  final String term;
  final String session;
  final List<GradeRecord> individualGrades;
  final PositionResult overallPosition;
  final Map<String, PositionResult> subjectPositions;
  final double averageScore;
  final int attendancePresent;
  final int attendanceTotal;

  StudentReportData({
    required this.studentId,
    required this.studentName,
    this.studentImageUrl,
    required this.grade,
    required this.arm,
    required this.section,
    required this.term,
    required this.session,
    required this.individualGrades,
    required this.overallPosition,
    required this.subjectPositions,
    required this.averageScore,
    required this.attendancePresent,
    required this.attendanceTotal,
  });
}
