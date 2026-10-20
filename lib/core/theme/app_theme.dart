import 'package:flutter/material.dart';

/// Hạt nhân Design System của Cal-Note
/// - Giới hạn 4 màu sắc tương phản cao cho toàn bộ UI
/// - 4 màu chuẩn EVN riêng cho khối Đánh giá CBM
/// - 3 cỡ chữ duy nhất: 18px (Tiêu đề), 14px (Nội dung), 12px (Chú thích)
/// - 4 kiểu chữ phân cấp: IN HOA ĐẬM, Thường Đậm, Thường Regular, Thường Nghiêng
class AppTheme {
  // ==========================================
  // 1. BẢNG MÀU CỐT LÕI (4 MÀU TƯƠNG PHẢN CAO)
  // ==========================================
  /// 1. Màu nền tối sâu khử lóa ngoài trời
  static const Color bgDark = Color(0xFF070D1E);
  /// Nền thẻ Card và Container
  static const Color cardDark = Color(0xFF0E1A38);
  /// Viền thẻ Card
  static const Color cardBorder = Color(0xFF1B2A52);

  /// 2. Màu chữ & số liệu đo lường trắng sáng
  static const Color textWhite = Color(0xFFFFFFFF);

  /// 3. Màu Cam an toàn cao thế (Icon, Nút bấm, Tiêu đề mục lớn, Cảnh báo/Không đạt)
  static const Color accentOrange = Color(0xFFFF7A00);

  /// 4. Màu Xanh lục điện (Chỉ số Đạt, An toàn, Hoàn thành)
  static const Color statusGreen = Color(0xFF00E676);

  // ==========================================
  // 2. BẢNG 4 MÀU ĐÁNH GIÁ THEO TIÊU CHUẨN CBM
  // ==========================================
  static const Color cbmLevel1 = Color(0xFF00E676); // Mức 1 (Tốt) - Xanh lục
  static const Color cbmLevel2 = Color(0xFFFFD600); // Mức 2 (Khá) - Vàng
  static const Color cbmLevel3 = Color(0xFFFF7A00); // Mức 3 (Trung bình) - Cam
  static const Color cbmLevel4 = Color(0xFFFF3B30); // Mức 4 (Xấu) - Đỏ

  /// Lấy màu sắc chuẩn CBM theo mức (1: Xanh lục, 2: Vàng, 3: Cam, 4: Đỏ)
  static Color getCbmColor(int level) {
    switch (level) {
      case 1:
        return cbmLevel1;
      case 2:
        return cbmLevel2;
      case 3:
        return cbmLevel3;
      case 4:
      default:
        return cbmLevel4;
    }
  }

  /// Lấy tên kết luận CBM chuẩn theo mức (1: Tốt, 2: Khá, 3: Trung bình, 4: Xấu)
  static String getCbmConclusion(int level) {
    switch (level) {
      case 1:
        return "Tốt";
      case 2:
        return "Khá";
      case 3:
        return "Trung bình";
      case 4:
      default:
        return "Xấu";
    }
  }

  /// Lấy nhãn đầy đủ Mức + Kết luận CBM (VD: Mức 1 (Tốt))
  static String getCbmLevelName(int level) {
    return "Mức $level (${getCbmConclusion(level)})";
  }

  /// Lấy màu sắc chuẩn CBM theo tên kết luận / mức (Tốt: Xanh lục, Khá: Vàng, TB: Cam, Xấu: Đỏ)
  static Color getCbmColorByConclusion(String conclusion) {
    final lower = conclusion.toLowerCase();
    if (lower.contains('tốt') || lower.contains('1') || lower.contains('good')) {
      return cbmLevel1;
    } else if (lower.contains('khá') || lower.contains('2') || lower.contains('fair')) {
      return cbmLevel2;
    } else if (lower.contains('trung bình') || lower.contains('tb') || lower.contains('3') || lower.contains('average')) {
      return cbmLevel3;
    } else if (lower.contains('xấu') || lower.contains('4') || lower.contains('poor') || lower.contains('không đạt')) {
      return cbmLevel4;
    }
    return cbmLevel1;
  }

  // Tương thích ngược với các biến màu cũ trong codebase
  static const Color myDarkNavy = cardDark;
  static const Color myMedNavy = cardBorder;
  static const Color myBrightBlue = accentOrange;
  static const Color myOrangeAccent = accentOrange;
  static const Color myVeryDarkBg = bgDark;

  // ==========================================
  // 3. QUY CHUẨN 3 CỠ CHỮ DUY NHẤT
  // ==========================================
  static const double fontSizeTitle = 18.0;   // Tiêu đề
  static const double fontSizeBody = 14.0;    // Nội dung / Số liệu
  static const double fontSizeCaption = 12.0; // Chú thích / Ghi chú

