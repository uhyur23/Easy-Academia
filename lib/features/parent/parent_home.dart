import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/app_state.dart';
import '../../core/design_system.dart';
import '../../services/school_data_service.dart';
import '../../models/student.dart';
import '../../models/grade_record.dart';
import '../shared/student_detail_screen.dart';
import 'announcement_feed.dart';

class ParentHome extends StatefulWidget {
  const ParentHome({super.key});

  @override
  State<ParentHome> createState() => _ParentHomeState();
}

class _ParentHomeState extends State<ParentHome> {
  String? _selectedStudentId;

  @override
  Widget build(BuildContext context) {
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final appState = context.watch<AppState>();
        final students = service.getLinkedStudents(appState.linkedStudentIds);

        // Ensure a student is selected if list is not empty
        if (students.isNotEmpty) {
          if (_selectedStudentId == null ||
              !students.any((s) => s.id == _selectedStudentId)) {
            _selectedStudentId = students.first.id;
          }
        }

        if (students.isEmpty) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Parent Tracker'),
              backgroundColor: Colors.transparent,
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.add_link_rounded,
                    color: AppColors.primary,
                  ),
                  onPressed: () =>
                      _showLinkStudentDialog(context, service, appState),
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded),
                  onPressed: () => _showLogoutDialog(context),
                ),
              ],
            ),
            body: _buildEmptyState(context, service, appState),
          );
        }

        final student = students.firstWhere((s) => s.id == _selectedStudentId);

        // Switch school context if needed (for parents with kids in different schools)
        if (service.currentSchoolId != student.schoolId) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            service.startListening(student.schoolId);
          });
        }

        // Fetch grades for this student
        final allGrades = service.getGradesForSchool(student.schoolId);
        final studentGrades =
            allGrades.where((g) => g.studentId == student.id).toList()
              ..sort((a, b) => b.timestamp.compareTo(a.timestamp));

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              _buildSliverAppBar(context, service, appState, students),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStudentSelector(context, student),
                      const SizedBox(height: 32),
                      _buildPerformanceChart(student, studentGrades),
                      AnnouncementFeed(schoolId: student.schoolId),
                      const SizedBox(height: 32),
                      Text(
                        'Recent Reports',
                        style: AppTypography.label.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 16),
                      _buildReportList(context, studentGrades, student),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSliverAppBar(
    BuildContext context,
    SchoolDataService service,
    AppState appState,
    List<Student> students,
  ) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.background,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          'Parent Dashboard',
          style: AppTypography.header.copyWith(fontSize: 18),
        ),
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 20, bottom: 16),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.add_link_rounded, color: AppColors.primary),
          tooltip: 'Link another child',
          onPressed: () => _showLinkStudentDialog(context, service, appState),
        ),
        IconButton(
          icon: const Icon(Icons.logout_rounded),
          onPressed: () => _showLogoutDialog(context),
        ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    SchoolDataService service,
    AppState appState,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.family_restroom_rounded,
            size: 80,
            color: Colors.white.withAlpha(20),
          ),
          const SizedBox(height: 24),
          Text('No students linked yet', style: AppTypography.header),
          const SizedBox(height: 8),
          Text(
            'Link your child\'s profile to track their progress',
            style: AppTypography.body,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => _showLinkStudentDialog(context, service, appState),
            icon: const Icon(Icons.add_link_rounded),
            label: const Text('Link My Child'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            ),
          ),
        ],
      ).animate().fadeIn(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text(
          'Logout Confirmation',
          style: AppTypography.header.copyWith(fontSize: 20),
        ),
        content: const SizedBox(
          width: 300,
          child: Text(
            'Are you sure you want to logout? You will need to sign in again to access the tracker.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<AppState>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent.withAlpha(200),
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  void _showLinkStudentDialog(
    BuildContext context,
    SchoolDataService service,
    AppState appState,
  ) {
    final codeController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Text('Link Student', style: AppTypography.label),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter the 6-digit code provided by your school.',
                style: AppTypography.body.copyWith(fontSize: 14),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: codeController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Student Link Code',
                  hintText: 'e.g. 111111',
                  hintStyle: const TextStyle(color: Colors.white24),
                  labelStyle: const TextStyle(color: Colors.white70),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                keyboardType: TextInputType.number,
                maxLength: 6,
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
            onPressed: () {
              final student = service.findStudentByLinkCode(
                codeController.text,
              );
              if (student != null) {
                appState.linkStudent(student.id);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Succesfully linked with ${student.name}'),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Invalid link code. Please try again.'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentSelector(BuildContext context, Student student) {
    Uint8List? imageBytes;
    if (student.imageUrl != null && student.imageUrl!.isNotEmpty) {
      try {
        final cleanString = student.imageUrl!.contains(',')
            ? student.imageUrl!.split(',').last
            : student.imageUrl!;
        imageBytes = base64Decode(cleanString);
      } catch (e) {
        debugPrint('Error decoding image for ${student.name}: $e');
      }
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentDetailScreen(student: student),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Row(
        children: [
          Hero(
            tag: 'student-avatar-${student.id}',
            child: CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.primary.withAlpha(50),
              backgroundImage: imageBytes != null
                  ? MemoryImage(imageBytes)
                  : null,
              child: imageBytes == null
                  ? Text(student.name.isNotEmpty ? student.name[0] : '?')
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                student.name,
                style: AppTypography.header.copyWith(fontSize: 20),
              ),
              Text(
                '${student.grade} - ${student.isPresent ? "Online/Present" : "Offline/Absent"}',
                style: AppTypography.body.copyWith(
                  color: student.isPresent
                      ? Colors.greenAccent
                      : Colors.redAccent,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(
              Icons.swap_horiz_rounded,
              color: AppColors.primary,
            ),
            onPressed: () => _showStudentSwitcher(context),
          ),
        ],
      ).animate().fadeIn().slideX(begin: 0.1),
    );
  }

  void _showStudentSwitcher(BuildContext context) {
    final service = context.read<SchoolDataService>();
    final appState = context.read<AppState>();
    final linkedStudents = service.getLinkedStudents(appState.linkedStudentIds);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => GlassContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: 24,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switch Child Profile',
              style: AppTypography.header.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 16),
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: linkedStudents.length,
                itemBuilder: (context, index) {
                  final s = linkedStudents[index];
                  final isSelected = s.id == _selectedStudentId;

                  Uint8List? imageBytes;
                  if (s.imageUrl != null && s.imageUrl!.isNotEmpty) {
                    try {
                      final cleanString = s.imageUrl!.contains(',')
                          ? s.imageUrl!.split(',').last
                          : s.imageUrl!;
                      imageBytes = base64Decode(cleanString);
                    } catch (e) {
                      debugPrint('Error decoding image: $e');
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: InkWell(
                      onTap: () {
                        setState(() => _selectedStudentId = s.id);
                        Navigator.pop(context);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withAlpha(30)
                              : Colors.white.withAlpha(10),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : Colors.white12,
                          ),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: AppColors.primary.withAlpha(50),
                              backgroundImage: imageBytes != null
                                  ? MemoryImage(imageBytes)
                                  : null,
                              child: imageBytes == null
                                  ? Text(s.name.isNotEmpty ? s.name[0] : '?')
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(s.name, style: AppTypography.label),
                                  Text(
                                    s.grade,
                                    style: AppTypography.body.copyWith(
                                      fontSize: 12,
                                      color: Colors.white60,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.primary,
                              ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _showLinkStudentDialog(context, service, appState);
              },
              icon: const Icon(Icons.add_link_rounded),
              label: const Text('Link Another Child'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(10),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceChart(Student student, List<GradeRecord> grades) {
    // Basic calculation: Get average of last 5 grades if available
    double averageScore = 0.0;
    if (grades.isNotEmpty) {
      averageScore =
          grades.fold(0.0, (sum, g) => sum + g.totalScore) / grades.length;
    } else {
      averageScore =
          student.performance * 100; // Use stored performance if no grades
    }

    return GlassContainer(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Academic Growth', style: AppTypography.label),
              Text(
                '${averageScore.toInt()}%',
                style: AppTypography.header.copyWith(
                  color: AppColors.primary,
                  fontSize: 24,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (grades.isEmpty)
            Center(
              child: Text(
                "No grade data available yet",
                style: AppTypography.body,
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: grades.take(7).map((g) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: _buildBar(
                      g.subject.substring(0, 3),
                      g.totalScore / 100,
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).scale();
  }

  Widget _buildBar(String label, double scale) {
    return Column(
      children: [
        Container(
          width: 30,
          height: 120 * scale,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(6),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withAlpha(80),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: AppTypography.body.copyWith(fontSize: 10)),
      ],
    );
  }

  Widget _buildReportList(
    BuildContext context,
    List<GradeRecord> grades,
    Student selectedStudent,
  ) {
    if (grades.isEmpty) {
      return Center(
        child: Text(
          'No recent grades recorded.',
          style: AppTypography.body.copyWith(color: Colors.white38),
        ),
      );
    }

    final service = context.read<SchoolDataService>();

    return Column(
      children: grades.take(5).map((grade) {
        // Calculate position for the badge
        final pos = service.getSubjectPosition(
          studentId: grade.studentId,
          subject: grade.subject,
          grade: selectedStudent.grade,
          arm: selectedStudent.arm,
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
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withAlpha(20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.insert_drive_file_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${grade.subject} - ${grade.term}',
                        style: AppTypography.label,
                      ),
                      Row(
                        children: [
                          Text(
                            'Score: ${grade.totalScore.toInt()} (${grade.grade})',
                            style: AppTypography.body.copyWith(fontSize: 12),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              pos.ordinal,
                              style: AppTypography.label.copyWith(
                                fontSize: 10,
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => _showGradeDetails(context, grade),
                  child: const Text('View'),
                ),
              ],
            ),
          ).animate().fadeIn(),
        );
      }).toList(),
    );
  }

  void _showGradeDetails(BuildContext context, GradeRecord grade) {
    // Get service and student info to calculate positions
    final service = context.read<SchoolDataService>();
    final appState = context.read<AppState>();
    final student = service
        .getStudentsForSchool(appState.schoolId ?? '')
        .firstWhere((s) => s.id == grade.studentId);

    // Calculate subject position
    final subjectPosition = service.getSubjectPosition(
      studentId: grade.studentId,
      subject: grade.subject,
      grade: student.grade,
      arm: student.arm,
      term: grade.term,
      session: grade.session,
    );

    // Calculate overall position
    final overallPosition = service.getOverallPosition(
      studentId: grade.studentId,
      grade: student.grade,
      arm: student.arm,
      term: grade.term,
      session: grade.session,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: Column(
          children: [
            Text(
              grade.subject,
              style: AppTypography.header.copyWith(fontSize: 20),
            ),
            const SizedBox(height: 4),
            Text(
              '${grade.term} - ${grade.session}',
              style: AppTypography.body.copyWith(fontSize: 14),
            ),
          ],
        ),
        content: SizedBox(
          width: 400,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildScoreRow('Continuous Assessment', grade.caScore),
                const SizedBox(height: 12),
                _buildScoreRow('Examination', grade.examScore),
                const Divider(color: Colors.white24, height: 32),
                _buildScoreRow('Total Score', grade.totalScore, isTotal: true),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: _getGradeColor(grade.grade).withAlpha(30),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getGradeColor(grade.grade).withAlpha(50),
                    ),
                  ),
                  child: Text(
                    'Grade: ${grade.grade} (${GradingUtils.getGradeRemarks(grade.grade)})',
                    style: AppTypography.label.copyWith(
                      color: _getGradeColor(grade.grade),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                // Subject Position
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withAlpha(50)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: AppColors.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Subject Position',
                              style: AppTypography.body.copyWith(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subjectPosition.displayText,
                        style: AppTypography.label.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                // Overall Position
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.accent.withAlpha(50)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.stars,
                            color: AppColors.accent,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Overall Position',
                              style: AppTypography.body.copyWith(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        overallPosition.displayText,
                        style: AppTypography.label.copyWith(
                          color: AppColors.accent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: isTotal
              ? AppTypography.label
              : AppTypography.body.copyWith(color: Colors.white70),
        ),
        Text(
          score.toStringAsFixed(1),
          style: (isTotal ? AppTypography.header : AppTypography.body).copyWith(
            color: isTotal ? AppColors.primary : Colors.white,
          ),
        ),
      ],
    );
  }

  Color _getGradeColor(String grade) {
    if (grade == 'A' || grade == 'B') return Colors.greenAccent;
    if (grade == 'C' || grade == 'D') return Colors.orangeAccent;
    return Colors.redAccent;
  }
}
