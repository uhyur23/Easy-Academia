import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/app_state.dart';
import '../../core/design_system.dart';
import '../../services/school_data_service.dart';
import '../../models/grade_record.dart';
import '../../models/student.dart';

class GradeEntryScreen extends StatefulWidget {
  const GradeEntryScreen({super.key});

  @override
  State<GradeEntryScreen> createState() => _GradeEntryScreenState();
}

class _GradeEntryScreenState extends State<GradeEntryScreen> {
  String? _selectedSection;
  String? _selectedGrade;
  String? _selectedArm;
  String? _selectedSubject;
  String _selectedTerm = '1st Term';
  late String _selectedSession;
  final Map<String, TextEditingController> _caControllers = {};
  final Map<String, TextEditingController> _examControllers = {};
  bool _isSaving = false;

  final List<String> _sessions = ['2024/2025', '2025/2026', '2026/2027'];

  @override
  void initState() {
    super.initState();

    // Standard Academic Session Logic: If month >= Sept (9), session is year/(year+1)
    final now = DateTime.now();
    final startYear = now.month >= 9 ? now.year : now.year - 1;
    final autoSession = '$startYear/${startYear + 1}';

    _selectedSession = _sessions.contains(autoSession)
        ? autoSession
        : _sessions[1];

    final subjects = context.read<AppState>().staffSubjects;
    if (subjects.isNotEmpty) {
      _selectedSubject = subjects.first;
    }
  }

