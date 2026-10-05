import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

/// Model Tiêu chuẩn thử nghiệm (Standards)
class ReferenceItemModel {
  final String id;
  final String category;
  final String categoryCode;
  final String subCategory;
  final String item;
  final String limit;
  final String standard;
  final String voltageLevel;
  final String recommendation;

  const ReferenceItemModel({
    required this.id,
    required this.category,
    required this.categoryCode,
    required this.subCategory,
    required this.item,
    required this.limit,
    required this.standard,
    required this.voltageLevel,
    required this.recommendation,
  });

  factory ReferenceItemModel.fromJson(Map<String, dynamic> json) {
    return ReferenceItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      categoryCode: json['categoryCode'] ?? 'relay_safety',
      subCategory: json['subCategory'] ?? json['sub_category'] ?? '',
      item: json['item'] ?? '',
      limit: json['limit'] ?? '',
      standard: json['standard'] ?? '',
      voltageLevel: json['voltageLevel'] ?? json['voltage_level'] ?? 'ALL',
      recommendation: json['recommendation'] ??
          'Xử lý cách điện, đo đạc lại hoặc thực hiện theo quy định nhà sản xuất.',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'categoryCode': categoryCode,
        'subCategory': subCategory,
        'item': item,
        'limit': limit,
        'standard': standard,
        'voltageLevel': voltageLevel,
        'recommendation': recommendation,
      };
}

/// Model Tiêu chuẩn kiểm định (Thông tư 02/2025/TT-BCT)
class TT02ItemModel {
  final String id;
  final String category;
  final String categoryCode;
  final String subCategory;
  final String item;
  final String period;
  final String limit;
  final String standard;
  final String voltageLevel;
  final String recommendation;

  const TT02ItemModel({
    required this.id,
    required this.category,
    required this.categoryCode,
    required this.subCategory,
    required this.item,
    required this.period,
    required this.limit,
    required this.standard,
    required this.voltageLevel,
    required this.recommendation,
  });

  factory TT02ItemModel.fromJson(Map<String, dynamic> json) {
    return TT02ItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      categoryCode: json['categoryCode'] ?? 'relay_safety',
      subCategory: json['subCategory'] ?? '',
      item: json['item'] ?? '',
      period: json['period'] ?? '',
      limit: json['limit'] ?? '',
      standard: json['standard'] ?? '',
      voltageLevel: json['voltageLevel'] ?? 'ALL',
      recommendation: json['recommendation'] ??
          'Thiết bị bắt buộc kiểm định an toàn kỹ thuật theo Thông tư 02/2025/TT-BCT.',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'categoryCode': categoryCode,
        'subCategory': subCategory,
        'item': item,
        'period': period,
        'limit': limit,
        'standard': standard,
        'voltageLevel': voltageLevel,
        'recommendation': recommendation,
      };
}

/// Model Tiêu chuẩn CBM (Condition-Based Maintenance)
class CbmItemModel {
  final String id;
  final String category;
  final String categoryCode;
  final String subCategory;
  final String item;
  final String voltageLevel;
  final String good;
  final String fair;
  final String average;
  final String poor;
  final String recommendation;
  final String standard;

  const CbmItemModel({
    required this.id,
    required this.category,
    required this.categoryCode,
    required this.subCategory,
    required this.item,
    required this.voltageLevel,
    required this.good,
    required this.fair,
    required this.average,
    required this.poor,
    required this.recommendation,
    required this.standard,
  });

  factory CbmItemModel.fromJson(Map<String, dynamic> json) {
    return CbmItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      categoryCode: json['categoryCode'] ?? 'relay_safety',
      subCategory: json['subCategory'] ?? '',
      item: json['item'] ?? '',
      voltageLevel: json['voltageLevel'] ?? 'ALL',
      good: json['good'] ?? '',
      fair: json['fair'] ?? 'N/A',
      average: json['average'] ?? 'N/A',
      poor: json['poor'] ?? '',
      recommendation: json['recommendation'] ?? '',
      standard: json['standard'] ?? 'EVNCPC-KT/QT.40',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'categoryCode': categoryCode,
        'subCategory': subCategory,
        'item': item,
        'voltageLevel': voltageLevel,
        'good': good,
        'fair': fair,
        'average': average,
        'poor': poor,
        'recommendation': recommendation,
        'standard': standard,
      };
}

class ReferenceStandardService {
  static const String boxStandards = 'standardsBox';
  static const String boxTT02 = 'tt02Box';
  static const String boxCBM = 'cbmBox';

  /// Khởi tạo các Box Hive và nạp dữ liệu mặc định từ asset nếu rỗng
  static Future<void> init() async {
    final bStd = await Hive.openBox(boxStandards);
    final bTT02 = await Hive.openBox(boxTT02);
    final bCBM = await Hive.openBox(boxCBM);

    if (bStd.isEmpty) {
      await loadDefaultStandards();
    }
    if (bTT02.isEmpty) {
      await loadDefaultTT02();
    }
    if (bCBM.isEmpty) {
      await loadDefaultCBM();
    }
  }

  /// Nạp danh sách tiêu chuẩn Thử nghiệm từ assets
  static Future<void> loadDefaultStandards() async {
    try {
      String content = await rootBundle.loadString('assets/standards.json');
      List<dynamic> parsedJson = jsonDecode(content);
      final box = Hive.box(boxStandards);
      await box.clear();

      for (int i = 0; i < parsedJson.length; i++) {
        var item = parsedJson[i];
        ReferenceItemModel model =
            ReferenceItemModel.fromJson(Map<String, dynamic>.from(item));
        String key = model.id.isNotEmpty ? model.id : 'STD_$i';
        await box.put(key, model.toJson());
      }
    } catch (e) {
      // Catch fallback
    }
  }

