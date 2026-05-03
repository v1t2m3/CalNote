import 'package:flutter/material.dart';
import '../services/formula_service.dart';
import 'transformer_calculator_screen.dart';
import '../core/theme/app_theme.dart';
import 'history_screen.dart';
import 'circuit_breaker_screen.dart';
import 'ct_vt_screen.dart';
import 'surge_arrester_screen.dart';
import 'grounding_screen.dart';
import 'digital_relay_screen.dart';
import 'aptomat_screen.dart'; // THÊM IMPORT APTOMAT

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  final List<Map<String, dynamic>> _devices = const [
    {'name': 'Máy Biến Áp', 'icon': Icons.flash_on},
    {'name': 'Máy Cắt', 'icon': Icons.electric_moped_outlined},
    {'name': 'TI / TU', 'icon': Icons.settings_input_component},
    {'name': 'Chống Sét Van', 'icon': Icons.bolt},
    {'name': 'Tiếp Địa', 'icon': Icons.horizontal_rule},
    {'name': 'Aptomat (MCB/MCCB)', 'icon': Icons.power},
    {'name': 'Rơ Le Số', 'icon': Icons.memory},
    {'name': 'Cáp Lực', 'icon': Icons.cable},
  ];

  Future<void> _importFormulas(BuildContext context) async {
    String? message = await FormulaService.importFormulasFromFile();
    if (context.mounted && message != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      Navigator.pop(context); // Đóng Drawer sau khi nạp xong
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MTE-LAB Cal-Notes', style: TextStyle( color: Colors.white)),
        actions: [
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
                   Icon(Icons.precision_manufacturing, size: 48, color: AppTheme.myOrangeAccent),
                   SizedBox(height: 12),
                   Text('⚙️ Cài đặt & Công cụ', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.file_upload, color: AppTheme.myOrangeAccent, size: 32),
              title: const Text('Nhập file Công thức (JSON)', style: TextStyle(fontSize: 18, color: Colors.white)),
              subtitle: const Text('Nạp công thức tính toán vào hệ thống', style: TextStyle(color: Colors.white70)),
              onTap: () => _importFormulas(context),
            ),
            const Divider(color: AppTheme.myMedNavy, thickness: 2),
            ListTile(
              leading: const Icon(Icons.info_outline, color: Colors.white70, size: 24),
              title: const Text('MTE-LAB Cal-Notes v1.0', style: TextStyle(fontSize: 16, color: Colors.white70)),
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
                    targetScreen = const CtVtScreen();
                    break;
                  case 3:
                    targetScreen = const SurgeArresterScreen();
                    break;
                  case 4:
                    targetScreen = const GroundingScreen();
                    break;
                  case 5:
                    targetScreen = const AptomatScreen(); // APTOMAT
                    break;
                  case 6:
                    targetScreen = const DigitalRelayScreen();
                    break;
                  case 7:
                  default:
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Module này đang xây dựng nghen!')),
                    );
                    return;
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => targetScreen),
                );
              },

              customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
