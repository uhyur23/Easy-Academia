import '../models/grade_record.dart';
import '../models/student.dart';

class PositionResult {
  final int position;
  final int totalStudents;

  PositionResult(this.position, this.totalStudents);

  String get ordinal {
    if (position == 1) return '1st';
    if (position == 2) return '2nd';
    if (position == 3) return '3rd';
    return '${position}th';
  }

  String get displayText => '$ordinal out of $totalStudents students';
}

class PositionCalculator {
  /// Calculate student's position in a specific subject
  static PositionResult calculateSubjectPosition({
    required String studentId,
    required String subject,
    required String grade,
    String? arm,
    required String term,
    required String session,
    required List<GradeRecord> allGrades,
    required List<Student> allStudents,
  }) {
    // Calculate total students in this class/grade/arm
    final totalInClass = allStudents.where((s) {
      final matchesGrade = s.grade == grade;
      final matchesArm = arm == null || s.arm == arm;
      return matchesGrade && matchesArm;
    }).length;
    final displayTotal = totalInClass > 0 ? totalInClass : 1;

    // Filter grades for this specific subject, grade, arm, term, and session
    final subjectGrades = allGrades
        .where(
          (g) =>
              g.subject == subject &&
              g.classLevel == grade &&
              (arm == null || g.arm == arm) &&
              g.term == term &&
              g.session == session,
        )
        .toList();
    // ... (rest of the logic remains same, just filtering is updated)
    if (subjectGrades.isEmpty) {
      return PositionResult(1, displayTotal);
    }

    final studentScores = <String, double>{};
    for (var gradeRecord in subjectGrades) {
      if (!studentScores.containsKey(gradeRecord.studentId) ||
          studentScores[gradeRecord.studentId]! < gradeRecord.totalScore) {
        studentScores[gradeRecord.studentId] = gradeRecord.totalScore;
      }
    }

    final targetScore = studentScores[studentId];
    if (targetScore == null) {
      return PositionResult(1, displayTotal);
    }

    final sortedScores = studentScores.values.toList()
      ..sort((a, b) => b.compareTo(a));

    int position = 1;
    for (var score in sortedScores) {
      if (score > targetScore) {
        position++;
      } else {
        break;
      }
    }

    return PositionResult(position, displayTotal);
  }

  /// Calculate student's overall position across all subjects
  static PositionResult calculateOverallPosition({
    required String studentId,
    required String grade,
    String? arm,
    required String term,
    required String session,
    required List<GradeRecord> allGrades,
    required List<Student> allStudents,
  }) {
    // Calculate total students in this class/grade/arm
    final totalInClass = allStudents.where((s) {
      final matchesGrade = s.grade == grade;
      final matchesArm = arm == null || s.arm == arm;
      return matchesGrade && matchesArm;
    }).length;
    final displayTotal = totalInClass > 0 ? totalInClass : 1;

    // Get all grades for this grade, arm, term, and session
    final relevantGrades = allGrades
        .where(
          (g) =>
              g.classLevel == grade &&
              (arm == null || g.arm == arm) &&
              g.term == term &&
              g.session == session,
        )
        .toList();

    if (relevantGrades.isEmpty) {
      return PositionResult(1, displayTotal);
    }

    final studentAverages = <String, double>{};
    final studentSubjectCounts = <String, int>{};

    for (var gradeRecord in relevantGrades) {
      if (!studentAverages.containsKey(gradeRecord.studentId)) {
        studentAverages[gradeRecord.studentId] = 0;
        studentSubjectCounts[gradeRecord.studentId] = 0;
      }
      studentAverages[gradeRecord.studentId] =
          studentAverages[gradeRecord.studentId]! + gradeRecord.totalScore;
      studentSubjectCounts[gradeRecord.studentId] =
          studentSubjectCounts[gradeRecord.studentId]! + 1;
    }

    final finalAverages = <String, double>{};
    studentAverages.forEach((id, total) {
      finalAverages[id] = total / studentSubjectCounts[id]!;
    });

    final targetAverage = finalAverages[studentId];
    if (targetAverage == null) {
      return PositionResult(1, displayTotal);
    }

    final sortedAverages = finalAverages.values.toList()
      ..sort((a, b) => b.compareTo(a));

    int position = 1;
    for (var avg in sortedAverages) {
      if (avg > targetAverage) {
        position++;
      } else {
        break;
      }
    }

    return PositionResult(position, displayTotal);
  }
}
