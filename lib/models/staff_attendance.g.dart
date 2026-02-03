// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff_attendance.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StaffAttendanceAdapter extends TypeAdapter<StaffAttendance> {
  @override
  final int typeId = 13;

  @override
  StaffAttendance read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return StaffAttendance(
      id: fields[0] as String,
      staffId: fields[1] as String,
      staffName: fields[2] as String,
      schoolId: fields[3] as String,
      timestamp: fields[4] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, StaffAttendance obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.staffId)
      ..writeByte(2)
      ..write(obj.staffName)
      ..writeByte(3)
      ..write(obj.schoolId)
      ..writeByte(4)
      ..write(obj.timestamp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffAttendanceAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
