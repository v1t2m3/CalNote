// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test_record.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TestCalculationAdapter extends TypeAdapter<TestCalculation> {
  @override
  final int typeId = 2;

  @override
  TestCalculation read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestCalculation(
      name: fields[0] as String,
      inputs: (fields[1] as Map).cast<String, num>(),
      result: fields[2] as double,
      unit: fields[3] as String,
    );
  }

  @override
  void write(BinaryWriter writer, TestCalculation obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.inputs)
      ..writeByte(2)
      ..write(obj.result)
      ..writeByte(3)
      ..write(obj.unit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestCalculationAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TestRecordAdapter extends TypeAdapter<TestRecord> {
  @override
  final int typeId = 1;

  @override
  TestRecord read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TestRecord(
      id: fields[0] as String,
      title: fields[1] as String,
      calculations: (fields[2] as List).cast<TestCalculation>(),
      timestamp: fields[3] as DateTime,
      imagePaths: (fields[4] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, TestRecord obj) {
    writer
      ..writeByte(5)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.calculations)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.imagePaths);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestRecordAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
