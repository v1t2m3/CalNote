import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_formatters.dart';
import 'note_detail_screen.dart';
import '../widgets/equipment_icon_widget.dart';


class GroundingScreen extends StatefulWidget {
  const GroundingScreen({super.key});

  @override
  State<GroundingScreen> createState() => _GroundingScreenState();
}

class _GroundingScreenState extends State<GroundingScreen> {
  final TextEditingController rDoCtrl = TextEditingController();
  final TextEditingController kMuaCtrl = TextEditingController();
  final TextEditingController resolutionCtrl = TextEditingController();
  
  String _thresholdClass = '4'; // 4 hoặc 10 Ohm
  double? rResult;
  bool isFailed = false;

  double parseInput(String val) => AppFormatters.parseInput(val);


  void _tinhDienTro() {
    double rDo = parseInput(rDoCtrl.text);
    double kMua = parseInput(kMuaCtrl.text);

    if (rDoCtrl.text.isEmpty || kMuaCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Chưa nhập đủ tham số kìa!')));
      return;
    }

    final model = FormulaService.getFormulaById('TD_R_QuyDoi');

    try {
      if (model != null) {
        rResult = FormulaService.calculate(
            model.formula, {'R_do': rDo, 'K_mua': kMua});
      } else {
        rResult = rDo * kMua;
      }
      
      double allowedThreshold = double.parse(_thresholdClass);
      isFailed = rResult! > allowedThreshold;
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tính: $e')));
    }
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    double resolution = parseInput(resolutionCtrl.text);
    String uBString = '';
    if (resolution > 0) {
      double uB = resolution / (2 * sqrt(3));
      uBString = ' (uB: ${uB.toStringAsFixed(4)})';
    }

    if (rResult != null) {
      cals.add(TestCalculation(
        name: 'Điện trở tiếp địa quy đổi',
        inputs: {
          'R_do': parseInput(rDoCtrl.text),
          'K_mua': parseInput(kMuaCtrl.text)
        },
        result: rResult!,
        unit: 'Ω$uBString',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Tính toán xong mới lưu được nghen!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Tiếp Địa',
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String hint = ''}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: AppTheme.fontSizeTitle, fontWeight: FontWeight.bold, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = rResult != null ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            EquipmentIconWidget(categoryCode: 'grounding', size: 26),
            SizedBox(width: 10),
            Text('TÍNH TOÁN TIẾP ĐỊA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAllNotes,
        backgroundColor:
            pendingCount > 0 ? AppTheme.myOrangeAccent : Colors.grey,
        icon: const Icon(Icons.bookmark_add),
        label: Text('Lưu Sổ ($pendingCount)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'I. QUY ĐỔI TIẾP ĐỊA MÙA (Ω)',
                      style: AppTheme.titleModuleStyle,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('R đo (Ω)', rDoCtrl, hint: 'VD: 3.45')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField('HS mùa K', kMuaCtrl, hint: 'VD: 1.40')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Độ phân giải', resolutionCtrl, hint: 'VD: 0.01'),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Ngưỡng cho phép: ',
                            style: TextStyle(fontSize: AppTheme.fontSizeBody, color: Colors.white70)),
                        Radio<String>(
                          value: '4',
                          groupValue: _thresholdClass,
                          activeColor: AppTheme.accentOrange,
                          onChanged: (val) => setState(() => _thresholdClass = val!),
                        ),
                        const Text('≤ 4 Ω', style: TextStyle(color: Colors.white)),
                        Radio<String>(
                          value: '10',
                          groupValue: _thresholdClass,
                          activeColor: AppTheme.accentOrange,
                          onChanged: (val) => setState(() => _thresholdClass = val!),
                        ),
                        const Text('≤ 10 Ω', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _tinhDienTro,
                      child: const Text('TÍNH QUY ĐỔI'),
                    ),
                    Builder(
                      builder: (context) {
                        double res = parseInput(resolutionCtrl.text);
                        if (res > 0) {
                          double uB = res / (2 * sqrt(3));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Text(
                              'ĐKBĐ Loại B dự kiến: uB = ${uB.toStringAsFixed(4)} Ω',
                              style: const TextStyle(color: AppTheme.accentOrange, fontSize: AppTheme.fontSizeCaption),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    ),
                    if (rResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppTheme.myMedNavy,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('R_qđ = ',
                                style: TextStyle(
                                    fontSize: AppTheme.fontSizeTitle, fontWeight: FontWeight.bold, color: Colors.white)),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('${rResult!.toStringAsFixed(2)} Ω',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeTitle,
                                      fontWeight: FontWeight.bold,
                                      color: isFailed ? AppTheme.cbmLevel4 : AppTheme.statusGreen,
                                    )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isFailed)
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'KẾT LUẬN: KHÔNG ĐẠT TIÊU CHUẨN',
                            style: TextStyle(
                              color: AppTheme.cbmLevel4,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontSizeBody,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'KẾT LUẬN: ĐẠT TIÊU CHUẨN',
                            style: TextStyle(
                              color: AppTheme.statusGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontSizeBody,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
