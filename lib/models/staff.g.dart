// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'staff.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StaffAdapter extends TypeAdapter<Staff> {
  @override
  final int typeId = 0;

  @override
  Staff read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Staff(
      id: fields[0] as String,
      name: fields[1] as String,
      department: fields[2] as String,
      role: fields[3] as String,
      email: fields[4] as String,
      schoolId: fields[5] as String,
      username: fields[6] as String,
      pin: fields[7] as String,
      isFormMaster: fields[8] as bool,
      subject: fields[9] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Staff obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.department)
      ..writeByte(3)
      ..write(obj.role)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.schoolId)
      ..writeByte(6)
      ..write(obj.username)
      ..writeByte(7)
      ..write(obj.pin)
      ..writeByte(8)
      ..write(obj.isFormMaster)
      ..writeByte(9)
      ..write(obj.subject);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