  // ==========================================
  // 4. KIỂU CHỮ CHUẨN HÓA (4 PHONG CÁCH)
  // ==========================================
  /// I. Tiêu đề mục lớn: IN HOA + IN ĐẬM (18px, Bold, Orange)
  static const TextStyle titleModuleStyle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: accentOrange,
    letterSpacing: 0.5,
  );

  /// Tiêu đề màn hình AppBar: IN HOA + IN ĐẬM (18px, Bold, White)
  static const TextStyle appBarTitleStyle = TextStyle(
    fontSize: fontSizeTitle,
    fontWeight: FontWeight.bold,
    color: textWhite,
    letterSpacing: 0.8,
  );

  /// II. Tiêu đề mục con (1, 2, 3): Thường/Hoa Nhẹ + In đậm (14px, Bold, Orange)
  static const TextStyle subTitleStyle = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: FontWeight.bold,
    color: accentOrange,
  );

  /// III. Nội dung thông thường: (14px, Regular, White)
  static const TextStyle bodyStyle = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: FontWeight.normal,
    color: textWhite,
  );

  /// Số liệu kết quả đo lường chính: (14px, Bold, White)
  static const TextStyle bodyBoldWhite = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: FontWeight.bold,
    color: textWhite,
  );

  /// Số liệu kết quả đạt: (14px, Bold, Green)
  static const TextStyle bodyBoldPass = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: FontWeight.bold,
    color: statusGreen,
  );

  /// Số liệu kết quả không đạt: (14px, Bold, Orange/Red)
  static const TextStyle bodyBoldFail = TextStyle(
    fontSize: fontSizeBody,
    fontWeight: FontWeight.bold,
    color: cbmLevel4,
  );

  /// IV. Chú thích, căn cứ, ghi chú: Thường + In nghiêng (12px, Italic, White70)
  static const TextStyle captionItalic = TextStyle(
    fontSize: fontSizeCaption,
    fontStyle: FontStyle.italic,
    color: Colors.white70,
  );

  /// Chú thích thông thường: (12px, Regular, White70)
  static const TextStyle captionStyle = TextStyle(
    fontSize: fontSizeCaption,
    fontWeight: FontWeight.normal,
    color: Colors.white70,
  );

  // ==========================================
  // 5. THEMEDATA TOÀN ỨNG DỤNG
  // ==========================================
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: bgDark,
      fontFamily: null, // Sử dụng font sans-serif chuẩn hệ thống thiết bị
      colorScheme: const ColorScheme.dark(
        primary: accentOrange,
        secondary: accentOrange,
        surface: cardDark,
        onPrimary: textWhite,
        onSecondary: textWhite,
        onSurface: textWhite,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cardDark,
        foregroundColor: textWhite,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: appBarTitleStyle,
      ),
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 2,
        margin: const EdgeInsets.symmetric(vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: cardBorder, width: 1.2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentOrange,
          foregroundColor: textWhite,
          minimumSize: const Size.fromHeight(48), // Chuẩn touch target 48px
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(fontSize: fontSizeBody, fontWeight: FontWeight.bold),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentOrange,
          minimumSize: const Size.fromHeight(48),
          side: const BorderSide(color: accentOrange, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          textStyle: const TextStyle(fontSize: fontSizeBody, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardBorder.withValues(alpha: 0.3),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        labelStyle: const TextStyle(color: Colors.white70, fontSize: fontSizeBody),
        hintStyle: const TextStyle(color: Colors.white38, fontSize: fontSizeCaption),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: cardBorder, width: 1.2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: accentOrange, width: 1.8),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold, color: textWhite),
        headlineMedium: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold, color: textWhite),
        headlineSmall: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold, color: textWhite),
        titleLarge: TextStyle(fontSize: fontSizeTitle, fontWeight: FontWeight.bold, color: textWhite),
        titleMedium: TextStyle(fontSize: fontSizeBody, fontWeight: FontWeight.bold, color: textWhite),
        titleSmall: TextStyle(fontSize: fontSizeCaption, fontWeight: FontWeight.bold, color: Colors.white70),
        bodyLarge: TextStyle(fontSize: fontSizeBody, color: textWhite),
        bodyMedium: TextStyle(fontSize: fontSizeBody, color: textWhite),
        bodySmall: TextStyle(fontSize: fontSizeCaption, color: Colors.white70),
        labelLarge: TextStyle(fontSize: fontSizeBody, fontWeight: FontWeight.bold, color: textWhite),
        labelMedium: TextStyle(fontSize: fontSizeCaption, color: Colors.white70),
        labelSmall: TextStyle(fontSize: fontSizeCaption, color: Colors.white60),
      ),
    );
  }
}

