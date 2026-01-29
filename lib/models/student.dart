import 'package:hive/hive.dart';

part 'student.g.dart';

@HiveType(typeId: 1)
class Student {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String grade;
  @HiveField(3)
  final double performance; // 0.0 to 1.0
  @HiveField(4)
  final List<String> activities;
  @HiveField(5)
  bool isPresent;
  @HiveField(6)
  final String schoolId;
  @HiveField(7)
  final String linkCode;
  @HiveField(8)
  final String section; // Creche, Nursery, Primary, JSS, SSS
  @HiveField(9)
  final String? imageUrl;
  @HiveField(10)
  final String arm; // A, B, C, etc.

  Student({
    required this.id,
    required this.name,
    required this.grade,
    required this.performance,
    required this.activities,
    required this.schoolId,
    required this.linkCode,
    required this.section,
    required this.arm,
    this.imageUrl,
    this.isPresent = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'grade': grade,
      'section': section,
      'arm': arm,
      'imageUrl': imageUrl,
      'performance': performance,
      'activities': activities,
      'isPresent': isPresent,
      'schoolId': schoolId,
      'linkCode': linkCode,
    };
  }

  factory Student.fromMap(Map<String, dynamic> map) {
    return Student(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      grade: map['grade'] ?? '',
      section: map['section'] ?? 'Primary',
      arm: map['arm'] ?? '',
      imageUrl: map['imageUrl'],
      performance: (map['performance'] ?? 0.0).toDouble(),
      activities: List<String>.from(map['activities'] ?? []),
      isPresent: map['isPresent'] ?? true,
      schoolId: map['schoolId'] ?? '',
      linkCode: map['linkCode'] ?? '',
    );
  }
}
