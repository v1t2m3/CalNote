import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import 'note_detail_screen.dart';


class CtVtScreen extends StatefulWidget {
  const CtVtScreen({super.key});

  @override
  State<CtVtScreen> createState() => _CtVtScreenState();
}

class _CtVtScreenState extends State<CtVtScreen> {
  final TextEditingController kDmCtrl = TextEditingController();
  final TextEditingController kTtCtrl = TextEditingController();
  final TextEditingController resolutionCtrl = TextEditingController();
  
  String _accuracyClass = '0.2'; // 0.2 hoặc 0.5
  double? errorResult;
  bool isFailed = false;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  void _tinhSaiSo() {
    double kdm = parseInput(kDmCtrl.text);
    double ktt = parseInput(kTtCtrl.text);

    if (kdm == 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('K định mức phải lớn hơn 0!')));
      return;
    }

    final model = FormulaService.getFormulaById('TITU_Ratio_Error');

    try {
      if (model != null) {
        errorResult = FormulaService.calculate(
            model.formula, {'K_tt': ktt, 'K_dm': kdm});
      } else {
        errorResult = ((ktt - kdm) / kdm) * 100;
      }
      
      double allowedError = double.parse(_accuracyClass);
      isFailed = errorResult!.abs() > allowedError;
      
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

    if (errorResult != null) {
      cals.add(TestCalculation(
        name: 'Sai số tỷ số TI/TU (Class $_accuracyClass)',
        inputs: {
          'K_dm': parseInput(kDmCtrl.text),
          'K_tt': parseInput(kTtCtrl.text)
        },
        result: errorResult!,
        unit: '%$uBString',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Chưa tính thì lấy gì lưu. Nhập lại nhập lại!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'TI / TU',
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
    int pendingCount = errorResult != null ? 1 : 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TÍNH TOÁN TI / TU'),
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
                    const Text('SAI SỐ TỶ SỐ TI/TU (%)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('K Định Mức', kDmCtrl)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField('K Thực Tế', kTtCtrl)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Độ phân giải (tuỳ chọn)', resolutionCtrl, hint: 'VD: 0.01'),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Cấp chính xác: ',
                            style: TextStyle(fontSize: 16)),
                        Radio<String>(
                          value: '0.2',
                          groupValue: _accuracyClass,
                          activeColor: AppTheme.myOrangeAccent,
                          onChanged: (val) => setState(() => _accuracyClass = val!),
                        ),
                        const Text('Class 0.2'),
                        Radio<String>(
                          value: '0.5',
                          groupValue: _accuracyClass,
                          activeColor: AppTheme.myOrangeAccent,
                          onChanged: (val) => setState(() => _accuracyClass = val!),
                        ),
                        const Text('Class 0.5'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _tinhSaiSo,
                      child: const Text('TÍNH SAI SỐ'),
                    ),
                    Builder(
                      builder: (context) {
                        double res = parseInput(resolutionCtrl.text);
                        if (res > 0) {
                          double uB = res / (2 * sqrt(3));
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                            child: Text(
                              'ĐKBĐ Loại B dự kiến: uB = ${uB.toStringAsFixed(4)} %',
                              style: const TextStyle(color: Colors.orangeAccent, fontSize: 16),
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      }
                    ),
                    if (errorResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppTheme.myMedNavy,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('f = ',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('${errorResult!.toStringAsFixed(4)} %',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium?.copyWith(
                                          color: isFailed ? Colors.redAccent : Colors.lightGreenAccent
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
                              'CẢNH BÁO: Thiết bị KHÔNG ĐẠT cấp chính xác!',
                              style: TextStyle(
                                  color: Colors.redAccent,
                                  fontWeight: FontWeight.bold)),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                              'THÀNH CÔNG: Thiết bị đạt cấp chính xác.',
                              style: TextStyle(
                                  color: Colors.lightGreenAccent,
                                  fontWeight: FontWeight.bold)),
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
