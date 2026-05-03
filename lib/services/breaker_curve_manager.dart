import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/breaker_curve.dart';

class BreakerCurveManager {
  static const String boxName = 'breakerCurvesBox';

  static Future<void> init() async {
    final box = await Hive.openBox<String>(boxName);

    // Tự động nạp đặc tuyến chuẩn IEC 60898-1 nếu chưa có bất kỳ dữ liệu nào
    if (box.isEmpty) {
      final iecTypeB = BreakerCurve(
        id: 'IEC_STD_TypeB',
        brand: 'IEC Standard',
        series: '60898-1',
        type: 'B',
        points: [
          CurvePoint(k: 1.0, tMin: 3600, tMax: 10000),
          CurvePoint(k: 1.13, tMin: 3600, tMax: 10000),
          CurvePoint(k: 1.45, tMin: 1, tMax: 3600),
          CurvePoint(k: 2.55, tMin: 1, tMax: 60),
          CurvePoint(k: 3.0, tMin: 0.1, tMax: 4.0),
          CurvePoint(k: 5.0, tMin: 0.01, tMax: 0.1),
          CurvePoint(k: 10.0, tMin: 0.005, tMax: 0.1),
        ],
      );

      final iecTypeC = BreakerCurve(
        id: 'IEC_STD_TypeC',
        brand: 'IEC Standard',
        series: '60898-1',
        type: 'C',
        points: [
          CurvePoint(k: 1.0, tMin: 3600, tMax: 10000),
          CurvePoint(k: 1.13, tMin: 3600, tMax: 10000),
          CurvePoint(k: 1.45, tMin: 1, tMax: 3600),
          CurvePoint(k: 2.55, tMin: 1, tMax: 60),
          CurvePoint(k: 5.0, tMin: 0.1, tMax: 4.0),
          CurvePoint(k: 10.0, tMin: 0.01, tMax: 0.1),
          CurvePoint(k: 20.0, tMin: 0.005, tMax: 0.1),
        ],
      );

      final iecTypeD = BreakerCurve(
        id: 'IEC_STD_TypeD',
        brand: 'IEC Standard',
        series: '60898-1',
        type: 'D',
        points: [
          CurvePoint(k: 1.0, tMin: 3600, tMax: 10000),
          CurvePoint(k: 1.13, tMin: 3600, tMax: 10000),
          CurvePoint(k: 1.45, tMin: 1, tMax: 3600),
          CurvePoint(k: 2.55, tMin: 1, tMax: 60),
          CurvePoint(k: 10.0, tMin: 0.1, tMax: 4.0),
          CurvePoint(k: 20.0, tMin: 0.01, tMax: 0.1),
          CurvePoint(k: 50.0, tMin: 0.005, tMax: 0.1),
        ],
      );

      await box.put(iecTypeB.id, jsonEncode(iecTypeB.toJson()));
      await box.put(iecTypeC.id, jsonEncode(iecTypeC.toJson()));
      await box.put(iecTypeD.id, jsonEncode(iecTypeD.toJson()));
    }
  }

  /// Nạp danh sách
  static List<BreakerCurve> getAllCurves() {
    final box = Hive.box<String>(boxName);
    return box.values.map((v) => BreakerCurve.fromJson(jsonDecode(v))).toList();
  }

  /// Tìm Curve theo ID
  static BreakerCurve? getCurveById(String id) {
    final box = Hive.box<String>(boxName);
    final jsonStr = box.get(id);
    if (jsonStr != null) {
      return BreakerCurve.fromJson(jsonDecode(jsonStr));
    }
    return null;
  }

  /// Lưu Curve
  static Future<void> saveCurve(BreakerCurve curve) async {
    final box = Hive.box<String>(boxName);
    await box.put(curve.id, jsonEncode(curve.toJson()));
  }

  /// Xoá Curve
  static Future<void> deleteCurve(String id) async {
    final box = Hive.box<String>(boxName);
    await box.delete(id);
  }

  /// Import JSON File (dành cho người làm sẵn file json trên máy tính)
  static Future<String> importJson() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();

