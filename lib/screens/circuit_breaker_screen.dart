import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import 'note_detail_screen.dart';


class CircuitBreakerScreen extends StatefulWidget {
  const CircuitBreakerScreen({super.key});

  @override
  State<CircuitBreakerScreen> createState() => _CircuitBreakerScreenState();
}

class _CircuitBreakerScreenState extends State<CircuitBreakerScreen> {
  // 1. Điện trở cách điện
  final TextEditingController rCdACtrl = TextEditingController();
  final TextEditingController rCdBCtrl = TextEditingController();
  final TextEditingController rCdCCtrl = TextEditingController();
  double? minRcd;

  // 2. Điện trở tiếp xúc
  final TextEditingController rTxACtrl = TextEditingController();
  final TextEditingController rTxBCtrl = TextEditingController();
  final TextEditingController rTxCCtrl = TextEditingController();
  final TextEditingController resolutionCtrl = TextEditingController();
  double? maxRtx;
  
  // 3. Thời gian không đồng thời
  final TextEditingController tACtrl = TextEditingController();
  final TextEditingController tBCtrl = TextEditingController();
  final TextEditingController tCCtrl = TextEditingController();
  String _actionType = 'Close'; // Close hoặc Open
  double? timeResult; // delta t
  bool hasTimeWarning = false;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  void _tinhCachDien() {
    double rA = parseInput(rCdACtrl.text);
    double rB = parseInput(rCdBCtrl.text);
    double rC = parseInput(rCdCCtrl.text);
    
    if (rCdACtrl.text.isEmpty && rCdBCtrl.text.isEmpty && rCdCCtrl.text.isEmpty) {
       minRcd = null;
    } else {
       // Coi giá trị nhỏ nhất là đại diện xấu nhất
       List<double> vals = [];
       if (rCdACtrl.text.isNotEmpty) vals.add(rA);
       if (rCdBCtrl.text.isNotEmpty) vals.add(rB);
       if (rCdCCtrl.text.isNotEmpty) vals.add(rC);
       minRcd = vals.reduce(min);
    }
    setState(() {});
  }

  void _tinhTiepXuc() {
    double rA = parseInput(rTxACtrl.text);
    double rB = parseInput(rTxBCtrl.text);
    double rC = parseInput(rTxCCtrl.text);

    if (rTxACtrl.text.isEmpty && rTxBCtrl.text.isEmpty && rTxCCtrl.text.isEmpty) {
       maxRtx = null;
    } else {
       List<double> vals = [];
       if (rTxACtrl.text.isNotEmpty) vals.add(rA);
       if (rTxBCtrl.text.isNotEmpty) vals.add(rB);
       if (rTxCCtrl.text.isNotEmpty) vals.add(rC);
       maxRtx = vals.reduce(max);
    }
    setState(() {});
  }