  /// Nạp danh sách Tiêu chuẩn Kiểm định TT02 từ assets
  static Future<void> loadDefaultTT02() async {
    try {
      String content = await rootBundle.loadString('assets/standardTT02.json');
      List<dynamic> parsedJson = jsonDecode(content);
      final box = Hive.box(boxTT02);
      await box.clear();

      for (int i = 0; i < parsedJson.length; i++) {
        var item = parsedJson[i];
        TT02ItemModel model =
            TT02ItemModel.fromJson(Map<String, dynamic>.from(item));
        String key = model.id.isNotEmpty ? model.id : 'TT02_$i';
        await box.put(key, model.toJson());
      }
    } catch (e) {
      // Catch fallback
    }
  }

  /// Nạp danh sách Tiêu chuẩn CBM từ assets
  static Future<void> loadDefaultCBM() async {
    try {
      String content = await rootBundle.loadString('assets/standardCBM.json');
      List<dynamic> parsedJson = jsonDecode(content);
      final box = Hive.box(boxCBM);
      await box.clear();

      for (int i = 0; i < parsedJson.length; i++) {
        var item = parsedJson[i];
        CbmItemModel model =
            CbmItemModel.fromJson(Map<String, dynamic>.from(item));
        String key = model.id.isNotEmpty ? model.id : 'CBM_$i';
        await box.put(key, model.toJson());
      }
    } catch (e) {
      // Catch fallback
    }
  }

  /// Nạp file JSON Tiêu chuẩn thử nghiệm từ máy
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
          final box = Hive.box(boxStandards);
          await box.clear();

          for (int i = 0; i < parsedJson.length; i++) {
            var item = parsedJson[i];
            ReferenceItemModel model =
                ReferenceItemModel.fromJson(Map<String, dynamic>.from(item));
            String key = model.id.isNotEmpty ? model.id : 'STD_$i';
            await box.put(key, model.toJson());
          }
          return "Nạp Tiêu chuẩn Thử nghiệm thành công!";
        } else {
          return "File JSON không đúng định dạng List.";
        }
      } else {
        return "Bạn chưa chọn file.";
      }
    } catch (e) {
      return "Lỗi nạp file: $e";
    }
  }

  /// Nạp file JSON Tiêu chuẩn TT02 từ máy
  static Future<String?> importTT02FromFile() async {
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
          final box = Hive.box(boxTT02);
          await box.clear();

          for (int i = 0; i < parsedJson.length; i++) {
            var item = parsedJson[i];
            TT02ItemModel model =
                TT02ItemModel.fromJson(Map<String, dynamic>.from(item));
            String key = model.id.isNotEmpty ? model.id : 'TT02_$i';
            await box.put(key, model.toJson());
          }
          return "Nạp Tiêu chuẩn Kiểm định TT02 thành công!";
        } else {
          return "File JSON không đúng định dạng List.";
        }
      } else {
        return "Bạn chưa chọn file.";
      }
    } catch (e) {
      return "Lỗi nạp file: $e";
    }
  }

  /// Nạp file JSON Tiêu chuẩn CBM từ máy
  static Future<String?> importCBMFromFile() async {
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
          final box = Hive.box(boxCBM);
          await box.clear();

          for (int i = 0; i < parsedJson.length; i++) {
            var item = parsedJson[i];
            CbmItemModel model =
                CbmItemModel.fromJson(Map<String, dynamic>.from(item));
            String key = model.id.isNotEmpty ? model.id : 'CBM_$i';
            await box.put(key, model.toJson());
          }
          return "Nạp Tiêu chuẩn CBM thành công!";
        } else {
          return "File JSON không đúng định dạng List.";
        }
      } else {
        return "Bạn chưa chọn file.";
      }
    } catch (e) {
      return "Lỗi nạp file: $e";
    }
  }

  /// Khôi phục tiêu chuẩn thử nghiệm về mặc định
  static Future<String> resetStandardsToDefault() async {
    await loadDefaultStandards();
    return "Đã khôi phục Tiêu chuẩn Thử nghiệm về mặc định ban đầu.";
  }

  /// Khôi phục tiêu chuẩn TT02 về mặc định
  static Future<String> resetTT02ToDefault() async {
    await loadDefaultTT02();
    return "Đã khôi phục Tiêu chuẩn Kiểm định TT02 về mặc định ban đầu.";
  }

  /// Khôi phục tiêu chuẩn CBM về mặc định
  static Future<String> resetCBMToDefault() async {
    await loadDefaultCBM();
    return "Đã khôi phục Tiêu chuẩn CBM về mặc định ban đầu.";
  }

  /// Lấy tất cả Tiêu chuẩn Thử nghiệm
  static List<ReferenceItemModel> getAllStandards() {
    final box = Hive.box(boxStandards);
    return box.values
        .map((e) => ReferenceItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Lấy tất cả Tiêu chuẩn Kiểm định TT02
  static List<TT02ItemModel> getAllTT02() {
    final box = Hive.box(boxTT02);
    return box.values
        .map((e) => TT02ItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Lấy tất cả Tiêu chuẩn CBM
  static List<CbmItemModel> getAllCBM() {
    final box = Hive.box(boxCBM);
    return box.values
        .map((e) => CbmItemModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
