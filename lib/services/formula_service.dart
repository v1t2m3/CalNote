import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:function_tree/function_tree.dart';
import 'package:hive/hive.dart';

class FormulaModel {
  final String testId;
  final String name;
  final List<String> inputs;
  final String formula;
  final String unit;

  FormulaModel({
    required this.testId,
    required this.name,
    required this.inputs,
    required this.formula,
    required this.unit,
  });

  factory FormulaModel.fromJson(Map<String, dynamic> json) {
    return FormulaModel(
      testId: json['test_id'],
      name: json['name'],
      inputs: List<String>.from(json['inputs']),
      formula: json['formula'],
      unit: json['unit'],
    );
  }

  Map<String, dynamic> toJson() => {
        'test_id': testId,
        'name': name,
        'inputs': inputs,
        'formula': formula,
        'unit': unit,
      };
}

class FormulaService {
  static const String boxName = 'formulasBox';

  /// Khởi tạo Box chứa công thức
  static Future<void> init() async {
    await Hive.openBox(boxName);
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

  /// Lấy cấu hình một công thức cụ thể theo ID
  static FormulaModel? getFormulaById(String testId) {
    final box = Hive.box(boxName);
    final data = box.get(testId);
    if (data != null) {
      return FormulaModel.fromJson(Map<String, dynamic>.from(data));
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
}
