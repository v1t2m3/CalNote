import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/dashboard_screen.dart';
import 'models/test_record.dart';
import 'services/formula_service.dart';
import 'services/breaker_curve_manager.dart';
import 'core/theme/app_theme.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Khởi tạo Hive cho nền tảng Web (tự động dùng IndexedDB, không gọi path_provider)
  await Hive.initFlutter();
  
  // Đăng ký Adapter trước khi mở Box
  Hive.registerAdapter(TestCalculationAdapter());
  Hive.registerAdapter(TestRecordAdapter());
  
  // Khởi tạo FormulaService
  await FormulaService.init();
  await BreakerCurveManager.init();

  usePathUrlStrategy(); // Sử dụng Path URL thay cho Hash URL (#)
  runApp(const MyApp());
}

// Lớp tuỳ chỉnh ScrollBehavior để bỏ đi hiện tượng Overscroll Glow (phát sáng ở cuộn) & Bouncing
class SafariScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    // Trả về child nguyên bản thay vì thêm glowing indicator
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTE-LAB Cal-Notes',
      themeMode: ThemeMode.dark, // Ép dùng luôn Dark Mode cho ứng dụng đo đạc
      darkTheme: AppTheme.darkTheme,
      scrollBehavior: SafariScrollBehavior(), // Gắn ScrollBehavior vào để xoá Overscroll trong Flutter
      home: const DashboardScreen(),
    );
  }
}
