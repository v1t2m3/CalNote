import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import 'note_detail_screen.dart';


class DigitalRelayScreen extends StatefulWidget {
  const DigitalRelayScreen({super.key});

  @override
  State<DigitalRelayScreen> createState() => _DigitalRelayScreenState();
}

class _DigitalRelayScreenState extends State<DigitalRelayScreen> {
  final TextEditingController iFCtrl = TextEditingController();
  final TextEditingController iSetCtrl = TextEditingController();
  final TextEditingController tmsCtrl = TextEditingController();
  final TextEditingController resolutionCtrl = TextEditingController();
  
  double? tResult;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  void _tinhThoiGian() {
    double iF = parseInput(iFCtrl.text);
    double iSet = parseInput(iSetCtrl.text);
    double tms = parseInput(tmsCtrl.text);

    if (iF == 0 || iSet == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dòng điện phải lớn hơn 0!')));
      return;
    }

    if (iF <= iSet) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Dòng sự cố phải lớn hơn dòng cài đặt (I_f > I_set)!')));
      return; 
    }

    final model = FormulaService.getFormulaById('RL_IDMT_NormalInverse');

    try {
      if (model != null) {
        tResult = FormulaService.calculate(
            model.formula, {'I_f': iF, 'I_set': iSet, 'TMS': tms});
      } else {
        // IEC Normal Inverse: t = 0.14 / ((I_f/I_set)^0.02 - 1) * TMS
        tResult = (0.14 / (pow((iF / iSet), 0.02) - 1)) * tms;
      }
      
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

    if (tResult != null) {
      cals.add(TestCalculation(
        name: 'TG Tác động (IEC Normal Inverse)',
        inputs: {
          'I_f': parseInput(iFCtrl.text),
          'I_set': parseInput(iSetCtrl.text),
          'TMS': parseInput(tmsCtrl.text)
        },
        result: tResult!,
        unit: 's$uBString',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Đã tính đâu mà bấm lưu đại ca!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Rơ Le Số',
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
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = tResult != null ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TÍNH TOÁN RƠ LE SỐ'),
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
                    const Text('THỜI GIAN TÁC ĐỘNG (IEC Normal Inverse)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('I_set (A)', iSetCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField('I_f (A)', iFCtrl)),
                      ],
                    ),
                    _buildTextField('Hệ số TMS', tmsCtrl),
                    const SizedBox(height: 8),
                    _buildTextField('Độ phân giải thời gian (s)', resolutionCtrl, hint: 'VD: 0.001'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _tinhThoiGian,
                      child: const Text('TÍNH THỜI GIAN CẮT'),
                    ),
                    Builder(
                      builder: (context) {
                        double res = parseInput(resolutionCtrl.text);
                        if (res > 0) {
                          double uB = res / (2 * sqrt(3));
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              'ĐKBĐ Loại B dự kiến: uB = ${uB.toStringAsFixed(4)} s',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    ),
                    if (tResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppTheme.myMedNavy,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('t = ',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('${tResult!.toStringAsFixed(3)} s',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium),
                              ),
                            ),
                          ],
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
