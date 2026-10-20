import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

/// Kết quả đối chiếu Tiêu chuẩn Thử nghiệm (TCVN / IEC)
class StandardEvalResult {
  final bool isPass;
  final String statusText;
  final String limitText;
  final String standardText;
  final String recommendation;
  final ReferenceItemModel? item;

  const StandardEvalResult({
    required this.isPass,
    required this.statusText,
    required this.limitText,
    required this.standardText,
    required this.recommendation,
    this.item,
  });
}

/// Kết quả đối chiếu Tiêu chuẩn CBM (4 mức tình trạng)
class CbmEvalResult {
  final int level; // 1, 2, 3, 4
  final String levelName; // Mức 1 (Tốt), Mức 2 (Khá), ...
  final String conclusion;
  final String rangeText;
  final String recommendation;
  final CbmItemModel? item;

  const CbmEvalResult({
    required this.level,
    required this.levelName,
    required this.conclusion,
    required this.rangeText,
    required this.recommendation,
    this.item,
  });
}

/// Kết quả đối chiếu Tiêu chuẩn Kiểm định TT 02/2025/TT-BCT
class TT02EvalResult {
  final bool isPass;
  final String statusText;
  final String limitText;
  final String periodText;
  final String standardText;
  final String recommendation;
  final TT02ItemModel? item;

  const TT02EvalResult({
    required this.isPass,
    required this.statusText,
    required this.limitText,
    required this.periodText,
    required this.standardText,
    required this.recommendation,
    this.item,
  });
}

/// Model Tiêu chuẩn thử nghiệm (Standards)
class ReferenceItemModel {
  final String id;
  final String category;
  final String categoryCode;
  final String subCategory;
  final String item;
  final String testCode;
  final String limit;
  final String standard;
  final String voltageLevel;
  final String recommendation;
  final String? symbol;
  final String? compare;
  final dynamic value;
  final dynamic min;
  final dynamic max;
  final String? unit;
  final String? note;

  const ReferenceItemModel({
    required this.id,
    required this.category,
    required this.categoryCode,
    required this.subCategory,
    required this.item,
    this.testCode = '',
    required this.limit,
    required this.standard,
    required this.voltageLevel,
    required this.recommendation,
    this.symbol,
    this.compare,
    this.value,
    this.min,
    this.max,
    this.unit,
    this.note,
  });

  factory ReferenceItemModel.fromJson(Map<String, dynamic> json) {
    return ReferenceItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      categoryCode: json['categoryCode'] ?? 'relay_safety',
      subCategory: json['subCategory'] ?? json['sub_category'] ?? json['category'] ?? '',
      item: json['item'] ?? '',
      testCode: json['testCode'] ?? '',
      limit: json['limit'] ?? '',
      standard: json['standard'] ?? '',
      voltageLevel: json['voltageLevel'] ?? json['voltage_level'] ?? 'ALL',
      recommendation: json['recommendation'] ??
          'Xử lý cách điện, đo đạc lại hoặc thực hiện theo quy định nhà sản xuất.',
      symbol: json['symbol'],
      compare: json['compare'],
      value: json['value'],
      min: json['min'],
      max: json['max'],
      unit: json['unit'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'categoryCode': categoryCode,
        'subCategory': subCategory,
        'item': item,
        'testCode': testCode,
        'limit': limit,
        'standard': standard,
        'voltageLevel': voltageLevel,
        'recommendation': recommendation,
        'symbol': symbol,
        'compare': compare,
        'value': value,
        'min': min,
        'max': max,
        'unit': unit,
        'note': note,
      };
}

/// Model Tiêu chuẩn kiểm định (Thông tư 02/2025/TT-BCT)
class TT02ItemModel {
  final String id;
  final String category;
  final String categoryCode;
  final String subCategory;
  final String item;
  final String testCode;
  final String period;
  final String limit;
  final String standard;
  final String voltageLevel;
  final String recommendation;
  final String? symbol;
  final String? compare;
  final dynamic value;
  final dynamic min;
  final dynamic max;
  final String? unit;
  final String? note;

