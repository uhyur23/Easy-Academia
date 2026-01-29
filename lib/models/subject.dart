import 'package:hive/hive.dart';

part 'subject.g.dart';

@HiveType(typeId: 8)
class Subject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String schoolId;

  @HiveField(3)
  final String? department;

  @HiveField(4)
  final DateTime createdAt;

  Subject({
    required this.id,
    required this.name,
    required this.schoolId,
    this.department,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'schoolId': schoolId,
      'department': department,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      schoolId: map['schoolId'] ?? '',
      department: map['department'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
    );
  }
}
