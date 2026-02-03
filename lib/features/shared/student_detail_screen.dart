import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/design_system.dart';
import '../../models/student.dart';
import '../../services/school_data_service.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import '../../utils/report_sheet_generator.dart';
import '../../models/student_report_data.dart';
import '../../utils/position_calculator.dart';
import '../../core/app_state.dart';

class StudentDetailScreen extends StatefulWidget {
  final Student student;
  final bool canEdit;

  const StudentDetailScreen({
    super.key,
    required this.student,
    this.canEdit = false,
  });

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  late Student _currentStudent;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _currentStudent = widget.student;
  }

  Future<void> _handleChangePhoto() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );

    if (image == null) return;

    setState(() => _isUploading = true);
    final bytes = await image.readAsBytes();
    final base64 = 'data:image/jpeg;base64,${base64Encode(bytes)}';

    try {
      await context.read<SchoolDataService>().updateStudentImage(
        _currentStudent.id,
        base64,
      );
      setState(() {
        _currentStudent = Student(
          id: _currentStudent.id,
          name: _currentStudent.name,
          grade: _currentStudent.grade,
          section: _currentStudent.section,
          arm: _currentStudent.arm,
          performance: _currentStudent.performance,
          activities: _currentStudent.activities,
          schoolId: _currentStudent.schoolId,
          linkCode: _currentStudent.linkCode,
          imageUrl: base64,
          isPresent: _currentStudent.isPresent,
        );
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating photo: $e')));
      }
    }
  }

  Widget _renderAvatar(String? imageUrl) {
    if (imageUrl == null) {
      return const Icon(Icons.person, size: 60, color: AppColors.secondary);
    }

    if (imageUrl.startsWith('data:image')) {
      try {
        final base64String = imageUrl.split(',').last;
        return Image.memory(base64Decode(base64String), fit: BoxFit.cover);
      } catch (e) {
        return const Icon(
          Icons.broken_image,
          size: 60,
          color: AppColors.primary,
        );
      }
    }

    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) =>
          const Icon(Icons.person, size: 60, color: AppColors.primary),
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text(
          'Delete Student Record',
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          'Are you sure you want to delete ${_currentStudent.name}\'s record? This will remove all their data from the school directory. This action cannot be undone.',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              try {
                await context.read<SchoolDataService>().removeStudent(
                  _currentStudent.id,
                );
                if (mounted) {
                  Navigator.pop(context); // Close detail screen
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Student record removed')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error removing student: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete Student'),
          ),
        ],
      ),
    );
  }

  Future<void> _showReportOptions(BuildContext context) async {
    String selectedTerm = '1st Term';
    String selectedSession = '2025/2026';
    final List<String> terms = ['1st Term', '2nd Term', '3rd Term'];
    final List<String> sessions = ['2024/2025', '2025/2026', '2026/2027'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            'Generate Report Card',
            style: AppTypography.header.copyWith(fontSize: 20),
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDialogDropdown(
                  label: 'Select Term',
                  value: selectedTerm,
                  items: terms,
                  onChanged: (val) => setDialogState(() => selectedTerm = val!),
                ),
                const SizedBox(height: 16),
                _buildDialogDropdown(
                  label: 'Select Session',
                  value: selectedSession,
                  items: sessions,
                  onChanged: (val) =>
                      setDialogState(() => selectedSession = val!),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _generateSingleReport(
                  selectedTerm,
                  selectedSession,
                  isPrint: false,
                );
              },
              icon: const Icon(Icons.download_rounded),
              label: const Text('Save PDF'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: BorderSide(color: Colors.white.withAlpha(50)),
              ),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await _generateSingleReport(
                  selectedTerm,
                  selectedSession,
                  isPrint: true,
                );
              },
              icon: const Icon(Icons.print_rounded),
              label: const Text('Print'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDialogDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white60),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(10),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              items: items
                  .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                  .toList(),
              onChanged: onChanged,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: Colors.white),
              isExpanded: true,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateSingleReport(
    String term,
    String session, {
    required bool isPrint,
  }) async {
    final service = context.read<SchoolDataService>();
    final appState = context.read<AppState>();

    // Prepare report data
    final studentGrades = service
        .getGradesForSchool(_currentStudent.schoolId)
        .where(
          (g) =>
              g.studentId == _currentStudent.id &&
              g.classLevel == _currentStudent.grade &&
              g.term == term &&
              g.session == session,
        )
        .toList();

    if (studentGrades.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No grades found for the selected term/session.'),
          ),
        );
      }
      return;
    }

    final pos = service.getOverallPosition(
      studentId: _currentStudent.id,
      grade: _currentStudent.grade,
      arm: _currentStudent.arm,
      term: term,
      session: session,
    );

    // Calculate subject positions
    final subjectPositions = <String, PositionResult>{};
    for (final g in studentGrades) {
      subjectPositions[g.subject] = service.getSubjectPosition(
        studentId: _currentStudent.id,
        subject: g.subject,
        grade: _currentStudent.grade,
        arm: _currentStudent.arm,
        term: term,
        session: session,
      );
    }

    final totalScore = studentGrades.fold(0.0, (sum, g) => sum + g.totalScore);
    final avgScore = totalScore / studentGrades.length;

    // Calculate attendance
    int present = 0;
    int totalDays = 0;
    for (final record in service.getAttendanceForSchool(
      _currentStudent.schoolId,
    )) {
      if (record.grade == _currentStudent.grade &&
          record.arm == _currentStudent.arm) {
        totalDays++;
        if (record.presentStudentIds.contains(_currentStudent.id)) {
          present++;
        }
      }
    }

    final reportData = StudentReportData(
      studentId: _currentStudent.id,
      studentName: _currentStudent.name,
      studentImageUrl: _currentStudent.imageUrl,
      grade: _currentStudent.grade,
      arm: _currentStudent.arm,
      section: _currentStudent.section,
      term: term,
      session: session,
      individualGrades: studentGrades,
      overallPosition: pos,
      subjectPositions: subjectPositions,
      averageScore: avgScore,
      attendancePresent: present,
      attendanceTotal: totalDays,
    );

    try {
      final pdfBytes = await ReportSheetGenerator.generateClassReports(
        reports: [reportData],
        schoolLogoBase64: appState.badgeUrl,
        schoolName: appState.schoolName ?? 'Easy Academia',
        showPositions: service.schoolConfig?.showPositionOnReport ?? true,
      );

      final fileName = 'Report_${_currentStudent.name}_$term';
      if (isPrint) {
        await Printing.layoutPdf(
          onLayout: (PdfPageFormat format) async => pdfBytes,
          name: fileName,
        );
      } else {
        await Printing.sharePdf(bytes: pdfBytes, filename: '$fileName.pdf');
      }
    } catch (e) {
      debugPrint('Error printing report: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentStudent.name,
          style: AppTypography.header.copyWith(fontSize: 20),
        ),
        backgroundColor: Colors.transparent,
        actions: [
          if (widget.canEdit) ...[
            IconButton(
              icon: const Icon(Icons.print_rounded, color: AppColors.primary),
              tooltip: 'Print Report Card',
              onPressed: () => _showReportOptions(context),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
              tooltip: 'Delete Student',
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 32),
            _buildMetricsGrid(),
            const SizedBox(height: 32),
            _buildAcademicPerformanceList(),
            const SizedBox(height: 32),
            _buildAttendanceHistory(),
            const SizedBox(height: 32),
            _buildActivitiesList(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Center(
      child: Column(
        children: [
          Hero(
            tag: 'student-avatar-${_currentStudent.id}',
            child: InkWell(
              onTap: _isUploading ? null : _handleChangePhoto,
              borderRadius: BorderRadius.circular(60),
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(30),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.primary.withAlpha(50),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _isUploading
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primary,
                          ),
                        )
                      : _renderAvatar(_currentStudent.imageUrl),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentStudent.name,
            style: AppTypography.header.copyWith(fontSize: 24),
          ),
          Text(_currentStudent.grade, style: AppTypography.body),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: _currentStudent.isPresent
                  ? Colors.greenAccent.withAlpha(20)
                  : Colors.redAccent.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _currentStudent.isPresent
                    ? Colors.greenAccent.withAlpha(50)
                    : Colors.redAccent.withAlpha(50),
              ),
            ),
            child: Text(
              _currentStudent.isPresent
                  ? 'Currently Present'
                  : 'Currently Absent',
              style: TextStyle(
                color: _currentStudent.isPresent
                    ? Colors.greenAccent
                    : Colors.redAccent,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ).animate().fadeIn().scale(),
    );
  }

  Widget _buildMetricsGrid() {
    // Calculate Attendance Rate
    final attendanceRecords = context
        .watch<SchoolDataService>()
        .getAttendanceForSchool(_currentStudent.schoolId)
        .where((a) => a.grade == _currentStudent.grade)
        .toList();

    int totalDays = attendanceRecords.length;
    int daysPresent = attendanceRecords
        .where((a) => a.presentStudentIds.contains(_currentStudent.id))
        .length;

    double attendanceRate = totalDays > 0
        ? (daysPresent / totalDays) * 100
        : 100.0; // Default to 100% if no records yet

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 3,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.2,
      children: [
        _MetricBox(
          label: 'Average',
          value: '${(_currentStudent.performance * 100).toInt()}%',
          icon: Icons.auto_graph_rounded,
          color: AppColors.primary,
        ),
        _MetricBox(
          label: 'Attendance',
          value: '${attendanceRate.toInt()}%',
          icon: Icons.calendar_today_rounded,
          color: AppColors.accent,
        ),
        if (context.read<SchoolDataService>().schoolConfig?.showPositionInApp ??
            true)
          _buildOverallRankMetric(),
      ],
    );
  }

  Widget _buildOverallRankMetric() {
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        // We'll use the latest grade record's term/session or defaults
        final grades = service
            .getGradesForSchool(_currentStudent.schoolId)
            .where((g) => g.studentId == _currentStudent.id)
            .toList();

        if (grades.isEmpty) {
          return const _MetricBox(
            label: 'Rank',
            value: '-',
            icon: Icons.emoji_events_rounded,
            color: Colors.orangeAccent,
          );
        }

        final latest = grades.first;
        final rank = service.getOverallPosition(
          studentId: _currentStudent.id,
          grade: _currentStudent.grade,
          arm: _currentStudent.arm,
          term: latest.term,
          session: latest.session,
        );

        return _MetricBox(
          label: 'Class Rank',
          value: rank.ordinal,
          icon: Icons.emoji_events_rounded,
          color: Colors.orangeAccent,
        );
      },
    );
  }

  Widget _buildAttendanceHistory() {
    // Get last 7 days related to this student's grade
    final allRecords = context
        .watch<SchoolDataService>()
        .getAttendanceForSchool(_currentStudent.schoolId)
        .where((a) => a.grade == _currentStudent.grade)
        .toList();

    // Sort by date descending
    allRecords.sort((a, b) => b.date.compareTo(a.date));

    // Take last 7 records, or fewer if not available
    final recentRecords = allRecords.take(7).toList().reversed.toList();

    // If no records, just show empty state or filler
    if (recentRecords.isEmpty) {
      return GlassContainer(
        padding: const EdgeInsets.all(20),
        child: Center(
          child: Text(
            "No attendance records found.",
            style: AppTypography.body,
          ),
        ),
      );
    }

    return GlassContainer(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attendance History', style: AppTypography.label),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: recentRecords.map((record) {
              final isPresent = record.presentStudentIds.contains(
                _currentStudent.id,
              );
              // Get day string (e.g., "M", "T")
              final weekDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
              final dayLabel =
                  weekDays[record.date.weekday - 1]; // weekday is 1-7

              return Column(
                children: [
                  Container(
                    width: 12,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isPresent
                          ? Colors.greenAccent
                          : Colors.redAccent.withAlpha(50),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    dayLabel,
                    style: AppTypography.body.copyWith(fontSize: 10),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildActivitiesList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Enrolled Activities', style: AppTypography.label),
            if (widget.canEdit)
              IconButton(
                icon: const Icon(
                  Icons.edit_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
                onPressed: _showEditActivitiesDialog,
              ),
          ],
        ),
        const SizedBox(height: 16),
        if (_currentStudent.activities.isEmpty)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              "No activities enrolled.",
              style: AppTypography.body.copyWith(color: Colors.white54),
            ),
          )
        else
          ..._currentStudent.activities.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: AppColors.secondary,
                      size: 18,
                    ),
                    const SizedBox(width: 12),
                    Text(activity, style: AppTypography.body),
                  ],
                ),
              ),
            ),
          ),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  void _showEditActivitiesDialog() {
    final controller = TextEditingController();
    List<String> tempActivities = List.from(_currentStudent.activities);

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text('Manage Activities', style: AppTypography.label),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: tempActivities.map((activity) {
                    return Chip(
                      label: Text(activity),
                      backgroundColor: AppColors.primary.withAlpha(20),
                      labelStyle: const TextStyle(color: Colors.white),
                      deleteIcon: const Icon(
                        Icons.close,
                        size: 18,
                        color: Colors.white70,
                      ),
                      onDeleted: () {
                        setDialogState(() {
                          tempActivities.remove(activity);
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Add Activity',
                    hintText: 'e.g. Chess Club',
                    hintStyle: const TextStyle(color: Colors.white24),
                    labelStyle: const TextStyle(color: Colors.white70),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.add, color: AppColors.primary),
                      onPressed: () {
                        if (controller.text.isNotEmpty) {
                          setDialogState(() {
                            tempActivities.add(controller.text.trim());
                            controller.clear();
                          });
                        }
                      },
                    ),
                  ),
                  onSubmitted: (value) {
                    if (value.isNotEmpty) {
                      setDialogState(() {
                        tempActivities.add(value.trim());
                        controller.clear();
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                await context.read<SchoolDataService>().updateStudentActivities(
                  _currentStudent.id,
                  tempActivities,
                );

                setState(() {
                  _currentStudent = Student(
                    id: _currentStudent.id,
                    name: _currentStudent.name,
                    grade: _currentStudent.grade,
                    section: _currentStudent.section,
                    arm: _currentStudent.arm,
                    performance: _currentStudent.performance,
                    activities: tempActivities,
                    schoolId: _currentStudent.schoolId,
                    linkCode: _currentStudent.linkCode,
                    imageUrl: _currentStudent.imageUrl,
                    isPresent: _currentStudent.isPresent,
                  );
                });
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicPerformanceList() {
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final allGrades = service.getGradesForSchool(_currentStudent.schoolId);
        final studentGrades =
            allGrades.where((g) => g.studentId == _currentStudent.id).toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        if (studentGrades.isEmpty) {
          return GlassContainer(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Academic Performance', style: AppTypography.label),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    "No grades recorded yet.",
                    style: AppTypography.body.copyWith(color: Colors.white38),
                  ),
                ),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Academic Performance', style: AppTypography.label),
            const SizedBox(height: 16),
            ...studentGrades.map((grade) {
              final pos = service.getSubjectPosition(
                studentId: grade.studentId,
                subject: grade.subject,
                grade: _currentStudent.grade,
                arm: _currentStudent.arm,
                term: grade.term,
                session: grade.session,
              );

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: GlassContainer(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: AppColors.primary,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(grade.subject, style: AppTypography.label),
                            Text(
                              '${grade.term} • ${grade.session}',
                              style: AppTypography.body.copyWith(
                                fontSize: 11,
                                color: Colors.white38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${grade.totalScore.toInt()}%',
                                style: AppTypography.label.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(10),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  grade.grade,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white70,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (service.schoolConfig?.showPositionInApp ?? true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Rank: ${pos.ordinal}',
                                style: AppTypography.body.copyWith(
                                  fontSize: 11,
                                  color: Colors.orangeAccent,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
      },
    );
  }
}

class _MetricBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricBox({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTypography.header.copyWith(fontSize: 20, color: color),
          ),
          Text(
            label,
            style: AppTypography.body.copyWith(fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
