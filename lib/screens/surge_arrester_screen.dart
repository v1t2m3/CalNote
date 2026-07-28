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
  // Module 1: Dòng rò
  final TextEditingController iDoCtrl = TextEditingController();
  final TextEditingController tDoCtrl = TextEditingController();
  final TextEditingController tTcCtrl = TextEditingController(text: '20');
  final TextEditingController resolutionCtrl = TextEditingController();
  final TextEditingController iRCtrl = TextEditingController();
  final TextEditingController iCCtrl = TextEditingController();

  double? iResult;
  double? iTotalCalc;
  double? iR20Calc;

  // Module 2: Điện áp rò 1mA
  final TextEditingController uDo1mACtrl = TextEditingController();
  final TextEditingController uDm1mACtrl = TextEditingController();
  double? u1mAError;

  // Module 3: Cách điện đế & Quả chống sét
  final TextEditingController rCdLaCtrl = TextEditingController();
  final TextEditingController rCdBaseCtrl = TextEditingController();
  double? minRcdLa;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  void _tinhDongRo() {
    double iDo = parseInput(iDoCtrl.text);
    double tDo = parseInput(tDoCtrl.text);
    double tTc = parseInput(tTcCtrl.text);
    double iR = parseInput(iRCtrl.text);
    double iC = parseInput(iCCtrl.text);

    try {
      // 1. Quy đổi dòng rò tổng
      if (iDoCtrl.text.isNotEmpty && tDoCtrl.text.isNotEmpty) {
        final model = FormulaService.getFormulaById('LA_Leakage_Current');
        if (model != null) {
          iResult = FormulaService.calculate(
              model.formula, {'I_do': iDo, 'T_do': tDo, 'T_tc': tTc});
        } else {
          iResult = iDo / pow(1.5, (tDo - tTc) / 10);
        }
      } else {
        iResult = null;
      }

      // 2. Tính tổng dòng rò từ Ir và Ic: I_total = sqrt(Ir^2 + Ic^2)
      if (iRCtrl.text.isNotEmpty && iCCtrl.text.isNotEmpty) {
        final modelOp = FormulaService.getFormulaById('LA_Operating_Leakage');
        if (modelOp != null) {
          iTotalCalc = FormulaService.calculate(
              modelOp.formula, {'I_r': iR, 'I_c': iC});
        } else {
          iTotalCalc = sqrt(pow(iR, 2) + pow(iC, 2));
        }
      } else {
        iTotalCalc = null;
      }

      // 3. Quy đổi dòng rò điện trở Ir về 20°C: Ir20 = Ir / 1.1^((t-20)/10)
      if (iRCtrl.text.isNotEmpty && tDoCtrl.text.isNotEmpty) {
        final modelIr = FormulaService.getFormulaById('LA_Ir_20');
        if (modelIr != null) {
          iR20Calc = FormulaService.calculate(
              modelIr.formula, {'I_r': iR, 'T_do': tDo});
        } else {
          iR20Calc = iR / pow(1.1, (tDo - 20) / 10);
        }
      } else {
        iR20Calc = null;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tính dòng rò LA: $e')));
    }
  }

  void _tinhU1mA() {
    double uDo = parseInput(uDo1mACtrl.text);
    double uDm = parseInput(uDm1mACtrl.text);

    if (uDo1mACtrl.text.isEmpty || uDm1mACtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập U_đo và U_đm (1mA)!')));
      return;
    }

    try {
      final model = FormulaService.getFormulaById('LA_Ref_Voltage_Error');
      if (model != null) {
        u1mAError = FormulaService.calculate(
            model.formula, {'U_do': uDo, 'U_dm': uDm});
      } else {
        u1mAError = ((uDo - uDm) / uDm) * 100;
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tính sai số U_1mA: $e')));
    }
  }

  void _tinhCachDien() {
    double rLa = parseInput(rCdLaCtrl.text);
    double rBase = parseInput(rCdBaseCtrl.text);

    List<double> vals = [];
    if (rCdLaCtrl.text.isNotEmpty) vals.add(rLa);
    if (rCdBaseCtrl.text.isNotEmpty) vals.add(rBase);

    if (vals.isNotEmpty) {
      minRcdLa = vals.reduce(min);
    } else {
      minRcdLa = null;
    }
    setState(() {});
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

    if (iTotalCalc != null) {
      cals.add(TestCalculation(
        name: 'Dòng rò tổng LA (Ir + Ic)',
        inputs: {
          'I_r': parseInput(iRCtrl.text),
          'I_c': parseInput(iCCtrl.text),
        },
        result: iTotalCalc!,
        unit: 'mA',
      ));
    }

    if (iR20Calc != null) {
      cals.add(TestCalculation(
        name: 'Dòng rò điện trở Ir (20°C)',
        inputs: {
          'I_r': parseInput(iRCtrl.text),
          'T_do': parseInput(tDoCtrl.text),
        },
        result: iR20Calc!,
        unit: 'µA',
      ));
    }

    if (u1mAError != null) {
      cals.add(TestCalculation(
        name: 'Sai số điện áp rò U_1mA',
        inputs: {
          'U_do': parseInput(uDo1mACtrl.text),
          'U_dm': parseInput(uDm1mACtrl.text),
        },
        result: u1mAError!,
        unit: '%',
      ));
    }

    if (minRcdLa != null) {
      cals.add(TestCalculation(
        name: 'Điện trở cách điện LA (Min)',
        inputs: {
          if (rCdLaCtrl.text.isNotEmpty) 'R_LA': parseInput(rCdLaCtrl.text),
          if (rCdBaseCtrl.text.isNotEmpty)
            'R_Đế': parseInput(rCdBaseCtrl.text),
        },
        result: minRcdLa!,
        unit: 'MΩ',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Vui lòng thực hiện tính toán trước khi lưu!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Chống Sét Van (LA)',
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {String hint = '', bool isExpanded = true}) {
    final field = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        ),
      ),
    );
    return isExpanded ? Expanded(child: field) : field;
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = 0;
    if (iResult != null) pendingCount++;
    if (iTotalCalc != null) pendingCount++;
    if (u1mAError != null) pendingCount++;
    if (minRcdLa != null) pendingCount++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TÍNH TOÁN CHỐNG SÉT VAN (LA)'),
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
            // MODULE 1: QUY ĐỔI & PHÂN TÁCH DÒNG RÒ -----------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('1. DÒNG RÒ VẬN HÀNH & QUY ĐỔI (mA)',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('I_đo (mA)', iDoCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('T_đo (°C)', tDoCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('T_tc (°C)', tTcCtrl),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTextField('Dòng điện trở Ir (µA)', iRCtrl,
                            hint: 'Ir (µA)'),
                        const SizedBox(width: 8),
                        _buildTextField('Dòng điện dung Ic (mA)', iCCtrl,
                            hint: 'Ic (mA)'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                        'Độ phân giải máy đo (uB)', resolutionCtrl,
                        hint: 'VD: 0.001', isExpanded: false),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhDongRo,
                      child: const Text('TÍNH & QUY ĐỔI DÒNG RÒ'),
                    ),
                    if (iResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'I_tc quy đổi: ${iResult!.toStringAsFixed(3)} mA',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (iTotalCalc != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Dòng rò tổng I_total: ${iTotalCalc!.toStringAsFixed(3)} mA',
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (iR20Calc != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Ir20 quy đổi 20°C: ${iR20Calc!.toStringAsFixed(1)} µA',
                          style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 2: SAI SỐ ĐIỆN ÁP RÒ 1mA ----------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('2. ĐIỆN ÁP RÒ 1mA (U_1mA)',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('U_1mA đo (kV)', uDo1mACtrl),
                        const SizedBox(width: 8),
                        _buildTextField('U_1mA định mức (kV)', uDm1mACtrl),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhU1mA,
                      child: const Text('TÍNH SAI SỐ U_1mA (%)'),
                    ),
                    if (u1mAError != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Sai số ΔU_1mA: ${u1mAError! >= 0 ? "+" : ""}${u1mAError!.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: u1mAError!.abs() <= 5.0
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        u1mAError!.abs() <= 5.0
                            ? '✓ Đạt tiêu chuẩn (|ΔU| ≤ 5%)'
                            : '⚠️ Vượt ngưỡng cho phép (|ΔU| > 5%)',
                        style: TextStyle(
                          color: u1mAError!.abs() <= 5.0
                              ? Colors.lightGreenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 3: ĐIỆN TRỞ CÁCH ĐIỆN & ĐẾ BỘ ĐẾM SẾT ------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('3. ĐIỆN TRỞ CÁCH ĐIỆN & ĐẾ CÁCH ĐIỆN',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('R_cd Quả LA (MΩ)', rCdLaCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('R_cd Đế chống sét (MΩ)', rCdBaseCtrl),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhCachDien,
                      child: const Text('CẬP NHẬT R_cd LA'),
                    ),
                    if (minRcdLa != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'R_cd Min: ${minRcdLa!.toStringAsFixed(0)} MΩ',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )
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