  const TT02ItemModel({
    required this.id,
    required this.category,
    required this.categoryCode,
    required this.subCategory,
    required this.item,
    this.testCode = '',
    required this.period,
    required this.limit,
    required this.standard,
    required this.voltageLevel,
    required this.recommendation,
    this.symbol,
    this.compare,
    this.value,
    this.min,
    this.max,
    this.unit,
    this.note,
  });

  factory TT02ItemModel.fromJson(Map<String, dynamic> json) {
    return TT02ItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      categoryCode: json['categoryCode'] ?? 'relay_safety',
      subCategory: json['subCategory'] ?? json['category'] ?? '',
      item: json['item'] ?? '',
      testCode: json['testCode'] ?? '',
      period: json['period'] ?? 'Lần đầu, định kỳ, sau sửa chữa',
      limit: json['limit'] ?? '',
      standard: json['standard'] ?? 'Thông tư 02/2025/TT-BCT',
      voltageLevel: json['voltageLevel'] ?? 'ALL',
      recommendation: json['recommendation'] ??
          'Thiết bị bắt buộc kiểm định an toàn kỹ thuật theo Thông tư 02/2025/TT-BCT.',
      symbol: json['symbol'],
      compare: json['compare'],
      value: json['value'],
      min: json['min'],
      max: json['max'],
      unit: json['unit'],
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'categoryCode': categoryCode,
        'subCategory': subCategory,
        'item': item,
        'testCode': testCode,
        'period': period,
        'limit': limit,
        'standard': standard,
        'voltageLevel': voltageLevel,
        'recommendation': recommendation,
        'symbol': symbol,
        'compare': compare,
        'value': value,
        'min': min,
        'max': max,
        'unit': unit,
        'note': note,
      };
}

/// Model Tiêu chuẩn CBM (Condition-Based Maintenance)
class CbmItemModel {
  final String id;
  final String category;
  final String categoryCode;
  final String subCategory;
  final String item;
  final String testCode;
  final String voltageLevel;
  final String? symbol;
  final String? unit;
  final Map<String, dynamic>? levels;
  final String good;
  final String fair;
  final String average;
  final String poor;
  final String recommendation;
  final String standard;
  final String? note;

  const CbmItemModel({
    required this.id,
    required this.category,
    required this.categoryCode,
    required this.subCategory,
    required this.item,
    this.testCode = '',
    required this.voltageLevel,
    this.symbol,
    this.unit,
    this.levels,
    required this.good,
    required this.fair,
    required this.average,
    required this.poor,
    required this.recommendation,
    required this.standard,
    this.note,
  });

  /// Tên phép đo hiển thị kèm ký hiệu tính toán trong ngoặc đơn (nếu có)
  String get displayItem {
    if (symbol != null && symbol!.trim().isNotEmpty) {
      final s = symbol!.trim();
      if (!item.contains('($s)')) {
        return '$item ($s)';
      }
    }
    return item;
  }

  factory CbmItemModel.fromJson(Map<String, dynamic> json) {
    return CbmItemModel(
      id: json['id'] ?? '',
      category: json['category'] ?? '',
      categoryCode: json['categoryCode'] ?? 'relay_safety',
      subCategory: json['subCategory'] ?? json['category'] ?? '',
      item: json['item'] ?? '',
      testCode: json['testCode'] ?? '',
      voltageLevel: json['voltageLevel'] ?? 'ALL',
      symbol: json['symbol'],
      unit: json['unit'],
      levels: json['levels'] != null ? Map<String, dynamic>.from(json['levels']) : null,
      good: json['good'] ?? '',
      fair: json['fair'] ?? 'N/A',
      average: json['average'] ?? 'N/A',
      poor: json['poor'] ?? '',
      recommendation: json['recommendation'] ?? '',
      standard: json['standard'] ?? 'Quy trình CBM EVN',
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'category': category,
        'categoryCode': categoryCode,
        'subCategory': subCategory,
        'item': item,
        'testCode': testCode,
        'voltageLevel': voltageLevel,
        'symbol': symbol,
        'unit': unit,
        'levels': levels,
        'good': good,
        'fair': fair,
        'average': average,
        'poor': poor,
        'recommendation': recommendation,
        'standard': standard,
        'note': note,
      };
}

class ReferenceStandardService {
  static const String boxStandards = 'standardsBox';
  static const String boxTT02 = 'tt02Box';
  static const String boxCBM = 'cbmBox';
  static const int currentSchemaVersion = 5;
  static const String keySchemaVersion = 'standards_schema_version_v5';

