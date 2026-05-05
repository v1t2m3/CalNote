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
  
  // Khởi tạo URL Strategy không cần dấu #
  usePathUrlStrategy(); 

  try {
    // Khởi tạo Hive cho Web
    await Hive.initFlutter();
    
    // Đăng ký Adapter trước khi mở Box
    if (!Hive.isAdapterRegistered(0)) { // Thêm kiểm tra tránh lỗi duplicate register
      Hive.registerAdapter(TestCalculationAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(TestRecordAdapter());
    }
    
    // Khởi tạo Service
    await FormulaService.init();
    await BreakerCurveManager.init();
  } catch (e) {
    debugPrint('Lỗi khởi tạo Hive hoặc Services: $e');
  }

  runApp(const MyApp());
}

// Lớp tuỳ chỉnh ScrollBehavior để bỏ đi hiện tượng Overscroll Glow & Bouncing
class SafariScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildOverscrollIndicator(BuildContext context, Widget child, ScrollableDetails details) {
    return child;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MTE-LAB Cal-Notes',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.dark,
      darkTheme: AppTheme.darkTheme,
      scrollBehavior: SafariScrollBehavior(),
      home: const DashboardScreen(),
    );
  }
}
