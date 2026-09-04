// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hive_adapters.dart';

// **************************************************************************
// AdaptersGenerator
// **************************************************************************

class TrackerAdapter extends TypeAdapter<Tracker> {
  @override
  final typeId = 0;

  @override
  Tracker read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Tracker(
      id: fields[6] == null ? '' : fields[6] as String,
      name: fields[0] as String,
      startedAt: fields[1] as DateTime,
      emoji: fields[7] == null ? '⭐' : fields[7] as String,
      colorIndex: fields[8] == null ? 0 : (fields[8] as num).toInt(),
      sortIndex: fields[9] == null ? 0 : (fields[9] as num).toInt(),
      milestones: fields[2] == null
          ? kDefaultMilestones
          : (fields[2] as List).cast<Duration>(),
      history: fields[3] == null
          ? const []
          : (fields[3] as List).cast<TrackerRun>(),
      acknowledged: fields[4] == null
          ? const {}
          : (fields[4] as Set).cast<Duration>(),
      schemaVersion: fields[5] == null ? 2 : (fields[5] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, Tracker obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.startedAt)
      ..writeByte(2)
      ..write(obj.milestones)
      ..writeByte(3)
      ..write(obj.history)
      ..writeByte(4)
      ..write(obj.acknowledged)
      ..writeByte(5)
      ..write(obj.schemaVersion)
      ..writeByte(6)
      ..write(obj.id)
      ..writeByte(7)
      ..write(obj.emoji)
      ..writeByte(8)
      ..write(obj.colorIndex)
      ..writeByte(9)
      ..write(obj.sortIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackerAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TrackerRunAdapter extends TypeAdapter<TrackerRun> {
  @override
  final typeId = 1;

  @override
  TrackerRun read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TrackerRun(
      startedAt: fields[0] as DateTime,
      endedAt: fields[1] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, TrackerRun obj) {
    writer
      ..writeByte(2)
      ..writeByte(0)
      ..write(obj.startedAt)
      ..writeByte(1)
      ..write(obj.endedAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrackerRunAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class AlarmEntryAdapter extends TypeAdapter<AlarmEntry> {
  @override
  final typeId = 2;

  @override
  AlarmEntry read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return AlarmEntry(
      id: fields[0] == null ? '' : fields[0] as String,
      label: fields[1] == null ? 'Alarm' : fields[1] as String,
      hour: fields[2] == null ? 7 : (fields[2] as num).toInt(),
      minute: fields[3] == null ? 0 : (fields[3] as num).toInt(),
      repeatDays: fields[4] == null
          ? const []
          : (fields[4] as List).cast<int>(),
      soundId: fields[5] == null ? kDefaultRingtoneId : fields[5] as String,
      isEnabled: fields[6] == null ? true : fields[6] as bool,
      snoozeMinutes: fields[7] == null ? 5 : (fields[7] as num).toInt(),
      sortIndex: fields[8] == null ? 0 : (fields[8] as num).toInt(),
    );
  }

  @override
  void write(BinaryWriter writer, AlarmEntry obj) {
    writer
      ..writeByte(9)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.label)
      ..writeByte(2)
      ..write(obj.hour)
      ..writeByte(3)
      ..write(obj.minute)
      ..writeByte(4)
      ..write(obj.repeatDays)
      ..writeByte(5)
      ..write(obj.soundId)
      ..writeByte(6)
      ..write(obj.isEnabled)
      ..writeByte(7)
      ..write(obj.snoozeMinutes)
      ..writeByte(8)
      ..write(obj.sortIndex);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AlarmEntryAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class NoteAdapter extends TypeAdapter<Note> {
  @override
  final typeId = 3;

  @override
  Note read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Note(
      id: fields[0] == null ? '' : fields[0] as String,
      title: fields[1] == null ? '' : fields[1] as String,
      body: fields[2] == null ? '' : fields[2] as String,
      colorTag: fields[3] == null ? kDefaultNoteTag : fields[3] as String,
      isTask: fields[6] == null ? false : fields[6] as bool,
      isDone: fields[7] == null ? false : fields[7] as bool,
      completedAt: fields[8] as DateTime?,
      dueAt: fields[9] as DateTime?,
      createdAt: fields[4] as DateTime,
      updatedAt: fields[5] as DateTime,
    );
  }

  @override
  void write(BinaryWriter writer, Note obj) {
    writer
      ..writeByte(10)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.body)
      ..writeByte(3)
      ..write(obj.colorTag)
      ..writeByte(4)
      ..write(obj.createdAt)
      ..writeByte(5)
      ..write(obj.updatedAt)
      ..writeByte(6)
      ..write(obj.isTask)
      ..writeByte(7)
      ..write(obj.isDone)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.dueAt);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NoteAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