        // Kiểm tra xem là mảng hay đối tượng lẻ
        var parsed = jsonDecode(content);
        if (parsed is List) {
          for (var item in parsed) {
            final curve = BreakerCurve.fromJson(item);
            await saveCurve(curve);
          }
          return "Đã import thành công ${parsed.length} đặc tuyến!";
        } else if (parsed is Map<String, dynamic>) {
          final curve = BreakerCurve.fromJson(parsed);
          await saveCurve(curve);
          return "Đã import đặc tuyến ${curve.brand} - ${curve.series} thành công!";
        } else {
           return "File JSON không hợp lệ.";
        }
      }
      return "Chưa chọn file.";
    } catch (e) {
      return "Lỗi import: $e";
    }
  }

  /// LOG-LOG MAPPING UTILITY
  /// Nội suy Log-Log để tìm t ứng với k
  /// t = 10^( log(t1) + (log(k) - log(k1))/(log(k2) - log(k1)) * (log(t2) - log(t1)) )
  static double _interpolateLogLog(double k, double k1, double t1, double k2, double t2) {
    if (k <= k1) return t1;
    if (k >= k2) return t2;
    if (t1 <= 0 || t2 <= 0 || k1 <= 0 || k2 <= 0) return t1; // Bypass nếu log âm
    
    double logK = log(k) / ln10;
    double logK1 = log(k1) / ln10;
    double logK2 = log(k2) / ln10;
    double logT1 = log(t1) / ln10;
    double logT2 = log(t2) / ln10;

    double ratio = (logK - logK1) / (logK2 - logK1);
    double logT = logT1 + ratio * (logT2 - logT1);
    
    return pow(10, logT).toDouble();
  }

  /// Tính toán ngưỡng [t_min, t_max] của đặc tuyến tại một bội số k cho trước
  static Map<String, double> evaluateTripTimeLimits(BreakerCurve curve, double k) {
    if (curve.points.isEmpty) {
      return {'tMin': 0, 'tMax': 0};
    }
    
    // Đảm bảo points được sort theo k tăng dần
    List<CurvePoint> pts = List.from(curve.points)..sort((a, b) => a.k.compareTo(b.k));

    // Nếu k nhỏ hơn điểm min, trả về giới hạn vô hạn (hoặc tMin của điểm đầu)
    if (k <= pts.first.k) {
       return {'tMin': pts.first.tMin, 'tMax': pts.first.tMax};
    }
    // Nếu k lớn hơn điểm max, trả về điểm cuối
    if (k >= pts.last.k) {
       return {'tMin': pts.last.tMin, 'tMax': pts.last.tMax};
    }

    // Tìm 2 điểm bao quanh k
    for (int i = 0; i < pts.length - 1; i++) {
       if (k >= pts[i].k && k <= pts[i+1].k) {
          CurvePoint p1 = pts[i];
          CurvePoint p2 = pts[i+1];

          double tMin = _interpolateLogLog(k, p1.k, p1.tMin, p2.k, p2.tMin);
          double tMax = _interpolateLogLog(k, p1.k, p1.tMax, p2.k, p2.tMax);
          
          return {'tMin': tMin, 'tMax': tMax};
       }
    }
    return {'tMin': 0, 'tMax': 0};
  }

  /// Hiệu chỉnh quá tải nhiệt theo nhiệt độ (Tuỳ chọn đơn giản: shift đường cong đi X%)
  /// Thường cứ lệch 10C thì dịch đi độ nhạy ~5% (cái này do tham chiếu hãng)
  static double applyTempCorrection(double iDm, double tEnv, double tRef) {
    if (tEnv == tRef) return iDm;
    // Quy tắc nội suy nhiệt năng tương đối
    // DeltaT = T_env - T_ref
    double deltaT = tEnv - tRef;
    // Mỗi 10 độ C lệnh thì Idm giảm/tăng khoảng 5% (hệ số 0.005 mỗi độ C)
    double shiftRatio = 1.0 - (deltaT * 0.005);
    return iDm * shiftRatio;
  }
}
