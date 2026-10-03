import 'package:flutter/material.dart';
import '../services/formula_service.dart';
import '../services/reference_standard_service.dart';
import 'transformer_calculator_screen.dart';
import '../core/theme/app_theme.dart';
import 'history_screen.dart';
import 'circuit_breaker_screen.dart';
import 'ct_vt_screen.dart';
import 'surge_arrester_screen.dart';
import 'grounding_screen.dart';
import 'digital_relay_screen.dart';
import 'aptomat_screen.dart'; // THÊM IMPORT APTOMAT
import 'insulation_screen.dart'; // THÊM IMPORT ĐO CÁCH ĐIỆN (DAR & PI)
import 'cable_screen.dart'; // THÊM IMPORT CÁP LỰC
import 'reference_standard_screen.dart'; // THÊM IMPORT TRA CỨU TIÊU CHUẨN

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final List<Map<String, dynamic>> _devices = const [
    {'name': 'Máy Biến Áp', 'icon': Icons.flash_on},
    {'name': 'Máy Cắt', 'icon': Icons.electric_moped_outlined},
    {'name': 'Đo Cách Điện (DAR/PI)', 'icon': Icons.speed},
    {'name': 'TI / TU', 'icon': Icons.settings_input_component},
    {'name': 'Chống Sét Van', 'icon': Icons.bolt},
    {'name': 'Tiếp Địa', 'icon': Icons.horizontal_rule},
    {'name': 'Aptomat (MCB/MCCB)', 'icon': Icons.power},
    {'name': 'Rơ Le Số', 'icon': Icons.memory},
    {'name': 'Cáp Lực', 'icon': Icons.cable},
  ];

  void _showImportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.myDarkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.myMedNavy, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.file_upload, color: AppTheme.myOrangeAccent),
              SizedBox(width: 10),
              Text(
                'Nhập dữ liệu JSON',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Vui lòng chọn loại dữ liệu cấu hình JSON bạn muốn nạp vào ứng dụng:',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ListTile(
                tileColor: AppTheme.myMedNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: AppTheme.myOrangeAccent, width: 0.8),
                ),
                leading: const Icon(Icons.calculate, color: AppTheme.myOrangeAccent),
                title: const Text(
                  'Nhập file Công thức',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Nạp công thức tính toán toán học',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  String? message = await FormulaService.importFormulasFromFile();
                  if (context.mounted && message != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                    Navigator.pop(context); // Đóng Drawer
                  }
                },
              ),
              const SizedBox(height: 10),
              ListTile(
                tileColor: AppTheme.myMedNavy,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                  side: const BorderSide(color: Colors.cyanAccent, width: 0.8),
                ),
                leading: const Icon(Icons.menu_book, color: Colors.cyanAccent),
                title: const Text(
                  'Nhập file Tiêu chuẩn',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Nạp dữ liệu giới hạn tiêu chuẩn thử nghiệm',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                onTap: () async {
                  Navigator.pop(dialogContext);
                  String? message =
                      await ReferenceStandardService.importStandardsFromFile();
                  if (context.mounted && message != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(message)),
                    );
                    Navigator.pop(context); // Đóng Drawer
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  void _showResetDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.myDarkNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.myMedNavy, width: 1.5),
          ),
          title: const Row(
            children: [
              Icon(Icons.restart_alt, color: Colors.orangeAccent),
              SizedBox(width: 10),
              Text(
                'Khôi phục dữ liệu gốc',
                style: TextStyle(color: Colors.white, fontSize: 20),
              ),
            ],
          ),
          content: const Text(
            'Chọn loại dữ liệu bạn muốn khôi phục về giá trị mặc định ban đầu:',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                String msg = await FormulaService.resetToDefault();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                  Navigator.pop(context); // Đóng Drawer
                }
              },
              child: const Text('Khôi phục Công thức',
                  style: TextStyle(color: AppTheme.myOrangeAccent)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                String msg = await ReferenceStandardService.resetToDefault();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(msg)),
                  );
                  Navigator.pop(context); // Đóng Drawer
                }
              },
              child: const Text('Khôi phục Tiêu chuẩn',
                  style: TextStyle(color: Colors.cyanAccent)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Hủy', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MTE-LAB Cal-Notes',
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.menu_book, size: 28),
            tooltip: 'Tra cứu Tiêu chuẩn',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ReferenceStandardScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.history, size: 28),
            tooltip: 'Xem Sổ Tay',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          )
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.myDarkNavy,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: AppTheme.myMedNavy),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.precision_manufacturing,
                      size: 48, color: AppTheme.myOrangeAccent),
                  SizedBox(height: 12),
                  Text('⚙️ Cài đặt & Công cụ',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.menu_book,
                  color: AppTheme.myOrangeAccent, size: 32),
              title: const Text('Tra cứu Tiêu chuẩn',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              subtitle: const Text('Tra cứu nhanh tiêu chuẩn đạt của thiết bị',
                  style: TextStyle(color: Colors.white70)),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ReferenceStandardScreen()),
                );
              },
            ),
            const Divider(color: AppTheme.myMedNavy, thickness: 1),
            ListTile(
              leading: const Icon(Icons.file_upload,
                  color: AppTheme.myOrangeAccent, size: 32),
              title: const Text('Nhập file JSON cấu hình',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              subtitle: const Text('Nạp công thức hoặc tiêu chuẩn mới vào ứng dụng',
                  style: TextStyle(color: Colors.white70)),
              onTap: () => _showImportDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt,
                  color: Colors.orangeAccent, size: 28),
              title: const Text('Khôi phục mặc định',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              subtitle: const Text('Khôi phục công thức/tiêu chuẩn về ban đầu',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () => _showResetDialog(context),
            ),
            const Divider(color: AppTheme.myMedNavy, thickness: 2),
            ListTile(
              leading: const Icon(Icons.info_outline,
                  color: Colors.white70, size: 24),
              title: const Text('MTE-LAB Cal-Notes v1.0',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              onTap: () {},
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.9,
          ),
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            final item = _devices[index];
            return InkWell(
              onTap: () {
                Widget targetScreen;
                switch (index) {
                  case 0:
                    targetScreen = const TransformerCalculatorScreen();
                    break;
                  case 1:
                    targetScreen = const CircuitBreakerScreen();
                    break;
                  case 2:
                    targetScreen =
                        const InsulationCalculatorScreen(); // ĐO CÁCH ĐIỆN DAR & PI
                    break;
                  case 3:
                    targetScreen = const CtVtScreen();
                    break;
                  case 4:
                    targetScreen = const SurgeArresterScreen();
                    break;
                  case 5:
                    targetScreen = const GroundingScreen();
                    break;
                  case 6:
                    targetScreen = const AptomatScreen(); // APTOMAT
                    break;
                  case 7:
                    targetScreen = const DigitalRelayScreen();
                    break;
                  case 8:
                  default:
                    targetScreen = const CableScreen(); // CÁP LỰC
                    break;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => targetScreen),
                );
              },
              customBorder: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              child: Card(
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: AppTheme.myMedNavy, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      item['icon'],
                      size: 64,
                      color: AppTheme.myOrangeAccent,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item['name'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
