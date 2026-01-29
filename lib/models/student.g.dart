// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class StudentAdapter extends TypeAdapter<Student> {
  @override
  final int typeId = 1;

  @override
  Student read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Student(
      id: fields[0] as String,
      name: fields[1] as String,
      grade: fields[2] as String,
      performance: fields[3] as double,
      activities: (fields[4] as List).cast<String>(),
      schoolId: fields[6] as String,
      linkCode: fields[7] as String,
      section: fields[8] as String,
      arm: fields[10] as String,
      imageUrl: fields[9] as String?,
      isPresent: fields[5] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, Student obj) {
    writer
      ..writeByte(11)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.grade)
      ..writeByte(3)
      ..write(obj.performance)
      ..writeByte(4)
      ..write(obj.activities)
      ..writeByte(5)
      ..write(obj.isPresent)
      ..writeByte(6)
      ..write(obj.schoolId)
      ..writeByte(7)
      ..write(obj.linkCode)
      ..writeByte(8)
      ..write(obj.section)
      ..writeByte(9)
      ..write(obj.imageUrl)
      ..writeByte(10)
      ..write(obj.arm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StudentAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