  /// Khởi tạo các Box Hive và nạp dữ liệu mặc định từ asset nếu rỗng hoặc phiên bản cũ
  static Future<void> init() async {
    final bStd = await Hive.openBox(boxStandards);
    final bTT02 = await Hive.openBox(boxTT02);
    final bCBM = await Hive.openBox(boxCBM);
    final appBox = await Hive.openBox('appSettingsBox');

    final lastVer = appBox.get(keySchemaVersion);
    if (lastVer != currentSchemaVersion || bStd.isEmpty || bTT02.isEmpty || bCBM.isEmpty) {
      await loadDefaultStandards();
      await loadDefaultTT02();
      await loadDefaultCBM();
      await appBox.put(keySchemaVersion, currentSchemaVersion);
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
    } catch (_) {}
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
    } catch (_) {}
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
    } catch (_) {}
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
          return "Nạp Tiêu chuẩn Thử nghiệm thành công (${parsedJson.length} chỉ tiêu)!";
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
          return "Nạp Tiêu chuẩn Kiểm định TT02 thành công (${parsedJson.length} chỉ tiêu)!";
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
          return "Nạp Tiêu chuẩn CBM thành công (${parsedJson.length} chỉ tiêu)!";
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

  // =========================================================================
  // CÁC HÀM TRA CỨU & ĐỐI CHIẾU TIÊU CHUẨN TỰ ĐỘNG THEO TESTCODE & CẤP ĐIỆN ÁP
  // =========================================================================

  /// Kiểm tra xem cấp điện áp của tiêu chuẩn có phù hợp với đối tượng đo không
  static bool matchVoltage(String itemLevel, String targetLevel) {
    if (targetLevel == 'ALL' || itemLevel == 'ALL') return true;
    final normTarget = (targetLevel == '110kV' || targetLevel == '>35' || targetLevel == '>35kV')
        ? '>35kV'
        : '<=35kV';
    final normItem = (itemLevel == '110kV' || itemLevel == '>35' || itemLevel == '>35kV')
        ? '>35kV'
        : '<=35kV';
    return normTarget == normItem;
  }

  /// Tìm Tiêu chuẩn Thử nghiệm phù hợp nhất theo testCode, cấp điện áp và ký hiệu phép đo (symbol)
  static ReferenceItemModel? getStandardByTestCode(String testCode, {String voltageLevel = 'ALL', String? symbol}) {
    final all = getAllStandards();
    // Ưu tiên khớp chính xác testCode, symbol (nếu có) và voltageLevel
    for (var it in all) {
      if (it.testCode == testCode && (symbol == null || it.symbol == symbol) && it.voltageLevel == voltageLevel) {
        return it;
      }
    }
    for (var it in all) {
      if (it.testCode == testCode && (symbol == null || it.symbol == symbol) && matchVoltage(it.voltageLevel, voltageLevel)) {
        return it;
      }
    }
    // Fallback: nếu có symbol nhưng không tìm thấy, thử tìm chỉ theo testCode
    if (symbol != null) {
      for (var it in all) {
        if (it.testCode == testCode && matchVoltage(it.voltageLevel, voltageLevel)) {
          return it;
        }
      }
    }
    return null;
  }

  /// Tìm Tiêu chuẩn CBM phù hợp nhất theo testCode, cấp điện áp và ký hiệu phép đo (symbol)
  static CbmItemModel? getCbmByTestCode(String testCode, {String voltageLevel = 'ALL', String? symbol}) {
    final all = getAllCBM();
    for (var it in all) {
      if (it.testCode == testCode && (symbol == null || it.symbol == symbol) && it.voltageLevel == voltageLevel) {
        return it;
      }
    }
    for (var it in all) {
      if (it.testCode == testCode && (symbol == null || it.symbol == symbol) && matchVoltage(it.voltageLevel, voltageLevel)) {
        return it;
      }
    }
    if (symbol != null) {
      for (var it in all) {
        if (it.testCode == testCode && matchVoltage(it.voltageLevel, voltageLevel)) {
          return it;
        }
      }
    }
    return null;
  }