  @override
  void dispose() {
    for (var controller in _caControllers.values) {
      controller.dispose();
    }
    for (var controller in _examControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _saveAllGrades(
    BuildContext context,
    SchoolDataService service,
    List<Student> students,
  ) async {
    setState(() => _isSaving = true);
    final schoolId = context.read<AppState>().schoolId ?? '';
    final session = _selectedSession;

    if (_selectedSubject == null) {
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a subject first.')),
      );
      return;
    }

    try {
      for (var student in students) {
        final ca =
            double.tryParse(_caControllers[student.id]?.text ?? '0') ?? 0;
        final exam =
            double.tryParse(_examControllers[student.id]?.text ?? '0') ?? 0;
        final total = ca + exam;

        if (total > 0) {
          // Use a deterministic ID to prevent duplicates (student_subject_term_session)
          final recordId =
              '${student.id}_${_selectedSubject}_${_selectedTerm}_${session.replaceAll('/', '_')}';

          final record = GradeRecord(
            id: recordId,
            studentId: student.id,
            schoolId: schoolId,
            subject: _selectedSubject!,
            caScore: ca,
            examScore: exam,
            totalScore: total,
            grade: GradingUtils.getLetterGrade(total),
            timestamp: DateTime.now(),
            term: _selectedTerm,
            session: session,
            classLevel: _selectedGrade!,
            arm: student.arm,
          );
          await service.addGradeRecord(record);
        }
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Grades saved successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error saving grades: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final schoolId = context.watch<AppState>().schoolId ?? '';
    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final allStudents = service.getStudentsForSchool(schoolId);

        // 1. Filter by Section first
        final studentsBySection = allStudents.where((s) {
          if (_selectedSection == null) return true;
          return s.section == _selectedSection;
        }).toList();

        // 2. Extract available grades from filtered list
        final grades = studentsBySection.map((s) => s.grade).toSet().toList()
          ..sort();

        // 3. Default to first grade if available and none selected
        if (_selectedGrade == null && grades.isNotEmpty) {
          // Only default if not already set, or if current selection is invalid for new section
          _selectedGrade = grades.first;
          _selectedArm = null;
        } else if (_selectedGrade != null && !grades.contains(_selectedGrade)) {
          _selectedGrade = grades.isNotEmpty ? grades.first : null;
          _selectedArm = null;
        }

        // 4. Finally filter by Grade and Arm
        final students = studentsBySection.where((s) {
          final matchesGrade =
              _selectedGrade == null || s.grade == _selectedGrade;
          final matchesArm = _selectedArm == null || s.arm == _selectedArm;
          return matchesGrade && matchesArm;
        }).toList();

        // 5. Extract available arms from current grade
        final arms =
            studentsBySection
                .where((s) => s.grade == _selectedGrade)
                .map((s) => s.arm)
                .where((a) => a.isNotEmpty)
                .toSet()
                .toList()
              ..sort();

        // 6. Fetch existing grades to pre-fill and lock fields
        final allGrades = service.getGradesForSchool(schoolId);
        final session = _selectedSession;

        final existingGrades = {
          for (var g in allGrades.where(
            (g) =>
                g.subject == _selectedSubject &&
                g.term == _selectedTerm &&
                g.session == session &&
                g.classLevel == _selectedGrade,
          ))
            g.studentId: g,
        };

        // Initialize controllers and pre-fill if data exists
        for (var student in students) {
          final existing = existingGrades[student.id];

          _caControllers.putIfAbsent(student.id, () {
            final controller = TextEditingController();
            if (existing != null && existing.caScore > 0) {
              controller.text = existing.caScore.toStringAsFixed(0);
            }
            return controller;
          });

          _examControllers.putIfAbsent(student.id, () {
            final controller = TextEditingController();
            if (existing != null && existing.examScore > 0) {
              controller.text = existing.examScore.toStringAsFixed(0);
            }
            return controller;
          });
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Input Grades',
              style: AppTypography.header.copyWith(fontSize: 20),
            ),
            backgroundColor: Colors.transparent,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: _buildSectionFilter(),
              ),

              // Grade Selector
              if (studentsBySection.isNotEmpty) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 5,
                  ),
                  child: Row(
                    children: grades.map((grade) {
                      final isSelected = _selectedGrade == grade;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 5),
                        child: ChoiceChip(
                          label: Text(grade),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _selectedGrade = grade;
                                _selectedArm = null;
                              });
                            }
                          },
                          selectedColor: AppColors.primary,
                          backgroundColor: Colors.white.withAlpha(10),
                          labelStyle: AppTypography.label.copyWith(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),

                // Arm Selector
                if (_selectedGrade != null && arms.isNotEmpty) ...[
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 15,
                      vertical: 5,
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: ChoiceChip(
                            label: const Text('All Arms'),
                            selected: _selectedArm == null,
                            onSelected: (val) {
                              if (val) setState(() => _selectedArm = null);
                            },
                            selectedColor: AppColors.primary,
                            backgroundColor: Colors.white.withAlpha(10),
                            labelStyle: AppTypography.label.copyWith(
                              color: _selectedArm == null
                                  ? Colors.white
                                  : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        ...arms.map((arm) {
                          final isSelected = _selectedArm == arm;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 5),
                            child: ChoiceChip(
                              label: Text('Arm $arm'),
                              selected: isSelected,
                              onSelected: (val) {
                                if (val) setState(() => _selectedArm = arm);
                              },
                              selectedColor: AppColors.primary,
                              backgroundColor: Colors.white.withAlpha(10),
                              labelStyle: AppTypography.label.copyWith(
                                color: isSelected
                                    ? Colors.white
                                    : Colors.white70,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ],

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSubject,
                            hint: const Text(
                              'Select Subject',
                              style: TextStyle(color: Colors.white38),
                            ),
                            dropdownColor: AppColors.surface,
                            items: context.read<AppState>().staffSubjects.map((
                              s,
                            ) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s, style: AppTypography.body),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedSubject = val),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedTerm,
                            dropdownColor: AppColors.surface,
                            items: ['1st Term', '2nd Term', '3rd Term'].map((
                              t,
                            ) {
                              return DropdownMenuItem(
                                value: t,
                                child: Text(t, style: AppTypography.body),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedTerm = val!),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedSession,
                            dropdownColor: AppColors.surface,
                            items: _sessions.map((s) {
                              return DropdownMenuItem(
                                value: s,
                                child: Text(s, style: AppTypography.body),
                              );
                            }).toList(),
                            onChanged: (val) =>
                                setState(() => _selectedSession = val!),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: students.isEmpty
                    ? Center(
                        child: Text(
                          'No students found for this school.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: students.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final existing = existingGrades[student.id];
                          return _buildGradeRow(
                            student: student,
                            isCaMuted: existing != null && existing.caScore > 0,
                            isExamMuted:
                                existing != null && existing.examScore > 0,
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () => _saveAllGrades(context, service, students),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSaving
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Save Grades'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGradeRow({
    required Student student,
    required bool isCaMuted,
    required bool isExamMuted,
  }) {
    return GlassContainer(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withAlpha(20),
                child: Text(
                  student.name[0],
                  style: const TextStyle(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(student.name, style: AppTypography.label),
                    Text(
                      student.grade,
                      style: AppTypography.body.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
              _buildGradeBadge(student.id),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildScoreField(
                  controller: _caControllers[student.id]!,
                  label: 'CA (0-30)',
                  max: 30,
                  studentId: student.id,
                  enabled: !isCaMuted,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildScoreField(
                  controller: _examControllers[student.id]!,
                  label: 'Exam (0-70)',
                  max: 70,
                  studentId: student.id,
                  enabled: !isExamMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreField({
    required TextEditingController controller,
    required String label,
    required double max,
    required String studentId,
    bool enabled = true,
  }) {
    return TextField(
      controller: controller,
      enabled: enabled,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.body.copyWith(
          fontSize: 12,
          color: enabled ? Colors.white70 : Colors.white24,
        ),
        isDense: true,
        filled: !enabled,
        fillColor: Colors.white.withAlpha(5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: enabled ? Colors.white24 : Colors.transparent,
          ),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.white10),
        ),
      ),
      keyboardType: TextInputType.number,
      style: TextStyle(color: enabled ? Colors.white : Colors.white38),
      onChanged: (val) {
        final score = double.tryParse(val) ?? 0;
        if (score > max) {
          controller.text = max.toString();
          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
        setState(() {}); // Refresh grade badge
      },
    );
  }

  Widget _buildGradeBadge(String studentId) {
    final ca = double.tryParse(_caControllers[studentId]?.text ?? '0') ?? 0;
    final exam = double.tryParse(_examControllers[studentId]?.text ?? '0') ?? 0;
    final total = ca + exam;
    final grade = GradingUtils.getLetterGrade(total);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getGradeColor(grade).withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getGradeColor(grade).withAlpha(50)),
      ),
      child: Column(
        children: [
          Text(
            grade,
            style: TextStyle(
              color: _getGradeColor(grade),
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          Text(
            '${total.toInt()}',
            style: TextStyle(
              color: _getGradeColor(grade).withAlpha(150),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: _selectedSection,
          hint: Text(
            'Filter by Section (All)',
            style: AppTypography.body.copyWith(color: Colors.white60),
          ),
          dropdownColor: AppColors.surface,
          isExpanded: true,
          items: [
            const DropdownMenuItem(value: null, child: Text('All Sections')),
            ...['Creche', 'Nursery', 'Primary', 'JSS', 'SSS'].map((s) {
              return DropdownMenuItem(
                value: s,
                child: Text(s, style: AppTypography.body),
              );
            }),
          ],
          onChanged: (val) => setState(() => _selectedSection = val),
        ),
      ),
    );
  }

  Color _getGradeColor(String grade) {
    switch (grade) {
      case 'A':
        return Colors.greenAccent;
      case 'B':
        return Colors.blueAccent;
      case 'C':
        return Colors.yellowAccent;
      case 'D':
        return Colors.orangeAccent;
      case 'E':
        return Colors.deepOrangeAccent;
      default:
        return Colors.redAccent;
    }
  }
}
