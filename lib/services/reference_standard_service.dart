import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

class ReferenceItemModel {
  final String id;
  final String category;
  final String subCategory;
  final String item;
  final String limit;
  final String standard;

  const ReferenceItemModel({
    required this.id,
    required this.category,
    required this.subCategory,
    required this.item,
    required this.limit,
    required this.standard,
  });

  factory ReferenceItemModel.fromJson(Map<String, dynamic> json) {
    return ReferenceItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'] ?? json['sub_category'] ?? '',
      item: json['item'] ?? '',
      limit: json['limit'] ?? '',
      standard: json['standard'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'subCategory': subCategory,
        'item': item,
        'limit': limit,
        'standard': standard,
      };
}

class ReferenceStandardService {
  static const String boxName = 'standardsBox';

  /// Khởi tạo Box chứa Tiêu chuẩn và nạp mặc định nếu rỗng
  static Future<void> init() async {
    final box = await Hive.openBox(boxName);
    if (box.isEmpty) {
      await loadDefaultStandards();
    }
  }

  /// Nạp danh sách tiêu chuẩn mặc định từ file assets
  static Future<void> loadDefaultStandards() async {
    try {
      String content = await rootBundle.loadString('assets/standards.json');
      List<dynamic> parsedJson = jsonDecode(content);
      final box = Hive.box(boxName);
      await box.clear();

      for (int i = 0; i < parsedJson.length; i++) {
        var item = parsedJson[i];
        ReferenceItemModel model =
            ReferenceItemModel.fromJson(Map<String, dynamic>.from(item));
        String key = model.id.isNotEmpty ? model.id : 'STD_$i';
        await box.put(key, model.toJson());
      }
    } catch (e) {
      // Khi gặp lỗi vẫn có thể đọc dữ liệu mặc định từ asset nếu cần
    }
  }

  /// Nạp file JSON Tiêu chuẩn từ thiết bị (Ghi đè)
  static Future<String?> importStandardsFromFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        var parsedJson = jsonDecode(content);
        if (parsedJson is List) {
          final box = Hive.box(boxName);
          await box.clear(); // Ghi đè hoàn toàn danh sách cũ

          for (int i = 0; i < parsedJson.length; i++) {
            var item = parsedJson[i];
            ReferenceItemModel model =
                ReferenceItemModel.fromJson(Map<String, dynamic>.from(item));
            String key = model.id.isNotEmpty ? model.id : 'STD_$i';
            await box.put(key, model.toJson());
          }
          return "Nạp tiêu chuẩn thành công! Hệ thống đã cập nhật tiêu chuẩn mới.";
        } else {
          return "File JSON không đúng định dạng. Phải là một mảng (List) các tiêu chuẩn.";
        }
      } else {
        return "Bạn chưa chọn file.";
      }
    } catch (e) {
      return "Lỗi nạp file: $e";
    }
  }

  /// Khôi phục tiêu chuẩn về mặc định gốc
  static Future<String> resetToDefault() async {
    await loadDefaultStandards();
    return "Đã khôi phục Tiêu chuẩn về dữ liệu mặc định ban đầu.";
  }

  /// Lấy tất cả danh sách tiêu chuẩn
  static List<ReferenceItemModel> getAllStandards() {
    final box = Hive.box(boxName);
    return box.values
        .map((e) => ReferenceItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
