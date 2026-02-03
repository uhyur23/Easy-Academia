import 'package:hive/hive.dart';

part 'school_config.g.dart';

@HiveType(typeId: 12)
class SchoolConfig extends HiveObject {
  @HiveField(0)
  final String schoolId;

  @HiveField(1)
  final bool showPositionOnReport;

  @HiveField(2)
  final bool showPositionInApp;

  SchoolConfig({
    required this.schoolId,
    this.showPositionOnReport = true,
    this.showPositionInApp = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'showPositionOnReport': showPositionOnReport,
      'showPositionInApp': showPositionInApp,
    };
  }

  factory SchoolConfig.fromMap(Map<String, dynamic> map) {
    return SchoolConfig(
      schoolId: map['schoolId'] ?? '',
      showPositionOnReport: map['showPositionOnReport'] ?? true,
      showPositionInApp: map['showPositionInApp'] ?? true,
    );
  }

  SchoolConfig copyWith({
    String? schoolId,
    bool? showPositionOnReport,
    bool? showPositionInApp,
  }) {
    return SchoolConfig(
      schoolId: schoolId ?? this.schoolId,
      showPositionOnReport: showPositionOnReport ?? this.showPositionOnReport,
      showPositionInApp: showPositionInApp ?? this.showPositionInApp,
    );
  }
}
