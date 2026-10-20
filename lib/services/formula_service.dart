import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:function_tree/function_tree.dart';
import 'package:hive/hive.dart';

import 'package:flutter/services.dart' show rootBundle;

class FormulaModel {
  final String testId;
  final String? groupCode;
  final String? method;
  final String name;
  final List<String> inputs;
  final String formula;
  final String unit;

  FormulaModel({
    required this.testId,
    this.groupCode,
    this.method,
    required this.name,
    required this.inputs,
    required this.formula,
    required this.unit,
  });

  factory FormulaModel.fromJson(Map<String, dynamic> json) {
    return FormulaModel(
      testId: json['test_id'] ?? '',
      groupCode: json['group_code'] ?? json['groupCode'],
      method: json['method'],
      name: json['name'] ?? '',
      inputs: json['inputs'] != null ? List<String>.from(json['inputs']) : [],
      formula: json['formula'] ?? '',
      unit: json['unit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'test_id': testId,
        if (groupCode != null) 'group_code': groupCode,
        if (method != null) 'method': method,
        'name': name,
        'inputs': inputs,
        'formula': formula,
        'unit': unit,
      };
}

class FormulaService {
  static const String boxName = 'formulasBox';

  /// Khởi tạo Box chứa công thức và nạp mặc định nếu rỗng hoặc phiên bản cũ
  static Future<void> init() async {
    final box = await Hive.openBox(boxName);
    if (box.isEmpty || box.length < 35) {
      await loadDefaultFormulas();
    }
  }

  /// Nạp công thức mặc định từ assets
  static Future<void> loadDefaultFormulas() async {
    try {
      String content = await rootBundle.loadString('assets/formulas.json');
      List<dynamic> parsedJson = jsonDecode(content);
      final box = Hive.box(boxName);
      await box.clear();

      for (var item in parsedJson) {
        FormulaModel model = FormulaModel.fromJson(Map<String, dynamic>.from(item));
        await box.put(model.testId, model.toJson());
      }
    } catch (e) {
      // Catch fallback
    }
  }

  /// Khôi phục công thức về mặc định gốc
  static Future<String> resetToDefault() async {
    await loadDefaultFormulas();
    return "Đã khôi phục Công thức về dữ liệu mặc định ban đầu.";
  }

  /// Nạp file JSON cấu hình công thức từ thiết bị
  static Future<String?> importFormulasFromFile() async {
    try {
      // Cho phép chọn file có đuôi json
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        File file = File(result.files.single.path!);
        String content = await file.readAsString();
        
        // Parse JSON
        var parsedJson = jsonDecode(content);
        if (parsedJson is List) {
          final box = Hive.box(boxName);
          await box.clear(); // Xoá công thức cũ, nạp cái mới nghen

          for (var item in parsedJson) {
            FormulaModel model = FormulaModel.fromJson(item);
            await box.put(model.testId, model.toJson());
          }
          return "Nạp công thức cái rẹt xong gòi nghen, hệ thống đã up to date!";
        } else {
          return "Cái file JSON ni cấu trúc không đúng zồi, phải là một mảng (List) các công thức chớ.";
        }
      } else {
        return "Bác chưa chọn file mô hết.";
      }
    } catch (e) {
      return "Lỗi nạp file: $e";
    }
  }

  /// Lấy danh sách công thức đang có trong máy
  static List<FormulaModel> getAllFormulas() {
    final box = Hive.box(boxName);
    return box.values.map((e) => FormulaModel.fromJson(Map<String, dynamic>.from(e))).toList();
  }

  /// Lấy danh sách các công thức thuộc một nhóm (ví dụ: 'MC_R_tx', 'DCL_R_tx', 'DTD_R_tx', 'REC_R_tx', 'MBA_Unbalance')
  static List<FormulaModel> getFormulasByGroup(String groupCode) {
    final all = getAllFormulas();
    return all.where((f) => f.groupCode == groupCode || f.testId.startsWith('${groupCode}_')).toList();
  }

  /// Lấy cấu hình một công thức cụ thể theo ID, có fallback theo groupCode nếu testId đại diện cho cả nhóm
  static FormulaModel? getFormulaById(String testId) {
    final box = Hive.box(boxName);
    final data = box.get(testId);
    if (data != null) {
      return FormulaModel.fromJson(Map<String, dynamic>.from(data));
    }
    // Fallback: nếu gọi theo groupCode (ví dụ MC_R_tx), trả về công thức đầu tiên (mặc định) của nhóm đó
    final groupList = getFormulasByGroup(testId);
    if (groupList.isNotEmpty) {
      return groupList.first;
    }
    return null;
  }

  /// Tính toán kết quả bằng Function Tree
  /// Tham số [variables] là một Map chứa giá trị của các biến đầu vào, ví dụ:
  /// {'R_do': 1000, 'T_do': 30, 'T_tc': 75}
  static double calculate(String formulaStr, Map<String, num> variables) {
    try {
      // function_tree hỗ trợ diễn dịch chuỗi thành giá trị toán học
      // Ví dụ: "R_do * pow(1.5, (T_do - T_tc)/10)".interpret() ... wait.
      // Tuy nhiên, function_tree package cung cấp String.interpret() để chạy ngay,
      // hoặc MultiVariableFunction(các biến) nếu build hàm phức tạp.
      // Dễ nhất là thay (replace) các tên biến bằng giá trị số và interpret trực tiếp.

      String expression = formulaStr;
      
      // Sắp xếp các biến theo độ dài tên giảm dần để tránh thay nhầm (VD: 'T_do' không đè 'T_do_1')
      var keys = variables.keys.toList();
      keys.sort((a, b) => b.length.compareTo(a.length));

      for (var key in keys) {
        expression = expression.replaceAll(key, variables[key].toString());
      }

      // Có thể chạy thẳng interpret trên chuỗi đã ráp số liệu
      final result = expression.interpret();
      return result.toDouble();
    } catch (e) {
      // Quăng ra lỗi rõ ràng để anh em biết đường sửa file config
      throw Exception("Hông tính được zồi Đại ca: ${e.toString()}");
    }
  }

  /// Tính toán độ lệch % cho từng pha theo phương pháp công thức được chọn
  /// Hỗ trợ cả 3 phương pháp:
  /// - So với R_nsx (hoặc so với R_min nếu chưa nhập R_nsx)
  /// - So với R_min
  /// - So với R_avg
  static Map<String, double> calculatePhaseDeviations({
    required Map<String, double> phaseValues,
    String? formulaId,
    double? rNsx,
  }) {
    if (phaseValues.isEmpty) return {};
    final validEntries = phaseValues.entries.where((e) => e.value > 0).toList();
    if (validEntries.isEmpty) return {};

    final vals = validEntries.map((e) => e.value).toList();
    final minR = vals.reduce((a, b) => a < b ? a : b);
    final avgR = vals.reduce((a, b) => a + b) / vals.length;

    final Map<String, double> devs = {};
    final fId = (formulaId ?? '').toLowerCase();

    if (fId.contains('min')) {
      if (minR > 0) {
        for (var e in validEntries) {
          devs[e.key] = ((e.value - minR) / minR) * 100.0;
        }
      }
    } else if (fId.contains('avg') ||
        (!fId.contains('nsx') &&
            !fId.contains('min') &&
            (rNsx == null || rNsx <= 0) &&
            fId.contains('unbalance'))) {
      if (avgR > 0) {
        for (var e in validEntries) {
          devs[e.key] = ((e.value - avgR).abs() / avgR) * 100.0;
        }
      }
    } else {
      // Mặc định hoặc so với R_nsx
      if (rNsx != null && rNsx > 0) {
        for (var e in validEntries) {
          final diff = e.value - rNsx;
          // Đối với điện trở tiếp xúc, nếu nhỏ hơn hoặc bằng R_nsx thì đạt hoàn toàn (0.0%)
          // Nếu lớn hơn R_nsx thì tính phần trăm vượt
          devs[e.key] = diff > 0 ? (diff / rNsx) * 100.0 : 0.0;
        }
      } else if (minR > 0) {
        // Fallback khi chưa nhập R_nsx: tính so với giá trị nhỏ nhất giữa các pha
        for (var e in validEntries) {
          devs[e.key] = ((e.value - minR) / minR) * 100.0;
        }
      }
    }
    return devs;
  }
}