  void _tinhThoiGian() {
    double tA = parseInput(tACtrl.text);
    double tB = parseInput(tBCtrl.text);
    double tC = parseInput(tCCtrl.text);

    if (tACtrl.text.isEmpty && tBCtrl.text.isEmpty && tCCtrl.text.isEmpty) return;

    double tMax = max(tA, max(tB, tC));
    double tMin = min(tA, min(tB, tC));

    final model = FormulaService.getFormulaById('MC_Time_Delta');

    try {
      if (model != null) {
        timeResult = FormulaService.calculate(
            model.formula, {'t_max': tMax, 't_min': tMin});
      } else {
        timeResult = tMax - tMin;
      }
      
      hasTimeWarning = _actionType == 'Close' ? (timeResult! > 4.0) : (timeResult! > 2.0);
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tính: $e')));
    }
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    if (minRcd != null) {
      cals.add(TestCalculation(
        name: 'Điện trở cách điện (Min)',
        inputs: {
          'R_A': parseInput(rCdACtrl.text),
          'R_B': parseInput(rCdBCtrl.text),
          'R_C': parseInput(rCdCCtrl.text)
        },
        result: minRcd!,
        unit: 'MΩ', // Hoặc GΩ
      ));
    }

    if (maxRtx != null) {
      double resolution = parseInput(resolutionCtrl.text);
      String uBString = '';
      if (resolution > 0) {
        double uB = resolution / (2 * sqrt(3));
        uBString = ' (uB: ${uB.toStringAsFixed(4)})';
      }

      cals.add(TestCalculation(
        name: 'Điện trở tiếp xúc (Max)',
        inputs: {
          'R_txA': parseInput(rTxACtrl.text),
          'R_txB': parseInput(rTxBCtrl.text),
          'R_txC': parseInput(rTxCCtrl.text),
        },
        result: maxRtx!,
        unit: 'μΩ$uBString', 
      ));
    }

    if (timeResult != null) {
      cals.add(TestCalculation(
        name: _actionType == 'Close' ? 'Độ không đồng thời (Đóng)' : 'Độ không đồng thời (Cắt)',
        inputs: {
          't_A': parseInput(tACtrl.text),
          't_B': parseInput(tBCtrl.text),
          't_C': parseInput(tCCtrl.text)
        },
        result: timeResult!,
        unit: 'ms',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Chưa có thông số nào được tính. Hãy bấm nút tính tính toán trước nghen!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {String hint = '', bool isExpanded = true}) {
    final field = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
        ),
      ),
    );
    return isExpanded ? Expanded(child: field) : field;
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = 0;
    if (minRcd != null) pendingCount++;
    if (maxRtx != null) pendingCount++;
    if (timeResult != null) pendingCount++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TÍNH TOÁN MÁY CẮT'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAllNotes,
        backgroundColor:
            pendingCount > 0 ? AppTheme.myOrangeAccent : Colors.grey,
        icon: const Icon(Icons.bookmark_add),
        label: Text('Lưu Sổ ($pendingCount)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // MODULE 1: ĐIỆN TRỞ CÁCH ĐIỆN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('ĐIỆN TRỞ CÁCH ĐIỆN (MΩ)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rCdACtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rCdBCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rCdCCtrl),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhCachDien,
                      child: const Text('CẬP NHẬT Rcd'),
                    ),
                    if (minRcd != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rcd thấp nhất: ${minRcd!.toStringAsFixed(0)} MΩ',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE 2: ĐIỆN TRỞ TIẾP XÚC
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('ĐIỆN TRỞ TIẾP XÚC (μΩ)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rTxACtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rTxBCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rTxCCtrl),
                      ],
                    ),
                    _buildTextField('Độ phân giải thiết bị đo', resolutionCtrl, hint: 'VD: 0.1', isExpanded: false),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhTiepXuc,
                      child: const Text('CẬP NHẬT Rtx'),
                    ),
                    if (maxRtx != null) ...[
                       Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rtx cao nhất: ${maxRtx!.toStringAsFixed(1)} μΩ',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                       Builder(
                         builder: (context) {
                           double res = parseInput(resolutionCtrl.text);
                           if (res > 0) {
                             double uB = res / (2 * sqrt(3));
                             return Padding(
                               padding: const EdgeInsets.only(top: 4.0),
                               child: Text(
                                 '(uB: ${uB.toStringAsFixed(4)})',
                                 style: const TextStyle(color: Colors.grey, fontSize: 14),
                                 textAlign: TextAlign.center,
                               ),
                             );
                           }
                           return const SizedBox.shrink();
                         }
                       )
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE 3: ĐỘ KHÔNG ĐỒNG THỜI
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('ĐỘ KHÔNG ĐỒNG THỜI THỜI GIAN (ms)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A (ms)', tACtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B (ms)', tBCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C (ms)', tCCtrl),
                      ],
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Thao tác: ',
                            style: TextStyle(fontSize: 16)),
                        Radio<String>(
                          value: 'Close',
                          groupValue: _actionType,
                          activeColor: AppTheme.myOrangeAccent,
                          onChanged: (val) => setState(() => _actionType = val!),
                        ),
                        const Text('Đóng'),
                        Radio<String>(
                          value: 'Open',
                          groupValue: _actionType,
                          activeColor: AppTheme.myOrangeAccent,
                          onChanged: (val) => setState(() => _actionType = val!),
                        ),
                        const Text('Cắt'),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: _tinhThoiGian,
                      child: const Text('TÍNH Δt'),
                    ),
                    if (timeResult != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                            color: AppTheme.myMedNavy,
                            borderRadius: BorderRadius.circular(12)),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Δt = ',
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold)),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('${timeResult!.toStringAsFixed(3)} ms',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayMedium?.copyWith(
                                          color: hasTimeWarning ? Colors.redAccent : Colors.lightGreenAccent
                                        )),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (hasTimeWarning)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                              'CẢNH BÁO: Δt vượt ngưỡng cho phép (${_actionType == 'Close' ? '4ms' : '2ms'})!',
                              style: const TextStyle(
                                  color: Colors.redAccent,
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
