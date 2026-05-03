import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/test_record.dart';

class ExportService {
  /// Hàm dựng (build) chuỗi Text bám sát nguyên bản form tĩnh được yêu cầu
  static String buildTextContent(TestRecord record) {
    final date = DateFormat('dd/MM/yyyy').format(record.timestamp);
    final time = DateFormat('HH:mm:ss').format(record.timestamp);
    
    final StringBuffer sb = StringBuffer();
    // Format đúng theo yêu cầu (Gồm 30 khoảng trắng lùi vào)
    sb.writeln('MTE-LAB Cal-Notes                              $date');
    sb.writeln('----------------------------------------------------------');
    sb.writeln('Tiêu đề: ${record.title} - $time');
    
    for (var calc in record.calculations) {
      sb.writeln('Tính toán: ${calc.name}');
      
      // Nối chuỗi thông số đo định dạng [Key=Value, ...]
      final List<String> inputStrs = [];
      calc.inputs.forEach((key, value) {
        inputStrs.add('$key=$value');
      });
      sb.writeln('Thông số đo: [${inputStrs.join(', ')}]');
      
      sb.writeln('Kết quả tính toán: ${calc.result.toStringAsFixed(3)} ${calc.unit}');
      
      // Đường dẫn hình ảnh nếu có
      if (record.imagePaths.isNotEmpty) {
        // Có thể thay thế bằng đường dẫn thực nếu muốn, nhưng form gốc là `/image/`
        sb.writeln('Hình ảnh : ${record.imagePaths.join(", ")}');
      } else {
        sb.writeln('Hình ảnh : '); // Nếu không có hình thì bỏ trống
      }
      sb.writeln(''); // Dòng trống cách phép tính tiếp theo
    }
    
    return sb.toString().trim();
  }

  /// Lưu dữ liệu vào file Text thuần và trả về đường dẫn
  static Future<String?> exportRecordToTxt(TestRecord record) async {
    if (kIsWeb) return null;

    try {
      final String content = buildTextContent(record);

      // Lưu file vào thư mục App Documents
      final directory = await getApplicationDocumentsDirectory();
      
      // Tạo tên file không có ký tự đặc biệt
      final fileNameTitle = record.title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').replaceAll(' ', '_');
      final fileName = 'MTE_CalNote_${fileNameTitle}_${record.timestamp.millisecondsSinceEpoch}.txt';
      final String filePath = '${directory.path}/$fileName';
      
      final File file = File(filePath);
      await file.writeAsString(content, flush: true);
      
      return filePath;
    } catch (e) {
      debugPrint("Lỗi xuất file TXT: $e");
      return null;
    }
  }

  /// Khắc phục lỗi Zalo: Chia sẻ TRỰC TIẾP định dạng chữ (Text message), chứ không gửi đính kèm file
  static Future<void> shareTxtContent(TestRecord record) async {
    try {
      final String content = buildTextContent(record);
      // Chia sẻ trực tiếp dạng TextBox, giúp paste thẳng vào tin nhắn Zalo/FB
      await Share.share(content, subject: 'MTE-LAB Cal-Notes Record');
    } catch (e) {
      debugPrint("Lỗi chia sẻ đoạn text: $e");
    }
  }
}
