import 'package:flutter/material.dart';
import '../services/formula_service.dart';
import '../services/reference_standard_service.dart';
import '../services/calibration_service.dart';
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
import 'disconnector_calculator_screen.dart'; // THÊM IMPORT DAO CÁCH LY
import 'recloser_calculator_screen.dart'; // THÊM IMPORT RECLOSER / LBS / RMU
import '../widgets/equipment_icon_widget.dart'; // THÊM COMPONENT ICON SVG CAO THẾ

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final List<Map<String, dynamic>> _devices = const [
    {
      'code': 'transformer',
      'name': 'Máy Biến Áp',
      'svg': 'assets/icons/high_voltage/may_bien_ap.svg',
      'icon': Icons.electrical_services,
    },
    {
      'code': 'circuit_breaker',
      'name': 'Máy Cắt',
      'svg': 'assets/icons/high_voltage/may_cat.svg',
      'icon': Icons.power_settings_new,
    },
    {
      'code': 'disconnector',
      'name': 'Dao Cách Ly',
      'svg': 'assets/icons/high_voltage/dao_cach_ly.svg',
      'icon': Icons.power_off,
    },
    {
      'code': 'recloser_lbs',
      'name': 'Recloser / LBS / RMU',
      'svg': 'assets/icons/high_voltage/recloser_lbs.svg',
      'icon': Icons.tune,
    },
    {
      'code': 'insulation_ir',
      'name': 'Đo Cách Điện (DAR/PI)',
      'isIR': true,
      'icon': Icons.speed,
    },
    {
      'code': 'instrument_transformer',
      'name': 'TI / TU',
      'svg': 'assets/icons/high_voltage/TU_TI.svg',
      'icon': Icons.donut_large,
    },
    {
      'code': 'surge_arrester',
      'name': 'Chống Sét Van',
      'svg': 'assets/icons/high_voltage/chong_set_van.svg',
      'icon': Icons.flash_on,
    },
    {
      'code': 'grounding',
      'name': 'Tiếp Địa',
      'svg': 'assets/icons/high_voltage/tiep_dia.svg',
      'icon': Icons.format_line_spacing,
    },
    {
      'code': 'aptomat',
      'name': 'Aptomat (MCB/MCCB)',
      'svg': 'assets/icons/high_voltage/aptomat.svg',
      'icon': Icons.toggle_on,
    },
    {
      'code': 'digital_relay',
      'name': 'Rơ Le Số',
      'svg': 'assets/icons/high_voltage/relay_bao_ve.svg',
      'icon': Icons.shield,
    },
    {
      'code': 'cable',
      'name': 'Cáp Lực',
      'svg': 'assets/icons/high_voltage/cap_ngam.svg',
      'icon': Icons.cable,
    },
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
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Vui lòng chọn loại file JSON bạn muốn nạp vào ứng dụng:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                const SizedBox(height: 12),
                _buildImportTile(
                  context,
                  dialogContext,
                  title: 'Nhập file Công thức (formulas.json)',
                  subtitle: 'Nạp công thức tính toán toán học',
                  icon: Icons.calculate,
                  iconColor: AppTheme.myOrangeAccent,
                  onImport: () => FormulaService.importFormulasFromFile(),
                ),
                const SizedBox(height: 8),
                _buildImportTile(
                  context,
                  dialogContext,
                  title: 'Nhập file Tiêu chuẩn Thử nghiệm',
                  subtitle: 'Nạp file standards.json',
                  icon: Icons.science,
                  iconColor: Colors.amberAccent,
                  onImport: () => ReferenceStandardService.importStandardsFromFile(),
                ),
                const SizedBox(height: 8),
                _buildImportTile(
                  context,
                  dialogContext,
                  title: 'Nhập file Tiêu chuẩn Kiểm định TT02',
                  subtitle: 'Nạp file standardTT02.json (TT02/2025/TT-BCT)',
                  icon: Icons.verified_user,
                  iconColor: Colors.blueAccent,
                  onImport: () => ReferenceStandardService.importTT02FromFile(),
                ),
                const SizedBox(height: 8),
                _buildImportTile(
                  context,
                  dialogContext,
                  title: 'Nhập file Tiêu chuẩn CBM',
                  subtitle: 'Nạp file standardCBM.json (Đánh giá 4 mức)',
                  icon: Icons.analytics,
                  iconColor: Colors.purpleAccent,
                  onImport: () => ReferenceStandardService.importCBMFromFile(),
                ),
                const SizedBox(height: 8),
                _buildImportTile(
                  context,
                  dialogContext,
                  title: 'Nhập file Thiết bị Hiệu chuẩn (k, P, u%)',
                  subtitle: 'Nạp file calibrated_equipment.json',
                  icon: Icons.precision_manufacturing,
                  iconColor: Colors.tealAccent,
                  onImport: () => CalibrationService.importEquipmentFromFile(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Đóng', style: TextStyle(color: Colors.white54)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildImportTile(
    BuildContext context,
    BuildContext dialogContext, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Future<String?> Function() onImport,
  }) {
    return ListTile(
      tileColor: AppTheme.myMedNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: BorderSide(color: iconColor.withValues(alpha: 0.6), width: 0.8),
      ),
      leading: Icon(icon, color: iconColor),
      title: Text(
        title,
        style: const TextStyle(
            color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.white70, fontSize: 11),
      ),
      onTap: () async {
        Navigator.pop(dialogContext);
        String? message = await onImport();
        if (context.mounted && message != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
          Navigator.pop(context); // Đóng Drawer
        }
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
                'Khôi phục mặc định',
                style: TextStyle(color: Colors.white, fontSize: 19),
              ),
            ],
          ),
          content: const Text(
            'Chọn loại dữ liệu bạn muốn khôi phục về giá trị gốc mặc định ban đầu:',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          actions: [
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              runSpacing: 4,
              children: [
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    String msg = await FormulaService.resetToDefault();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Khôi phục Công thức',
                      style: TextStyle(color: AppTheme.myOrangeAccent, fontSize: 12)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    String msg =
                        await ReferenceStandardService.resetStandardsToDefault();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Khôi phục Thử nghiệm',
                      style: TextStyle(color: Colors.amberAccent, fontSize: 12)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    String msg = await ReferenceStandardService.resetTT02ToDefault();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Khôi phục TT02',
                      style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    String msg = await ReferenceStandardService.resetCBMToDefault();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Khôi phục CBM',
                      style: TextStyle(color: Colors.purpleAccent, fontSize: 12)),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);
                    String msg = await CalibrationService.resetToDefault();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(SnackBar(content: Text(msg)));
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Khôi phục Thiết bị Hiệu chuẩn',
                      style: TextStyle(color: Colors.tealAccent, fontSize: 12)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Hủy',
                      style: TextStyle(color: Colors.white54, fontSize: 12)),
                ),
              ],
            )
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isUncertaintyOn = CalibrationService.isUncertaintyEnabled;

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
            // CÔNG TẮC BẬT TẮT ĐỘ KHÔNG ĐẢM BẢO ĐO (ĐKĐBĐ)
            StatefulBuilder(
              builder: (ctx, setDrawerState) {
                bool enabled = CalibrationService.isUncertaintyEnabled;
                return Container(
                  color: enabled ? AppTheme.myOrangeAccent.withValues(alpha: 0.1) : Colors.transparent,
                  child: SwitchListTile(
                    value: enabled,
                    activeThumbColor: AppTheme.myOrangeAccent,
                    title: const Text('Độ không đảm bảo đo (ĐKĐBĐ)',
                        style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      enabled
                          ? 'BẬT: Tính toán với hiệu chuẩn & ĐKĐBĐ'
                          : 'TẮT: Tính toán theo giá trị đo',
                      style: TextStyle(
                          color: enabled ? Colors.greenAccent : Colors.white54,
                          fontSize: 12),
                    ),
                    secondary: Icon(Icons.tune,
                        color: enabled ? AppTheme.myOrangeAccent : Colors.white54,
                        size: 30),
                    onChanged: (val) async {
                      await CalibrationService.setUncertaintyEnabled(val);
                      setDrawerState(() {});
                      setState(() {});
                    },
                  ),
                );
              },
            ),
            const Divider(color: AppTheme.myMedNavy, thickness: 1),
            ListTile(
              leading: const Icon(Icons.menu_book,
                  color: AppTheme.myOrangeAccent, size: 32),
              title: const Text('Tra cứu Tiêu chuẩn',
                  style: TextStyle(fontSize: 18, color: Colors.white)),
              subtitle: const Text('Thử nghiệm, Kiểm định TT02 & CBM 4 Mức',
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
              subtitle: const Text('Công thức, Tiêu chuẩn hoặc Thiết bị hiệu chuẩn',
                  style: TextStyle(color: Colors.white70)),
              onTap: () => _showImportDialog(context),
            ),
            ListTile(
              leading: const Icon(Icons.restart_alt,
                  color: Colors.orangeAccent, size: 28),
              title: const Text('Khôi phục mặc định',
                  style: TextStyle(fontSize: 16, color: Colors.white)),
              subtitle: const Text('Khôi phục dữ liệu gốc từ hệ thống',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              onTap: () => _showResetDialog(context),
            ),
            const Divider(color: AppTheme.myMedNavy, thickness: 2),
            ListTile(
              leading: const Icon(Icons.info_outline,
                  color: Colors.white70, size: 24),
              title: const Text('MTE-LAB Cal-Notes v1.0',
                  style: TextStyle(fontSize: 16, color: Colors.white70)),
              subtitle: Text(
                isUncertaintyOn ? 'Chế độ: ĐKĐBĐ ISO 17025 BẬT' : 'Chế độ: Tiêu chuẩn',
                style: TextStyle(
                    color: isUncertaintyOn ? Colors.greenAccent : Colors.white38,
                    fontSize: 11),
              ),
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
            childAspectRatio: 0.88,
          ),
          itemCount: _devices.length,
          itemBuilder: (context, index) {
            final item = _devices[index];
            return InkWell(
              onTap: () {
                Widget targetScreen;
                switch (item['code']) {
                  case 'transformer':
                    targetScreen = const TransformerCalculatorScreen();
                    break;
                  case 'circuit_breaker':
                    targetScreen = const CircuitBreakerScreen();
                    break;
                  case 'disconnector':
                    targetScreen = const DisconnectorCalculatorScreen();
                    break;
                  case 'recloser_lbs':
                    targetScreen = const RecloserCalculatorScreen();
                    break;
                  case 'insulation_ir':
                    targetScreen = const InsulationCalculatorScreen();
                    break;
                  case 'instrument_transformer':
                    targetScreen = const CtVtScreen();
                    break;
                  case 'surge_arrester':
                    targetScreen = const SurgeArresterScreen();
                    break;
                  case 'grounding':
                    targetScreen = const GroundingScreen();
                    break;
                  case 'aptomat':
                    targetScreen = const AptomatScreen();
                    break;
                  case 'digital_relay':
                    targetScreen = const DigitalRelayScreen();
                    break;
                  case 'cable':
                  default:
                    targetScreen = const CableScreen();
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
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 12.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      EquipmentIconWidget(
                        categoryCode: item['code'],
                        customAsset: item['svg'],
                        isIR: item['isIR'] == true,
                        fallbackIcon: item['icon'],
                        size: 64,
                        isCard: true,
                        color: AppTheme.myOrangeAccent,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        item['name'],
                        style: AppTheme.bodyBoldWhite,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
