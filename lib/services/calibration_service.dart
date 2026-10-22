import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:hive/hive.dart';

/// Điểm kiểm chuẩn trong dải đo
class CalibrationPointModel {
  final double baseValue;
  final double deviceValue;
  final double correction;

  const CalibrationPointModel({
    required this.baseValue,
    required this.deviceValue,
    required this.correction,
  });

  factory CalibrationPointModel.fromJson(Map<String, dynamic> json) {
    return CalibrationPointModel(
      baseValue: (json['baseValue'] as num?)?.toDouble() ?? 0.0,
      deviceValue: (json['deviceValue'] as num?)?.toDouble() ?? 0.0,
      correction: (json['correction'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'baseValue': baseValue,
        'deviceValue': deviceValue,
        'correction': correction,
      };
}

/// Dải đo và độ không đảm bảo đo u%
class CalibrationRangeModel {
  final String rangeId;
  final String unit;
  final double min;
  final double max;
  final double uPercent;
  final List<CalibrationPointModel> calibrationPoints;

  const CalibrationRangeModel({
    required this.rangeId,
    required this.unit,
    required this.min,
    required this.max,
    required this.uPercent,
    required this.calibrationPoints,
  });

  factory CalibrationRangeModel.fromJson(Map<String, dynamic> json) {
    var rawPts = json['calibrationPoints'];
    List<CalibrationPointModel> pts = [];
    if (rawPts is List) {
      pts = rawPts
          .map((e) => CalibrationPointModel.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } else if (rawPts is Map) {
      pts = [
        CalibrationPointModel.fromJson(Map<String, dynamic>.from(rawPts))
      ];
    }
    return CalibrationRangeModel(
      rangeId: json['rangeId'] ?? '',
      unit: json['unit'] ?? '',
      min: (json['min'] as num?)?.toDouble() ?? 0.0,
      max: (json['max'] as num?)?.toDouble() ?? 999999.0,
      uPercent: (json['uPercent'] as num?)?.toDouble() ?? 0.0,
      calibrationPoints: pts,
    );
  }

  Map<String, dynamic> toJson() => {
        'rangeId': rangeId,
        'unit': unit,
        'min': min,
        'max': max,
        'uPercent': uPercent,
        'calibrationPoints': calibrationPoints.map((e) => e.toJson()).toList(),
      };
}

/// Thang đo (Scale) của thiết bị
class CalibrationScaleModel {
  final String scaleId;
  final String scaleName;
  final List<CalibrationRangeModel> ranges;

  const CalibrationScaleModel({
    required this.scaleId,
    required this.scaleName,
    required this.ranges,
  });

  factory CalibrationScaleModel.fromJson(Map<String, dynamic> json) {
    var rawRanges = json['ranges'] as List<dynamic>? ?? [];
    return CalibrationScaleModel(
      scaleId: json['scaleId'] ?? '',
      scaleName: json['scaleName'] ?? '',
      ranges: rawRanges
          .map((e) => CalibrationRangeModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'scaleId': scaleId,
        'scaleName': scaleName,
        'ranges': ranges.map((e) => e.toJson()).toList(),
      };
}

/// Phương tiện / Thiết bị thí nghiệm đã hiệu chuẩn
class CalibratedEquipmentModel {
  final String id;
  final String name;
  final String type;
  final String serial;
  final List<String> targetItem;
  final List<String> applicableTests;
  final double k;
  final String confidenceLevel;
  final List<CalibrationScaleModel> scales;

  const CalibratedEquipmentModel({
    required this.id,
    required this.name,
    required this.type,
    required this.serial,
    required this.targetItem,
    required this.applicableTests,
    required this.k,
    required this.confidenceLevel,
    required this.scales,
  });

  factory CalibratedEquipmentModel.fromJson(Map<String, dynamic> json) {
    var rawScales = json['scales'] as List<dynamic>? ?? [];
    return CalibratedEquipmentModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      type: json['type'] ?? '',
      serial: json['serial'] ?? '',
      targetItem: (json['targetItem'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      applicableTests: (json['applicableTests'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      k: (json['k'] as num?)?.toDouble() ?? 2.0,
      confidenceLevel: json['confidenceLevel'] ?? '95%',
      scales: rawScales
          .map((e) => CalibrationScaleModel.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'type': type,
        'serial': serial,
        'targetItem': targetItem,
        'applicableTests': applicableTests,
        'k': k,
        'confidenceLevel': confidenceLevel,
        'scales': scales.map((e) => e.toJson()).toList(),
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalibratedEquipmentModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Đánh giá kết luận sự phù hợp theo ISO 17025 / ILAC-G8
enum UncertaintyVerdict {
  pass,        // Đạt chắc chắn (Pass with high confidence >= 95%)
  warningRisk, // Đạt danh nghĩa nhưng có rủi ro biên (Guard-band Warning)
  fail         // Không đạt (Fail with high confidence)
}

/// Kết quả tính toán kèm Độ không đảm bảo đo
class UncertaintyResult {
  final double measuredValue;      // X_đo
  final double correction;         // Số hiệu chính C
  final double correctedValue;      // X_hc = X_đo + C
  final double uPercent;           // u%
  final double expandedUncertainty;// U = (u% / 100) * X_hc
  final double k;                  // k = 2
  final String confidenceLevel;    // P = 95%
  final double minBound;           // X_hc - U
  final double maxBound;           // X_hc + U
  final String unit;
  final CalibratedEquipmentModel equipment;
  final CalibrationRangeModel? range;

  // --- BƯỚC 2: CHỈ SỐ QUY CHUẨN DẪN XUẤT (DERIVED RESULT ĐỂ ĐỐI CHIẾU TIÊU CHUẨN) ---
  final String? derivedName;          // Tên chỉ số: VD "Sai số f_hc" hoặc "R_qd (75°C)"
  final double? derivedCorrected;     // Giá trị quy chuẩn sau HC: VD +2.014 (%)
  final double? derivedMinBound;      // Cận dưới dải quy chuẩn: VD +1.943 (%)
  final double? derivedMaxBound;      // Cận trên dải quy chuẩn: VD +2.085 (%)
  final String? derivedUnit;          // Đơn vị quy chuẩn: VD "%" hoặc "mΩ"
  final double? standardLimit;        // Giới hạn tiêu chuẩn: VD 0.5 (%) hoặc 100 (µΩ)
  final bool isUpperBound;            // true nếu quy định <= limit, false nếu >= limit

  UncertaintyResult({
    required this.measuredValue,
    required this.correction,
    required this.correctedValue,
    required this.uPercent,
    required this.expandedUncertainty,
    required this.k,
    required this.confidenceLevel,
    required this.minBound,
    required this.maxBound,
    required this.unit,
    required this.equipment,
    this.range,
    this.derivedName,
    this.derivedCorrected,
    this.derivedMinBound,
    this.derivedMaxBound,
    this.derivedUnit,
    this.standardLimit,
    this.isUpperBound = true,
  });

  /// Tạo bản sao kèm kết quả dẫn xuất Bước 2 để đối chiếu tiêu chuẩn
  UncertaintyResult withDerived({
    required String derivedName,
    required double derivedCorrected,
    required double derivedMinBound,
    required double derivedMaxBound,
    required String derivedUnit,
    double? standardLimit,
    bool isUpperBound = true,
  }) {
    return UncertaintyResult(
      measuredValue: measuredValue,
      correction: correction,
      correctedValue: correctedValue,
      uPercent: uPercent,
      expandedUncertainty: expandedUncertainty,
      k: k,
      confidenceLevel: confidenceLevel,
      minBound: minBound,
      maxBound: maxBound,
      unit: unit,
      equipment: equipment,
      range: range,
      derivedName: derivedName,
      derivedCorrected: derivedCorrected,
      derivedMinBound: derivedMinBound,
      derivedMaxBound: derivedMaxBound,
      derivedUnit: derivedUnit,
      standardLimit: standardLimit ?? this.standardLimit,
      isUpperBound: isUpperBound,
    );
  }

  /// Đánh giá sự phù hợp ILAC-G8 tự động
  UncertaintyVerdict? evaluateStandard([double? customLimit, bool? customIsUpperBound]) {
    final limit = customLimit ?? standardLimit;
    if (limit == null) return null;
    final upper = customIsUpperBound ?? isUpperBound;

    final valToCheck = derivedCorrected ?? correctedValue;
    final minToCheck = derivedMinBound ?? minBound;
    final maxToCheck = derivedMaxBound ?? maxBound;
    final unitToCheck = derivedUnit ?? unit;
    final nameToCheck = derivedName ?? '';

    // Kiểm tra sai số 2 phía (VD: sai số tỷ số |f| <= 0.5%)
    if (unitToCheck == '%' &&
        (nameToCheck.toLowerCase().contains('sai số') ||
            nameToCheck.toLowerCase().contains('f'))) {
      double absLim = limit.abs();
      if (minToCheck >= -absLim && maxToCheck <= absLim) {
        return UncertaintyVerdict.pass;
      } else if (valToCheck >= -absLim && valToCheck <= absLim) {
        return UncertaintyVerdict.warningRisk;
      } else {
        return UncertaintyVerdict.fail;
      }
    }

    // Kiểm tra 1 phía (<= limit hoặc >= limit)
    if (upper) {
      if (maxToCheck <= limit) {
        return UncertaintyVerdict.pass;
      } else if (valToCheck <= limit) {
        return UncertaintyVerdict.warningRisk;
      } else {
        return UncertaintyVerdict.fail;
      }
    } else {
      if (minToCheck >= limit) {
        return UncertaintyVerdict.pass;
      } else if (valToCheck >= limit) {
        return UncertaintyVerdict.warningRisk;
      } else {
        return UncertaintyVerdict.fail;
      }
    }
  }

  /// Đánh giá sự phù hợp với ngưỡng giới hạn tiêu chuẩn (tương thích ngược)
  UncertaintyVerdict evaluate(double limit, {bool isUpperBound = true}) {
    return evaluateStandard(limit, isUpperBound) ??
        (isUpperBound
            ? (maxBound <= limit
                ? UncertaintyVerdict.pass
                : (correctedValue <= limit
                    ? UncertaintyVerdict.warningRisk
                    : UncertaintyVerdict.fail))
            : (minBound >= limit
                ? UncertaintyVerdict.pass
                : (correctedValue >= limit
                    ? UncertaintyVerdict.warningRisk
                    : UncertaintyVerdict.fail)));
  }

  String getVerdictMessage(double limit, {bool isUpperBound = true}) {
    final v = evaluate(limit, isUpperBound: isUpperBound);
    switch (v) {
      case UncertaintyVerdict.pass:
        return "ĐẠT (Độ tin cậy ≥ 95%)";
      case UncertaintyVerdict.warningRisk:
        return "CẢNH BÁO: Rủi ro biên (Dải sai số chạm/vượt ngưỡng $limit)";
      case UncertaintyVerdict.fail:
        return "KHÔNG ĐẠT (Vượt giới hạn cho phép)";
    }
  }
}

class CalibrationService {
  static const String boxName = 'calibrationBox';
  static const String settingsKey = 'is_uncertainty_enabled';

  /// Khởi tạo Service, nạp danh sách thiết bị mặc định nếu rỗng hoặc thiếu thiết bị mới
  static Future<void> init() async {
    final box = await Hive.openBox(boxName);
    if (box.isEmpty ||
        !box.containsKey('CAL_EQ_08_CT65000') ||
        !box.containsKey('CAL_EQ_09_DILOSF6')) {
      await loadDefaultEquipments();
    }
  }

  /// Trạng thái BẬT / TẮT tính năng ĐKĐBĐ
  static bool get isUncertaintyEnabled {
    final box = Hive.box(boxName);
    return box.get(settingsKey, defaultValue: false) as bool;
  }

  static Future<void> setUncertaintyEnabled(bool enabled) async {
    final box = Hive.box(boxName);
    await box.put(settingsKey, enabled);
  }

  /// Nạp thiết bị hiệu chuẩn mặc định từ assets
  static Future<void> loadDefaultEquipments() async {
    try {
      String content =
          await rootBundle.loadString('assets/calibrated_equipment.json');
      List<dynamic> parsed = jsonDecode(content);
      final box = Hive.box(boxName);

      // Lưu giữ setting hiện tại trước khi clear
      bool curSetting = box.get(settingsKey, defaultValue: false) as bool;
      await box.clear();
      await box.put(settingsKey, curSetting);

      for (var item in parsed) {
        CalibratedEquipmentModel model =
            CalibratedEquipmentModel.fromJson(Map<String, dynamic>.from(item));
        await box.put(model.id, model.toJson());
      }
    } catch (e) {
      // Fallback nếu có lỗi
    }
  }

  /// Khôi phục thiết bị hiệu chuẩn về file gốc mặc định
  static Future<String> resetToDefault() async {
    await loadDefaultEquipments();
    return "Đã khôi phục danh mục Thiết bị hiệu chuẩn về mặc định ban đầu.";
  }

  /// Nhập file JSON thiết bị hiệu chuẩn mới do người dùng tải lên
  static Future<String?> importEquipmentFromFile() async {
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
          bool curSetting = box.get(settingsKey, defaultValue: false) as bool;
          await box.clear();
          await box.put(settingsKey, curSetting);

          for (var item in parsedJson) {
            CalibratedEquipmentModel model = CalibratedEquipmentModel.fromJson(
                Map<String, dynamic>.from(item));
            await box.put(model.id, model.toJson());
          }
          return "Nạp danh mục Thiết bị hiệu chuẩn thành công (${parsedJson.length} thiết bị)!";
        } else {
          return "File JSON không đúng định dạng. Cần là một danh sách (List) các thiết bị.";
        }
      } else {
        return "Bạn chưa chọn file.";
      }
    } catch (e) {
      return "Lỗi nạp file hiệu chuẩn: $e";
    }
  }

  /// Lấy toàn bộ danh sách thiết bị hiệu chuẩn
  static List<CalibratedEquipmentModel> getAllEquipments() {
    final box = Hive.box(boxName);
    List<CalibratedEquipmentModel> list = [];
    for (var key in box.keys) {
      if (key == settingsKey) continue;
      var data = box.get(key);
      if (data is Map) {
        list.add(CalibratedEquipmentModel.fromJson(
            Map<String, dynamic>.from(data)));
      }
    }
    return list;
  }

  /// Lọc các thiết bị đo hỗ trợ phép đo cụ thể (theo testId)
  /// Ví dụ: 'MC_R_tx', 'MBA_R_dc', 'MBA_K_error', 'TITU_Ratio_Error'
  static List<CalibratedEquipmentModel> getEquipmentsForTest(String testId) {
    return getAllEquipments()
        .where((e) => e.applicableTests.contains(testId))
        .toList();
  }

  static String _normalizeUnit(String u) {
    return u
        .trim()
        .toLowerCase()
        .replaceAll('µ', 'u')
        .replaceAll('micro', 'u')
        .replaceAll('milli', 'm')
        .replaceAll('ohm', 'ω')
        .replaceAll('ppmv', 'ppm')
        .replaceAll('°c', 'c');
  }

  /// Tính toán giá trị hiệu chính X_hc và ĐKĐBĐ mở rộng U
  static UncertaintyResult calculateUncertainty({
    required CalibratedEquipmentModel equipment,
    required double measuredValue,
    required String unit,
  }) {
    CalibrationRangeModel? matchedRange;
    CalibrationScaleModel? matchedScale;

    // Tìm thang đo và dải đo tương ứng
    String normTargetUnit = _normalizeUnit(unit);
    for (var scale in equipment.scales) {
      for (var r in scale.ranges) {
        String normRangeUnit = _normalizeUnit(r.unit);
        bool unitMatch = normTargetUnit.isEmpty ||
            normRangeUnit.isEmpty ||
            normRangeUnit == normTargetUnit;
        if (unitMatch && measuredValue >= r.min && measuredValue <= r.max) {
          matchedRange = r;
          matchedScale = scale;
          break;
        }
      }
      if (matchedRange != null) break;
    }

    // Nếu không khớp dải chính xác, chọn dải đầu tiên có đơn vị phù hợp hoặc dải đầu tiên của máy
    if (matchedRange == null && equipment.scales.isNotEmpty) {
      matchedScale = equipment.scales.first;
      if (matchedScale.ranges.isNotEmpty) {
        matchedRange = matchedScale.ranges.first;
      }
    }

    double correction = 0.0;
    double uPercent = matchedRange?.uPercent ?? 0.0;

    if (matchedRange != null && matchedRange.calibrationPoints.isNotEmpty) {
      final points = matchedRange.calibrationPoints;
      // Sắp xếp theo giá trị đo tăng dần
      points.sort((a, b) => a.deviceValue.compareTo(b.deviceValue));

      if (measuredValue <= points.first.deviceValue) {
        correction = points.first.correction;
      } else if (measuredValue >= points.last.deviceValue) {
        correction = points.last.correction;
      } else {
        // Nội suy tuyến tính giữa 2 điểm kiểm chuẩn liền kề
        for (int i = 0; i < points.length - 1; i++) {
          final p1 = points[i];
          final p2 = points[i + 1];
          if (measuredValue >= p1.deviceValue && measuredValue <= p2.deviceValue) {
            double span = p2.deviceValue - p1.deviceValue;
            if (span > 0) {
              double ratio = (measuredValue - p1.deviceValue) / span;
              correction = p1.correction + ratio * (p2.correction - p1.correction);
            } else {
              correction = p1.correction;
            }
            break;
          }
        }
      }
    }

    // Giá trị sau hiệu chính
    double corrected = measuredValue + correction;
    // Độ không đảm bảo đo mở rộng U = (u% / 100) * |X_hc| (với k=2, P=95%)
    double uExpanded = (uPercent / 100.0) * corrected.abs();

    return UncertaintyResult(
      measuredValue: measuredValue,
      correction: correction,
      correctedValue: corrected,
      uPercent: uPercent,
      expandedUncertainty: uExpanded,
      k: equipment.k,
      confidenceLevel: equipment.confidenceLevel,
      minBound: corrected - uExpanded,
      maxBound: corrected + uExpanded,
      unit: unit.isNotEmpty ? unit : (matchedRange?.unit ?? ''),
      equipment: equipment,
      range: matchedRange,
    );
  }
}
