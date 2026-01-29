// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'daily_attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class DailyAttendanceAdapter extends TypeAdapter<DailyAttendance> {
  @override
  final int typeId = 5;

  @override
  DailyAttendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return DailyAttendance(
      id: fields[0] as String,
      schoolId: fields[1] as String,
      grade: fields[2] as String,
      arm: fields[7] as String?,
      date: fields[3] as DateTime,
      presentStudentIds: (fields[4] as List).cast<String>(),
      timestamp: fields[5] as DateTime,
      submittedBy: fields[6] as String,
    );
  }

  @override
  void write(BinaryWriter writer, DailyAttendance obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.schoolId)
      ..writeByte(2)
      ..write(obj.grade)
      ..writeByte(3)
      ..write(obj.date)
      ..writeByte(4)
      ..write(obj.presentStudentIds)
      ..writeByte(5)
      ..write(obj.timestamp)
      ..writeByte(6)
      ..write(obj.submittedBy)
      ..writeByte(7)
      ..write(obj.arm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyAttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
