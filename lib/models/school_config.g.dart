// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'school_config.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class SchoolConfigAdapter extends TypeAdapter<SchoolConfig> {
  @override
  final int typeId = 12;

  @override
  SchoolConfig read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return SchoolConfig(
      schoolId: fields[0] as String,
      showPositionOnReport: fields[1] as bool,
      showPositionInApp: fields[2] as bool,
    );
  }

  @override
  void write(BinaryWriter writer, SchoolConfig obj) {
    writer
      ..writeByte(3)
      ..writeByte(0)
      ..write(obj.schoolId)
      ..writeByte(1)
      ..write(obj.showPositionOnReport)
      ..writeByte(2)
      ..write(obj.showPositionInApp);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchoolConfigAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
