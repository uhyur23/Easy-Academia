import 'dart:async';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/staff.dart';
import '../models/student.dart';
import '../models/activity.dart';
import '../models/notification.dart';
import '../models/payment.dart';
import '../models/grade_record.dart';
import '../models/daily_attendance.dart';
import '../models/student_report_data.dart';
import '../models/subject.dart';
import '../utils/position_calculator.dart';

class SchoolDataService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<Staff> _staff = [];
  List<Student> _students = [];
  List<Activity> _activities = [];
  List<AppNotification> _notifications = [];
  List<Payment> _payments = [];
  List<GradeRecord> _grades = [];
  List<DailyAttendance> _attendanceRecords = [];
  List<Subject> _subjects = [];
  final List<StreamSubscription> _subscriptions = [];
  String? _currentSchoolId;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;
  String? get currentSchoolId => _currentSchoolId;

  SchoolDataService() {
    // We don't call _init here anymore because we need a schoolId
  }

  void startListening(String schoolId) {
    if (_currentSchoolId == schoolId) return;
    _currentSchoolId = schoolId;
    debugPrint('SchoolDataService: Starting listeners for school: $schoolId');
    _clearSubscriptions();

    // Staff Listener
    _subscriptions.add(
      _firestore
          .collection('staff')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            _staff = snapshot.docs
                .map((doc) => Staff.fromMap(doc.data()))
                .toList();
            _isInitialized = true;
            notifyListeners();
          }, onError: (e) => debugPrint('Staff listen error: $e')),
    );

    // Students Listener
    _subscriptions.add(
      _firestore
          .collection('students')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            _students = snapshot.docs
                .map((doc) => Student.fromMap(doc.data()))
                .toList();
            notifyListeners();
          }, onError: (e) => debugPrint('Students listen error: $e')),
    );

    // Activities Listener
    _subscriptions.add(
      _firestore
          .collection('activities')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            _activities = snapshot.docs
                .map((doc) => Activity.fromMap(doc.data()))
                .toList();
            notifyListeners();
          }, onError: (e) => debugPrint('Activities listen error: $e')),
    );

    // Notifications Listener
    _subscriptions.add(
      _firestore
          .collection('notifications')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            final docs = snapshot.docs
                .map((doc) => AppNotification.fromMap(doc.data()))
                .toList();
            // Sort client-side to avoid composite index requirement
            docs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
            _notifications = docs;
            notifyListeners();
          }, onError: (e) => debugPrint('Notifications listen error: $e')),
    );

    // Payments Listener
    _subscriptions.add(
      _firestore
          .collection('payments')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            _payments = snapshot.docs
                .map((doc) => Payment.fromMap(doc.data()))
                .toList();
            notifyListeners();
          }, onError: (e) => debugPrint('Payments listen error: $e')),
    );

    // Grades Listener
    _subscriptions.add(
      _firestore
          .collection('grades')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            _grades = snapshot.docs
                .map((doc) => GradeRecord.fromMap(doc.data()))
                .toList();
            notifyListeners();
          }, onError: (e) => debugPrint('Grades listen error: $e')),
    );

    // Attendance Listener
    _subscriptions.add(
      _firestore
          .collection('attendance')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            _attendanceRecords = snapshot.docs
                .map((doc) => DailyAttendance.fromMap(doc.data()))
                .toList();
            notifyListeners();
          }, onError: (e) => debugPrint('Attendance listen error: $e')),
    );

    // Subjects Listener
    _subscriptions.add(
      _firestore
          .collection('subjects')
          .where('schoolId', isEqualTo: schoolId)
          .snapshots()
          .listen((snapshot) {
            _subjects = snapshot.docs
                .map((doc) => Subject.fromMap(doc.data()))
                .toList();
            notifyListeners();
          }, onError: (e) => debugPrint('Subjects listen error: $e')),
    );
  }

  void _clearSubscriptions() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void clearData() {
    _currentSchoolId = null;
    _clearSubscriptions();
    _staff = [];
    _students = [];
    _activities = [];
    _notifications = [];
    _payments = [];
    _grades = [];
    _attendanceRecords = [];
    _subjects = [];
    _isInitialized = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _clearSubscriptions();
    super.dispose();
  }

  // Gated accessors
  List<Staff> getStaffForSchool(String schoolId) {
    return _staff
        .where((s) => s.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  List<Student> getStudentsForSchool(String schoolId) {
    return _students
        .where((s) => s.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  List<Student> getLinkedStudents(List<String> studentIds) {
    return _students.where((s) => studentIds.contains(s.id)).toList();
  }

  List<Activity> getActivitiesForSchool(String schoolId) {
    return _activities
        .where((a) => a.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  List<Activity> getActivitiesForStaff(String schoolId, String? staffId) {
    return _activities
        .where(
          (a) =>
              a.schoolId.toUpperCase() == schoolId.toUpperCase() &&
              (a.staffId == null || a.staffId == staffId),
        )
        .toList();
  }

  List<AppNotification> getNotificationsForSchool(String schoolId) {
    return _notifications
        .where((n) => n.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  List<AppNotification> getAnnouncementsForSchool(String schoolId) {
    // Only show manual announcements, urgent updates, events, or holidays.
    // Exclude technical logs like 'staff', 'student', 'activity'.
    const announcementTypes = ['announcement', 'urgent', 'event', 'holiday'];
    return _notifications
        .where(
          (n) =>
              n.schoolId.toUpperCase() == schoolId.toUpperCase() &&
              announcementTypes.contains(n.type.toLowerCase()),
        )
        .toList();
  }

  List<Payment> getPaymentsForSchool(String schoolId) {
    return _payments
        .where((p) => p.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  List<GradeRecord> getGradesForSchool(String schoolId) {
    return _grades
        .where((g) => g.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  List<DailyAttendance> getAttendanceForSchool(String schoolId) {
    return _attendanceRecords
        .where((a) => a.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  List<Subject> getSubjectsForSchool(String schoolId) {
    return _subjects
        .where((s) => s.schoolId.toUpperCase() == schoolId.toUpperCase())
        .toList();
  }

  DailyAttendance? getAttendanceRecord(
    String dateKey,
    String grade, [
    String? arm,
  ]) {
    // dateKey format: YYYY-MM-DD
    try {
      return _attendanceRecords.firstWhere(
        (a) =>
            a.id.startsWith(dateKey) &&
            a.grade == grade &&
            (arm == null || a.arm == arm),
      );
    } catch (_) {
      return null;
    }
  }

  double calculateMonthlyRevenue(String schoolId) {
    final now = DateTime.now();
    return getPaymentsForSchool(schoolId)
        .where(
          (p) => p.timestamp.month == now.month && p.timestamp.year == now.year,
        )
        .fold(0.0, (sum, p) => sum + p.amount);
  }

  // Activity Logger
  Future<void> logActivity({
    required String message,
    required String type,
    required String schoolId,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = AppNotification(
      id: id,
      message: message,
      type: type,
      timestamp: DateTime.now(),
      schoolId: schoolId,
    );
    await _firestore
        .collection('notifications')
        .doc(id)
        .set(notification.toMap());
  }

  Future<void> addAnnouncement({
    required String message,
    required String type,
    required String schoolId,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final notification = AppNotification(
      id: id,
      message: message,
      type: type, // announcement, urgent, event, holiday
      timestamp: DateTime.now(),
      schoolId: schoolId,
    );
    await _firestore
        .collection('notifications')
        .doc(id)
        .set(notification.toMap());
  }

  Future<void> addStaff(Staff staff) async {
    await _firestore.collection('staff').doc(staff.id).set(staff.toMap());
    await logActivity(
      message: 'New Staff Onboarded: ${staff.name}',
      type: 'staff',
      schoolId: staff.schoolId,
    );
  }

  Future<void> removeStaff(String id) async {
    final staffMember = _staff.firstWhere((s) => s.id == id);
    await _firestore.collection('staff').doc(id).delete();
    await logActivity(
      message: 'Staff Member Removed: ${staffMember.name}',
      type: 'staff',
      schoolId: staffMember.schoolId,
    );
  }

  Future<void> addSubject(Subject subject) async {
    await _firestore
        .collection('subjects')
        .doc(subject.id)
        .set(subject.toMap());
    await logActivity(
      message: 'New Subject Added: ${subject.name}',
      type: 'subject',
      schoolId: subject.schoolId,
    );
  }

  Future<void> removeSubject(String id) async {
    final subject = _subjects.firstWhere((s) => s.id == id);
    await _firestore.collection('subjects').doc(id).delete();
    await logActivity(
      message: 'Subject Removed: ${subject.name}',
      type: 'subject',
      schoolId: subject.schoolId,
    );
  }

  Future<void> updateStudentImage(String studentId, String base64Image) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'imageUrl': base64Image,
      });
      debugPrint('Updated student $studentId image');
    } catch (e) {
      debugPrint('Error updating student image: $e');
    }
  }

  Future<void> updateStudentActivities(
    String studentId,
    List<String> activities,
  ) async {
    try {
      await _firestore.collection('students').doc(studentId).update({
        'activities': activities,
      });
      debugPrint('Updated activities for student $studentId');
    } catch (e) {
      debugPrint('Error updating student activities: $e');
    }
  }

  Future<void> addStudent({
    required String name,
    required String grade,
    required String section,
    required String arm,
    required String schoolId,
    String? imageUrl,
  }) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final linkCode = generateLinkCode();

    final student = Student(
      id: id,
      name: name,
      grade: grade,
      section: section,
      arm: arm,
      imageUrl: imageUrl,
      performance: 0.0,
      activities: [],
      schoolId: schoolId,
      linkCode: linkCode,
    );

    await _firestore.collection('students').doc(id).set(student.toMap());
    await logActivity(
      message: 'New Student Registered: $name ($section - $grade$arm)',
      type: 'student',
      schoolId: schoolId,
    );
  }

  Future<void> removeStudent(String id) async {
    final student = _students.firstWhere((s) => s.id == id);
    await _firestore.collection('students').doc(id).delete();
    await logActivity(
      message: 'Student Removed: ${student.name} (${student.grade})',
      type: 'student',
      schoolId: student.schoolId,
    );
  }

  Future<void> addPayment(Payment payment) async {
    await _firestore
        .collection('payments')
        .doc(payment.id)
        .set(payment.toMap());
  }

  Future<void> addGradeRecord(GradeRecord grade) async {
    try {
      await _firestore.collection('grades').doc(grade.id).set(grade.toMap());

      // Update individual student performance (cumulative average)
      final studentGrades = _grades
          .where((g) => g.studentId == grade.studentId)
          .toList();
      if (studentGrades.isNotEmpty) {
        final totalAvg =
            studentGrades.fold(0.0, (sum, g) => sum + g.totalScore) /
            (studentGrades.length * 100);
        await updateStudentPerformance(grade.studentId, totalAvg);
      }
    } catch (e) {
      debugPrint('Error in addGradeRecord: $e');
      rethrow;
    }
  }

  Future<void> updateStudentPerformance(String id, double performance) async {
    await _firestore.collection('students').doc(id).update({
      'performance': performance,
    });
  }

  Future<void> updateStudentAttendance(String id, bool isPresent) async {
    await _firestore.collection('students').doc(id).update({
      'isPresent': isPresent,
    });
  }

  Future<void> addActivity(Activity activity) async {
    await _firestore
        .collection('activities')
        .doc(activity.id)
        .set(activity.toMap());
  }

  Future<void> updateActivityStatus(String id, ActivityStatus status) async {
    await _firestore.collection('activities').doc(id).update({
      'status': status.index,
    });
  }

  Future<void> deleteActivity(String id) async {
    await _firestore.collection('activities').doc(id).delete();
  }

  Future<void> submitAttendance(DailyAttendance record) async {
    await _firestore
        .collection('attendance')
        .doc(record.id)
        .set(record.toMap());
  }

  Student? findStudentByLinkCode(String code) {
    return _students.fold<Student?>(
      null,
      (prev, s) => s.linkCode == code ? s : prev,
    );
  }

  String generateLinkCode() {
    final random = Random();
    return List.generate(6, (_) => random.nextInt(10)).join();
  }

  PositionResult getSubjectPosition({
    required String studentId,
    required String subject,
    required String grade,
    String? arm,
    required String term,
    required String session,
  }) {
    return PositionCalculator.calculateSubjectPosition(
      studentId: studentId,
      subject: subject,
      grade: grade,
      arm: arm,
      term: term,
      session: session,
      allGrades: _grades,
      allStudents: _students,
    );
  }

  PositionResult getOverallPosition({
    required String studentId,
    required String grade,
    String? arm,
    required String term,
    required String session,
  }) {
    return PositionCalculator.calculateOverallPosition(
      studentId: studentId,
      grade: grade,
      arm: arm,
      term: term,
      session: session,
      allGrades: _grades,
      allStudents: _students,
    );
  }

  List<StudentReportData> getClassPerformanceReport({
    required String grade,
    String? arm,
    required String term,
    required String session,
  }) {
    final classStudents = _students
        .where((s) => s.grade == grade && (arm == null || s.arm == arm))
        .toList();
    final reports = <StudentReportData>[];

    for (final student in classStudents) {
      final studentGrades = _grades
          .where(
            (g) =>
                g.studentId == student.id &&
                g.classLevel.trim() == grade.trim() &&
                (arm == null || g.arm?.trim() == arm.trim()) &&
                g.term.trim() == term.trim() &&
                g.session.trim() == session.trim(),
          )
          .toList();
      // ...
      if (studentGrades.isEmpty) {
        continue;
      }

      final overallPos = getOverallPosition(
        studentId: student.id,
        grade: grade,
        arm: student.arm,
        term: term,
        session: session,
      );

      // Calculate subject positions
      final subjectPositions = <String, PositionResult>{};
      for (final g in studentGrades) {
        subjectPositions[g.subject] = getSubjectPosition(
          studentId: student.id,
          subject: g.subject,
          grade: grade,
          arm: student.arm,
          term: term,
          session: session,
        );
      }

      final totalScore = studentGrades.fold(
        0.0,
        (sum, g) => sum + g.totalScore,
      );
      final avgScore = totalScore / studentGrades.length;

      // Calculate attendance
      int present = 0;
      int totalDays = 0;
      for (final record in _attendanceRecords) {
        if (record.grade == grade && (arm == null || record.arm == arm)) {
          totalDays++;
          if (record.presentStudentIds.contains(student.id)) {
            present++;
          }
        }
      }

      reports.add(
        StudentReportData(
          studentId: student.id,
          studentName: student.name,
          studentImageUrl: student.imageUrl,
          grade: grade,
          arm: student.arm,
          section: student.section,
          term: term,
          session: session,
          individualGrades: studentGrades,
          overallPosition: overallPos,
          subjectPositions: subjectPositions,
          averageScore: avgScore,
          attendancePresent: present,
          attendanceTotal: totalDays,
        ),
      );
    }

    return reports;
  }
}