  /// Tìm Tiêu chuẩn Kiểm định TT02 phù hợp nhất theo testCode, cấp điện áp và ký hiệu phép đo (symbol)
  static TT02ItemModel? getTT02ByTestCode(String testCode, {String voltageLevel = 'ALL', String? symbol}) {
    final all = getAllTT02();
    for (var it in all) {
      if (it.testCode == testCode && (symbol == null || it.symbol == symbol) && it.voltageLevel == voltageLevel) {
        return it;
      }
    }
    for (var it in all) {
      if (it.testCode == testCode && (symbol == null || it.symbol == symbol) && matchVoltage(it.voltageLevel, voltageLevel)) {
        return it;
      }
    }
    if (symbol != null) {
      for (var it in all) {
        if (it.testCode == testCode && matchVoltage(it.voltageLevel, voltageLevel)) {
          return it;
        }
      }
    }
    return null;
  }

  /// Hàm so sánh giá trị số với ngưỡng tiêu chuẩn
  /// Hỗ trợ kiểm tra độ lớn sai số (|val| <= threshold) đối với các phép đo sai số phần trăm
  static bool? compareValue(double val, String? compare, dynamic threshold, dynamic minVal, dynamic maxVal, {bool isBilateral = false}) {
    if (compare == null) return null;
    final comp = compare.trim();
    if (comp == 'between' && minVal != null && maxVal != null) {
      final minN = (minVal is num) ? minVal.toDouble() : double.tryParse(minVal.toString());
      final maxN = (maxVal is num) ? maxVal.toDouble() : double.tryParse(maxVal.toString());
      if (minN != null && maxN != null) {
        return val >= minN && val <= maxN;
      }
    }
    if (threshold != null) {
      final thN = (threshold is num) ? threshold.toDouble() : double.tryParse(threshold.toString());
      if (thN != null) {
        // Đối với sai số có thể âm hoặc dương (hoặc kiểm tra trị tuyệt đối khi ngưỡng > 0 và giá trị âm)
        final effectiveVal = (isBilateral || (val < 0 && thN > 0)) ? val.abs() : val;
        if (comp == '≤' || comp == '<=') return effectiveVal <= thN;
        if (comp == '≥' || comp == '>=') return effectiveVal >= thN;
        if (comp == '<') return effectiveVal < thN;
        if (comp == '>') return effectiveVal > thN;
        if (comp == '=') return (val - thN).abs() < 1e-6;
      }
    }
    return null;
  }

  /// 1️⃣ ĐÁNH GIÁ THEO TIÊU CHUẨN (TCVN / IEC)
  static StandardEvalResult evaluateStandard(String testCode, double measuredValue, {String voltageLevel = 'ALL', String? symbol}) {
    final item = getStandardByTestCode(testCode, voltageLevel: voltageLevel, symbol: symbol);
    if (item == null) {
      return const StandardEvalResult(
        isPass: true,
        statusText: "Chưa có quy định",
        limitText: "Chưa cấu hình tiêu chuẩn cho phép đo này",
        standardText: "",
        recommendation: "",
      );
    }

    final isErrorTest = testCode.toLowerCase().contains('error') || testCode.toLowerCase().contains('ratio');
    final pass = compareValue(measuredValue, item.compare, item.value, item.min, item.max, isBilateral: isErrorTest);
    if (pass == null) {
      return StandardEvalResult(
        isPass: true,
        statusText: "Tham chiếu",
        limitText: item.limit.isNotEmpty ? item.limit : (item.note ?? ''),
        standardText: item.standard,
        recommendation: item.recommendation,
        item: item,
      );
    }

    return StandardEvalResult(
      isPass: pass,
      statusText: pass ? "Đạt" : "Không đạt",
      limitText: item.limit.isNotEmpty ? item.limit : "${item.symbol ?? ''} ${item.compare ?? ''} ${item.value ?? ''} ${item.unit ?? ''}".trim(),
      standardText: item.standard,
      recommendation: item.recommendation,
      item: item,
    );
  }

