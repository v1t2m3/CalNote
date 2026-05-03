import 'package:hive/hive.dart';

part 'test_record.g.dart';

@HiveType(typeId: 2)
class TestCalculation {
  @HiveField(0)
  late String name; // Tên tính toán (VD: Quy đổi điện trở)

  @HiveField(1)
  late Map<String, num> inputs; // Thông số đo

  @HiveField(2)
  late double result; // Kết quả tính

  @HiveField(3)
  late String unit; // Đơn vị tính

  TestCalculation({
    required this.name,
    required this.inputs,
    required this.result,
    required this.unit,
  });
}

@HiveType(typeId: 1)
class TestRecord extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String title;

  @HiveField(2)
  late List<TestCalculation> calculations;

  @HiveField(3)
  late DateTime timestamp;

  @HiveField(4)
  late List<String> imagePaths;

  TestRecord({
    required this.id,
    required this.title,
    required this.calculations,
    required this.timestamp,
    required this.imagePaths,
  });
}
