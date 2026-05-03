import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import 'note_detail_screen.dart';


class SurgeArresterScreen extends StatefulWidget {
  const SurgeArresterScreen({super.key});

  @override
  State<SurgeArresterScreen> createState() => _SurgeArresterScreenState();
}

class _SurgeArresterScreenState extends State<SurgeArresterScreen> {
  final TextEditingController iDoCtrl = TextEditingController();
  final TextEditingController tDoCtrl = TextEditingController();
  final TextEditingController tTcCtrl = TextEditingController(text: '20'); // Default is 20 C
  final TextEditingController resolutionCtrl = TextEditingController();
  
  double? iResult;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  void _tinhDongRo() {
    double iDo = parseInput(iDoCtrl.text);
    double tDo = parseInput(tDoCtrl.text);
    double tTc = parseInput(tTcCtrl.text);

    if (iDoCtrl.text.isEmpty || tDoCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Vui lòng nhập đủ các thông số!')));
      return;
    }

    final model = FormulaService.getFormulaById('LA_Leakage_Current');

    try {
      if (model != null) {
        iResult = FormulaService.calculate(
            model.formula, {'I_do': iDo, 'T_do': tDo, 'T_tc': tTc});
      } else {
        // Fallback formula: I_tc = I_do / 1.5 ^ ((T_do - T_tc)/10)
        iResult = iDo / pow(1.5, (tDo - tTc) / 10);
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

    if (iResult != null) {
      cals.add(TestCalculation(
        name: 'Dòng rò quy đổi (LA)',
        inputs: {
          'I_do': parseInput(iDoCtrl.text),
          'T_do': parseInput(tDoCtrl.text),
          'T_tc': parseInput(tTcCtrl.text)
        },
        result: iResult!,
        unit: 'mA$uBString',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng thực hiện phép tính ít nhất 1 lần nghen!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Chống Sét Van',
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
    int pendingCount = iResult != null ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TÍNH TOÁN CHỐNG SÉT VAN'),
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
                    const Text('QUY ĐỔI DÒNG RÒ (mA)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('I_đo (mA)', iDoCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField('T_đo (°C)', tDoCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField('T_tc (°C)', tTcCtrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Độ phân giải máy đo (tính uB)', resolutionCtrl, hint: 'VD: 0.001'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _tinhDongRo,
                      child: const Text('TÍNH DÒNG RÒ VỀ 20°C'),
                    ),
                    Builder(
                      builder: (context) {
                        double res = parseInput(resolutionCtrl.text);
                        if (res > 0) {
                          double uB = res / (2 * sqrt(3));
                          return Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: Text(
                              'ĐKBĐ Loại B dự kiến: uB = ${uB.toStringAsFixed(4)} mA',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    ),
                    if (iResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppTheme.myMedNavy,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('I_tc = ',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('${iResult!.toStringAsFixed(3)} mA',
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
