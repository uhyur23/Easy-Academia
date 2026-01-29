import 'package:hive/hive.dart';

part 'activity.g.dart';

@HiveType(typeId: 2)
enum ActivityStatus {
  @HiveField(0)
  upcoming,
  @HiveField(1)
  ongoing,
  @HiveField(2)
  completed,
}

@HiveType(typeId: 3)
class Activity {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final DateTime dateTime;
  @HiveField(4)
  final ActivityStatus status;
  @HiveField(5)
  final String location;
  @HiveField(6)
  final String schoolId;
  @HiveField(7)
  final String? staffId; // Optional, null means global/admin activity

  Activity({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.status,
    required this.location,
    required this.schoolId,
    this.staffId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'status': status.index,
      'location': location,
      'schoolId': schoolId,
      'staffId': staffId,
    };
  }

  factory Activity.fromMap(Map<String, dynamic> map) {
    return Activity(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      dateTime: DateTime.parse(
        map['dateTime'] ?? DateTime.now().toIso8601String(),
      ),
      status: ActivityStatus.values[map['status'] ?? 0],
      location: map['location'] ?? '',
      schoolId: map['schoolId'] ?? '',
      staffId: map['staffId'],
    );
  }
}
