import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import 'note_detail_screen.dart';

class InsulationCalculatorScreen extends StatefulWidget {
  const InsulationCalculatorScreen({super.key});

  @override
  State<InsulationCalculatorScreen> createState() =>
      _InsulationCalculatorScreenState();
}

class _InsulationCalculatorScreenState
    extends State<InsulationCalculatorScreen> {
  // Input controllers
  final TextEditingController r15sCtrl = TextEditingController();
  final TextEditingController r60sCtrl = TextEditingController();
  final TextEditingController r10mCtrl = TextEditingController();
  final TextEditingController tDoCtrl = TextEditingController(text: '30');
  final TextEditingController tTcCtrl = TextEditingController(text: '20');

  // Calculation Results
  double? darResult;
  double? piResult;
  double? r60sConverted;

  // Evaluation badges
  String? darEvaluation;
  Color darColor = Colors.grey;

  String? piEvaluation;
  Color piColor = Colors.grey;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  void _calculateAll() {
    double r15s = parseInput(r15sCtrl.text);
    double r60s = parseInput(r60sCtrl.text);
    double r10m = parseInput(r10mCtrl.text);
    double tDo = parseInput(tDoCtrl.text);
    double tTc = parseInput(tTcCtrl.text);

    if (r60sCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập điện trở 60s (R_60s / R_1m)!'),
        ),
      );
      return;
    }

    try {
      // 1. Tính DAR (R60s / R15s)
      if (r15s > 0 && r60s > 0) {
        final darModel = FormulaService.getFormulaById('INS_DAR');
        if (darModel != null) {
          darResult = FormulaService.calculate(
            darModel.formula,
            {'R_60s': r60s, 'R_15s': r15s},
          );
        } else {
          darResult = r60s / r15s;
        }

        // Evaluation for DAR (IEEE 43)
        if (darResult! < 1.0) {
          darEvaluation = 'Kém / Không đạt (< 1.0)';
          darColor = Colors.redAccent;
        } else if (darResult! < 1.25) {
          darEvaluation = 'Nghi ngờ / Tối thiểu (1.0 - 1.25)';
          darColor = Colors.orangeAccent;
        } else if (darResult! < 1.6) {
          darEvaluation = 'Tốt (1.25 - 1.6)';
          darColor = Colors.lightGreenAccent;
        } else {
          darEvaluation = 'Rất tốt (≥ 1.6)';
          darColor = Colors.greenAccent;
        }
      } else {
        darResult = null;
        darEvaluation = null;
      }

      // 2. Tính PI (R10m / R1m)
      if (r10m > 0 && r60s > 0) {
        final piModel = FormulaService.getFormulaById('INS_PI');
        if (piModel != null) {
          piResult = FormulaService.calculate(
            piModel.formula,
            {'R_10m': r10m, 'R_1m': r60s},
          );
        } else {
          piResult = r10m / r60s;
        }

        // Evaluation for PI (IEEE 43)
        if (piResult! < 1.0) {
          piEvaluation = 'Nguy hiểm / Rất kém (< 1.0)';
          piColor = Colors.redAccent;
        } else if (piResult! < 2.0) {
          piEvaluation = 'Nghi ngờ / Cần theo dõi (1.0 - 2.0)';
          piColor = Colors.orangeAccent;
        } else if (piResult! < 4.0) {
          piEvaluation = 'Tốt (2.0 - 4.0)';
          piColor = Colors.lightGreenAccent;
        } else {
          piEvaluation = 'Rất tốt (≥ 4.0)';
          piColor = Colors.greenAccent;
        }
      } else {
        piResult = null;
        piEvaluation = null;
      }

      // 3. Tính R_cd Quy đổi nhiệt độ tiêu chuẩn: R_tc = R_do * 1.5 ^ ((T_do - T_tc)/10)
      if (r60s > 0 && tDoCtrl.text.isNotEmpty && tTcCtrl.text.isNotEmpty) {
        final rcdModel = FormulaService.getFormulaById('MBA_Rcd');
        if (rcdModel != null) {
          r60sConverted = FormulaService.calculate(
            rcdModel.formula,
            {'R_do': r60s, 'T_do': tDo, 'T_tc': tTc},
          );
        } else {
          r60sConverted = r60s * pow(1.5, (tDo - tTc) / 10);
        }
      } else {
        r60sConverted = null;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính toán cách điện: $e')),
      );
    }
  }

  void _saveNotes() {
    List<TestCalculation> cals = [];

    if (darResult != null) {
      cals.add(TestCalculation(
        name: 'Tỉ số hấp thụ điện môi (DAR)',
        inputs: {
          'R_15s': parseInput(r15sCtrl.text),
          'R_60s': parseInput(r60sCtrl.text),
        },
        result: darResult!,
        unit: '(${darEvaluation?.split(' ')[0] ?? ''})',
      ));
    }

    if (piResult != null) {
      cals.add(TestCalculation(
        name: 'Hệ số phân cực (PI)',
        inputs: {
          'R_1m': parseInput(r60sCtrl.text),
          'R_10m': parseInput(r10mCtrl.text),
        },
        result: piResult!,
        unit: '(${piEvaluation?.split(' ')[0] ?? ''})',
      ));
    }

    if (r60sConverted != null) {
      cals.add(TestCalculation(
        name: 'R_cd 60s Quy đổi (${tTcCtrl.text}°C)',
        inputs: {
          'R_đo': parseInput(r60sCtrl.text),
          'T_đo': parseInput(tDoCtrl.text),
          'T_tc': parseInput(tTcCtrl.text),
        },
        result: r60sConverted!,
        unit: 'MΩ',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng thực hiện tính toán DAR hoặc PI trước!'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Phép đo Cách điện (PI & DAR)',
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {String hint = '', bool isExpanded = true}) {
    final field = Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        ),
      ),
    );
    return isExpanded ? Expanded(child: field) : field;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ĐO CÁCH ĐIỆN (DAR & PI)'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveNotes,
        backgroundColor: (darResult != null || piResult != null)
            ? AppTheme.myOrangeAccent
            : Colors.grey,
        icon: const Icon(Icons.bookmark_add),
        label: const Text('Lưu Sổ Tay'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // DỮ LIỆU ĐẦU VÀO ----------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '1. THÔNG SỐ ĐIỆN TRỞ CÁCH ĐIỆN (MΩ)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myBrightBlue),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('R_15s (MΩ)', r15sCtrl, hint: '15 giây'),
                        const SizedBox(width: 8),
                        _buildTextField('R_60s (MΩ)', r60sCtrl, hint: '1 phút'),
                        const SizedBox(width: 8),
                        _buildTextField('R_10m (MΩ)', r10mCtrl, hint: '10 phút'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      '2. NHIỆT ĐỘ THỬ NGHIỆM (°C)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myBrightBlue),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('T_đo (°C)', tDoCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('T_tc (°C)', tTcCtrl, hint: 'Mặc định 20°C'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _calculateAll,
                      icon: const Icon(Icons.calculate),
                      label: const Text('TÍNH DAR & PI & QUY ĐỔI R_cd'),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // KẾT QUẢ TÍNH DAR ----------------------------------
            if (darResult != null) ...[
              Card(
                color: AppTheme.myMedNavy,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'DAR (R_60s / R_15s):',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            darResult!.toStringAsFixed(3),
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: darColor),
                          ),
                        ],
                      ),
                      if (darEvaluation != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: darColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: darColor),
                          ),
                          child: Text(
                            'Đánh giá IEEE 43: $darEvaluation',
                            style: TextStyle(
                                color: darColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // KẾT QUẢ TÍNH PI ----------------------------------
            if (piResult != null) ...[
              Card(
                color: AppTheme.myMedNavy,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'PI (R_10m / R_1m):',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            piResult!.toStringAsFixed(3),
                            style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: piColor),
                          ),
                        ],
                      ),
                      if (piEvaluation != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: piColor.withAlpha(50),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: piColor),
                          ),
                          child: Text(
                            'Đánh giá IEEE 43: $piEvaluation',
                            style: TextStyle(
                                color: piColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 15),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // R60S QUY ĐỔI ----------------------------------
            if (r60sConverted != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'R_cd Quy đổi (${tTcCtrl.text}°C):',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${r60sConverted!.toStringAsFixed(1)} MΩ',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.cyanAccent),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],

            // TIÊU CHUẨN ĐÁNH GIÁ THAM KHẢO ------------------------
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📖 Tiêu chuẩn Đánh giá IEEE 43 / IEC',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    Divider(),
                    Text('• Hệ số phân cực (PI = R_10m / R_1m):',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('  - PI < 1.0: Nguy hiểm / Kém (Cần sấy/kiểm tra)'),
                    Text('  - 1.0 ≤ PI < 2.0: Nghi ngờ / Trung bình'),
                    Text('  - 2.0 ≤ PI < 4.0: Tốt (Đạt tiêu chuẩn)'),
                    Text('  - PI ≥ 4.0: Rất tốt'),
                    SizedBox(height: 8),
                    Text('• Tỉ số hấp thụ điện môi (DAR = R_60s / R_15s):',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('  - DAR < 1.0: Kém / Không đạt'),
                    Text('  - 1.0 ≤ DAR < 1.25: Nghi ngờ / Tối thiểu'),
                    Text('  - 1.25 ≤ DAR < 1.6: Tốt'),
                    Text('  - DAR ≥ 1.6: Rất tốt'),
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
