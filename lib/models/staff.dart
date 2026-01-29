import 'package:hive/hive.dart';

part 'staff.g.dart';

@HiveType(typeId: 0)
class Staff {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String department;
  @HiveField(3)
  final String role;
  @HiveField(4)
  final String email;
  @HiveField(5)
  final String schoolId;

  @HiveField(6)
  final String username;
  @HiveField(7)
  final String pin;
  @HiveField(8)
  final bool isFormMaster;
  @HiveField(9)
  final String? subject; // Deprecated, kept for backward compat
  @HiveField(10)
  final List<String> subjects;

  Staff({
    required this.id,
    required this.name,
    required this.department,
    required this.role,
    required this.email,
    required this.schoolId,
    required this.username,
    required this.pin,
    this.isFormMaster = false,
    this.subject,
    List<String>? subjects,
  }) : subjects = subjects ?? (subject != null ? [subject] : []);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'department': department,
      'role': role,
      'email': email,
      'schoolId': schoolId,
      'username': username,
      'pin': pin,
      'isFormMaster': isFormMaster,
      'subject': subject,
      'subjects': subjects,
    };
  }

  factory Staff.fromMap(Map<String, dynamic> map) {
    // Handle migration from single subject to list
    final singleSubject = map['subject'] as String?;
    final subjectsList = (map['subjects'] as List<dynamic>?)?.cast<String>();

    return Staff(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      department: map['department'] ?? '',
      role: map['role'] ?? '',
      email: map['email'] ?? '',
      schoolId: map['schoolId'] ?? '',
      username: map['username'] ?? '',
      pin: map['pin'] ?? '',
      isFormMaster: map['isFormMaster'] ?? false,
      subject: singleSubject,
      subjects: subjectsList,
    );
  }
}
