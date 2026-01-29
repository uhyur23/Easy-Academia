// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'activity.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class ActivityAdapter extends TypeAdapter<Activity> {
  @override
  final int typeId = 3;

  @override
  Activity read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Activity(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      dateTime: fields[3] as DateTime,
      status: fields[4] as ActivityStatus,
      location: fields[5] as String,
      schoolId: fields[6] as String,
      staffId: fields[7] as String?,
    );
  }

  @override
  void write(BinaryWriter writer, Activity obj) {
    writer
      ..writeByte(8)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.dateTime)
      ..writeByte(4)
      ..write(obj.status)
      ..writeByte(5)
      ..write(obj.location)
      ..writeByte(6)
      ..write(obj.schoolId)
      ..writeByte(7)
      ..write(obj.staffId);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class ActivityStatusAdapter extends TypeAdapter<ActivityStatus> {
  @override
  final int typeId = 2;

  @override
  ActivityStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return ActivityStatus.upcoming;
      case 1:
        return ActivityStatus.ongoing;
      case 2:
        return ActivityStatus.completed;
      default:
        return ActivityStatus.upcoming;
    }
  }

  @override
  void write(BinaryWriter writer, ActivityStatus obj) {
    switch (obj) {
      case ActivityStatus.upcoming:
        writer.writeByte(0);
        break;
      case ActivityStatus.ongoing:
        writer.writeByte(1);
        break;
      case ActivityStatus.completed:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ActivityStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