  /// 2️⃣ ĐÁNH GIÁ TIÊU CHUẨN CBM (4 MỨC TÌNH TRẠNG)
  static CbmEvalResult evaluateCbm(String testCode, double measuredValue, {String voltageLevel = 'ALL', String? symbol}) {
    final item = getCbmByTestCode(testCode, voltageLevel: voltageLevel, symbol: symbol);
    if (item == null) {
      return const CbmEvalResult(
        level: 1,
        levelName: "Chưa có quy định",
        conclusion: "N/A",
        rangeText: "",
        recommendation: "",
      );
    }

    final levels = item.levels;
    if (levels != null) {
      for (int i = 1; i <= 4; i++) {
        final lData = levels['level$i'];
        if (lData is Map) {
          final comp = lData['compare'];
          final val = lData['value'];
          final mn = lData['min'];
          final mx = lData['max'];
          final concl = lData['conclusion']?.toString() ?? '';

          final match = compareValue(measuredValue, comp, val, mn, mx);
          if (match == true) {
            String lName = "Mức $i ($concl)";
            String rText = "";
            if (comp == 'between' && mn != null && mx != null) {
              rText = "$mn ~ $mx ${item.unit ?? ''}".trim();
            } else if (comp != null && val != null) {
              rText = "$comp $val ${item.unit ?? ''}".trim();
            }
            return CbmEvalResult(
              level: i,
              levelName: lName,
              conclusion: concl,
              rangeText: rText,
              recommendation: item.recommendation,
              item: item,
            );
          }
        }
      }
    }

    return CbmEvalResult(
      level: 1,
      levelName: "Tham chiếu",
      conclusion: "Tham chiếu",
      rangeText: item.good,
      recommendation: item.recommendation,
      item: item,
    );
  }

  /// 3️⃣ ĐÁNH GIÁ KIỂM ĐỊNH TT02
  static TT02EvalResult evaluateTT02(String testCode, double measuredValue, {String voltageLevel = 'ALL', String? symbol}) {
    final item = getTT02ByTestCode(testCode, voltageLevel: voltageLevel, symbol: symbol);
    if (item == null) {
      return const TT02EvalResult(
        isPass: true,
        statusText: "Chưa có quy định",
        limitText: "Chưa cấu hình kiểm định TT02 cho phép đo này",
        periodText: "",
        standardText: "",
        recommendation: "",
      );
    }

    final isErrorTest = testCode.toLowerCase().contains('error') || testCode.toLowerCase().contains('ratio');
    final pass = compareValue(measuredValue, item.compare, item.value, item.min, item.max, isBilateral: isErrorTest);
    if (pass == null) {
      return TT02EvalResult(
        isPass: true,
        statusText: "Tham chiếu",
        limitText: item.limit,
        periodText: item.period,
        standardText: item.standard,
        recommendation: item.recommendation,
        item: item,
      );
    }

    return TT02EvalResult(
      isPass: pass,
      statusText: pass ? "Đạt" : "Không đạt",
      limitText: item.limit.isNotEmpty ? item.limit : "${item.symbol ?? ''} ${item.compare ?? ''} ${item.value ?? ''} ${item.unit ?? ''}".trim(),
      periodText: item.period,
      standardText: item.standard,
      recommendation: item.recommendation,
      item: item,
    );
  }

  /// Xác định cấp độ CBM (1, 2, 3, 4) cho một giá trị đo
  static int evaluateCbmLevel(CbmItemModel? item, double measuredValue) {
    if (item?.levels == null) return 1;
    final levels = item!.levels!;
    for (int i = 1; i <= 4; i++) {
      final lData = levels['level$i'];
      if (lData is Map) {
        final comp = lData['compare'];
        final val = lData['value'];
        final mn = lData['min'];
        final mx = lData['max'];
        if (compareValue(measuredValue, comp, val, mn, mx) == true) {
          return i;
        }
      }
    }
    return 1;
  }
}
