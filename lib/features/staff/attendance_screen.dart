import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../core/app_state.dart';
import '../../core/design_system.dart';
import '../../core/user_role.dart';
import '../../services/school_data_service.dart';
import '../../models/daily_attendance.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  // Local state for optimistic updates
  final Map<String, bool> _localAttendance = {};
  String? _selectedGrade;
  String? _selectedArm;
  DateTime _selectedDate = DateTime.now();
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final schoolId = appState.schoolId ?? '';
    final isAuthorized =
        appState.activeRole == UserRole.admin ||
        (appState.activeRole == UserRole.staff && appState.isFormMaster);

    if (!isAuthorized) {
      return _buildAccessDenied();
    }

    return Consumer<SchoolDataService>(
      builder: (context, service, _) {
        final students = service.getStudentsForSchool(schoolId);

        // Get all unique grades for selection
        final grades = students.map((s) => s.grade).toSet().toList()..sort();

        if (_selectedGrade == null && grades.isNotEmpty) {
          _selectedGrade = grades.first;
          _selectedArm = null;
        } else if (_selectedGrade != null && !grades.contains(_selectedGrade)) {
          _selectedGrade = grades.isNotEmpty ? grades.first : null;
          _selectedArm = null;
        }

        // Get arms for the selected grade
        final arms =
            students
                .where((s) => s.grade == _selectedGrade)
                .map((s) => s.arm)
                .where((a) => a.isNotEmpty && a != 'None')
                .toSet()
                .toList()
              ..sort();

        // Filter students by selected grade and arm
        final filteredStudents = students
            .where((s) => s.grade == _selectedGrade)
            .where((s) => _selectedArm == null || s.arm == _selectedArm)
            .toList();

        // Check if attendance is already submitted for this date and grade
        final dateKey = _selectedDate.toIso8601String().split('T')[0];
        final record = service.getAttendanceRecord(
          dateKey,
          _selectedGrade ?? '',
          _selectedArm,
        );
        final isLocked = record != null;

        // Sync local state if not present or if record changed
        if (isLocked) {
          for (var id in record.presentStudentIds) {
            _localAttendance[id] = true;
          }
          for (var s in filteredStudents) {
            if (!record.presentStudentIds.contains(s.id)) {
              _localAttendance[s.id] = false;
            }
          }
        } else {
          for (var student in filteredStudents) {
            _localAttendance.putIfAbsent(student.id, () => student.isPresent);
          }
        }

        final presentCount = filteredStudents
            .where((s) => _localAttendance[s.id] ?? false)
            .length;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Mark Attendance',
              style: AppTypography.header.copyWith(fontSize: 20),
            ),
            backgroundColor: Colors.transparent,
            actions: [
              IconButton(
                icon: const Icon(Icons.calendar_month, color: Colors.white70),
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now().subtract(
                      const Duration(days: 30),
                    ),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // Date Indicator & Status
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(30),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.primary.withAlpha(50),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.today, size: 16, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat('EEEE, MMM d').format(_selectedDate),
                            style: AppTypography.label.copyWith(
                              fontSize: 13,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (isLocked)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withAlpha(30),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.check_circle,
                              size: 14,
                              color: Colors.green,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Submitted',
                              style: AppTypography.body.copyWith(
                                fontSize: 12,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),

              // Grade Selector
              if (grades.isNotEmpty)
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
                                _selectedArm =
                                    null; // Reset arm on grade change
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

              // Arm Selector
              if (_selectedGrade != null && arms.isNotEmpty)
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
                              color: isSelected ? Colors.white : Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),

              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_selectedGrade ?? 'Class'}${_selectedArm != null ? " ($_selectedArm)" : ""} Students',
                      style: AppTypography.label,
                    ),
                    Text(
                      '$presentCount/${filteredStudents.length}',
                      style: AppTypography.header.copyWith(
                        color: AppColors.primary,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: filteredStudents.isEmpty
                    ? Center(
                        child: Text(
                          'No students found for this class.',
                          style: AppTypography.body.copyWith(
                            color: Colors.white38,
                          ),
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: filteredStudents.length,
                        itemBuilder: (context, index) {
                          final student = filteredStudents[index];
                          final isPresent =
                              _localAttendance[student.id] ?? false;

                          Uint8List? imageBytes;
                          if (student.imageUrl != null &&
                              student.imageUrl!.isNotEmpty) {
                            try {
                              final cleanString =
                                  student.imageUrl!.contains(',')
                                  ? student.imageUrl!.split(',').last
                                  : student.imageUrl!;
                              imageBytes = base64Decode(cleanString);
                            } catch (e) {
                              debugPrint(
                                'Error decoding image for ${student.name}: $e',
                              );
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: GlassContainer(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: AppColors.primary
                                        .withAlpha(20),
                                    backgroundImage: imageBytes != null
                                        ? MemoryImage(imageBytes)
                                        : null,
                                    child: imageBytes == null
                                        ? Text(
                                            student.name.isNotEmpty
                                                ? student.name[0]
                                                : '?',
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          student.name,
                                          style: AppTypography.label,
                                        ),
                                        Text(
                                          'ID: ${student.linkCode}',
                                          style: AppTypography.body.copyWith(
                                            fontSize: 12,
                                            color: Colors.white38,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isPresent,
                                    onChanged: isLocked
                                        ? null
                                        : (val) {
                                            setState(() {
                                              _localAttendance[student.id] =
                                                  val;
                                            });
                                          },
                                    activeColor: AppColors.primary,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              if (!isLocked)
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () async {
                            setState(() => _isSubmitting = true);
                            try {
                              final presentIds = filteredStudents
                                  .where((s) => _localAttendance[s.id] ?? false)
                                  .map((s) => s.id)
                                  .toList();

                              final record = DailyAttendance(
                                id: '${dateKey}_${_selectedGrade}${_selectedArm != null ? "_$_selectedArm" : ""}',
                                date: DateTime(
                                  _selectedDate.year,
                                  _selectedDate.month,
                                  _selectedDate.day,
                                ),
                                schoolId: schoolId,
                                grade: _selectedGrade!,
                                arm: _selectedArm,
                                presentStudentIds: presentIds,
                                timestamp: DateTime.now(),
                                submittedBy: appState.userName ?? 'Staff',
                              );

                              await service.submitAttendance(record);

                              // Also update student models for backward compatibility if needed
                              for (var s in filteredStudents) {
                                await service.updateStudentAttendance(
                                  s.id,
                                  presentIds.contains(s.id),
                                );
                              }

                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Attendance submitted successfully!',
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            } finally {
                              if (mounted)
                                setState(() => _isSubmitting = false);
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : const Text('Submit Attendance'),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Close',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAccessDenied() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.transparent),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_person_rounded,
                size: 80,
                color: AppColors.primary.withAlpha(50),
              ),
              const SizedBox(height: 24),
              Text(
                'Access Denied',
                style: AppTypography.header.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 12),
              Text(
                'Recording attendance is limited to Form Masters only. Please contact your administrator for access.',
                textAlign: TextAlign.center,
                style: AppTypography.body.copyWith(color: Colors.white60),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  minimumSize: const Size(150, 45),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
