// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'grade_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class GradeRecordAdapter extends TypeAdapter<GradeRecord> {
  @override
  final int typeId = 4;

  @override
  GradeRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return GradeRecord(
      id: fields[0] as String,
      studentId: fields[1] as String,
      schoolId: fields[2] as String,
      subject: fields[3] as String,
      caScore: fields[4] as double,
      examScore: fields[5] as double,
      totalScore: fields[6] as double,
      grade: fields[7] as String,
      timestamp: fields[8] as DateTime,
      term: fields[9] as String,
      session: fields[10] as String,
      classLevel: fields[11] as String,
      arm: fields[12] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, GradeRecord obj) {
    writer
      ..writeByte(13)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.studentId)
      ..writeByte(2)
      ..write(obj.schoolId)
      ..writeByte(3)
      ..write(obj.subject)
      ..writeByte(4)
      ..write(obj.caScore)
      ..writeByte(5)
      ..write(obj.examScore)
      ..writeByte(6)
      ..write(obj.totalScore)
      ..writeByte(7)
      ..write(obj.grade)
      ..writeByte(8)
      ..write(obj.timestamp)
      ..writeByte(9)
      ..write(obj.term)
      ..writeByte(10)
      ..write(obj.session)
      ..writeByte(11)
      ..write(obj.classLevel)
      ..writeByte(12)
      ..write(obj.arm);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GradeRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
