import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_formatters.dart';
import 'note_detail_screen.dart';

class CableScreen extends StatefulWidget {
  const CableScreen({super.key});

  @override
  State<CableScreen> createState() => _CableScreenState();
}

class _CableScreenState extends State<CableScreen> {
  // MODULE 1: CÁCH ĐIỆN CÁP
  final TextEditingController r15sCtrl = TextEditingController();
  final TextEditingController r60sCtrl = TextEditingController();
  final TextEditingController r10mCtrl = TextEditingController();
  final TextEditingController tDoInsCtrl = TextEditingController(text: '30');
  final TextEditingController tTcInsCtrl = TextEditingController(text: '20');

  double? darResult;
  double? piResult;
  double? r60sConverted;
  String? darEval;
  String? piEval;
  Color darColor = Colors.grey;
  Color piColor = Colors.grey;

  // MODULE 2: ĐIỆN TRỞ RUỘT DẪN (R_DC)
  final TextEditingController rACtrl = TextEditingController();
  final TextEditingController rBCtrl = TextEditingController();
  final TextEditingController rCCtrl = TextEditingController();
  final TextEditingController tDoRdcCtrl = TextEditingController(text: '30');
  String _material = 'Cu'; // Cu hoặc Al

  double? rResultA, rResultB, rResultC, deltaRdc;

  // MODULE 3: THỬ CHIỆU ĐIỆN ÁP CAO (HI-POT DC / VLF)
  final TextEditingController iLeakACtrl = TextEditingController();
  final TextEditingController iLeakBCtrl = TextEditingController();
  final TextEditingController iLeakCCtrl = TextEditingController();
  final TextEditingController uTestCtrl = TextEditingController();

  double? unbalanceLeakage;

  double parseInput(String val) {
    return AppFormatters.parseInput(val);
  }

  void _tinhCachDienCap() {
    double r15 = parseInput(r15sCtrl.text);
    double r60 = parseInput(r60sCtrl.text);
    double r10 = parseInput(r10mCtrl.text);
    double tDo = parseInput(tDoInsCtrl.text);
    double tTc = parseInput(tTcInsCtrl.text);

    if (r60sCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập R_60s (MΩ)!')),
      );
      return;
    }

    try {
      // DAR
      if (r15 > 0 && r60 > 0) {
        final darModel = FormulaService.getFormulaById('INS_DAR');
        darResult = darModel != null
            ? FormulaService.calculate(
                darModel.formula, {'R_60s': r60, 'R_15s': r15})
            : (r60 / r15);

        if (darResult! < 1.0) {
          darEval = 'Kém / Không đạt (< 1.0)';
          darColor = Colors.redAccent;
        } else if (darResult! < 1.25) {
          darEval = 'Nghi ngờ (1.0 - 1.25)';
          darColor = Colors.orangeAccent;
        } else if (darResult! < 1.6) {
          darEval = 'Tốt (1.25 - 1.6)';
          darColor = Colors.lightGreenAccent;
        } else {
          darEval = 'Rất tốt (≥ 1.6)';
          darColor = Colors.greenAccent;
        }
      } else {
        darResult = null;
      }

      // PI
      if (r10 > 0 && r60 > 0) {
        final piModel = FormulaService.getFormulaById('INS_PI');
        piResult = piModel != null
            ? FormulaService.calculate(
                piModel.formula, {'R_10m': r10, 'R_1m': r60})
            : (r10 / r60);

        if (piResult! < 1.0) {
          piEval = 'Nguy hiểm / Rất kém (< 1.0)';
          piColor = Colors.redAccent;
        } else if (piResult! < 2.0) {
          piEval = 'Nghi ngờ (1.0 - 2.0)';
          piColor = Colors.orangeAccent;
        } else if (piResult! < 4.0) {
          piEval = 'Tốt (2.0 - 4.0)';
          piColor = Colors.lightGreenAccent;
        } else {
          piEval = 'Rất tốt (≥ 4.0)';
          piColor = Colors.greenAccent;
        }
      } else {
        piResult = null;
      }

      // R60s Quy đổi
      if (r60 > 0 && tDoInsCtrl.text.isNotEmpty) {
        final rcdModel = FormulaService.getFormulaById('MBA_Rcd');
        r60sConverted = rcdModel != null
            ? FormulaService.calculate(
                rcdModel.formula, {'R_do': r60, 'T_do': tDo, 'T_tc': tTc})
            : r60 * pow(1.5, (tDo - tTc) / 10);
      } else {
        r60sConverted = null;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính cách điện cáp: $e')),
      );
    }
  }

  void _tinhRdcRuotDan() {
    double rA = parseInput(rACtrl.text);
    double rB = parseInput(rBCtrl.text);
    double rC = parseInput(rCCtrl.text);
    double tDo = parseInput(tDoRdcCtrl.text);

    String formulaId =
        _material == 'Cu' ? 'CABLE_Rdc_20_Cu' : 'CABLE_Rdc_20_Al';
    final model = FormulaService.getFormulaById(formulaId);
    double kMat = _material == 'Cu' ? 235.0 : 228.0;

    try {
      if (rACtrl.text.isNotEmpty) {
        rResultA = model != null
            ? FormulaService.calculate(
                model.formula, {'R_do': rA, 'T_do': tDo})
            : rA * ((kMat + 20) / (kMat + tDo));
      } else {
        rResultA = null;
      }

      if (rBCtrl.text.isNotEmpty) {
        rResultB = model != null
            ? FormulaService.calculate(
                model.formula, {'R_do': rB, 'T_do': tDo})
            : rB * ((kMat + 20) / (kMat + tDo));
      } else {
        rResultB = null;
      }

      if (rCCtrl.text.isNotEmpty) {
        rResultC = model != null
            ? FormulaService.calculate(
                model.formula, {'R_do': rC, 'T_do': tDo})
            : rC * ((kMat + 20) / (kMat + tDo));
      } else {
        rResultC = null;
      }

      List<double> validRs = [];
      if (rResultA != null) validRs.add(rResultA!);
      if (rResultB != null) validRs.add(rResultB!);
      if (rResultC != null) validRs.add(rResultC!);

      if (validRs.length > 1) {
        double maxR = validRs.reduce(max);
        double minR = validRs.reduce(min);
        double avgR = validRs.reduce((a, b) => a + b) / validRs.length;

        final errModel = FormulaService.getFormulaById('MBA_Unbalance');
        deltaRdc = errModel != null
            ? FormulaService.calculate(
                errModel.formula, {'R_max': maxR, 'R_min': minR, 'R_avg': avgR})
            : ((maxR - minR) / avgR) * 100;
      } else {
        deltaRdc = null;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính điện trở ruột dẫn: $e')),
      );
    }
  }

  void _tinhHiPotUnbalance() {
    double iA = parseInput(iLeakACtrl.text);
    double iB = parseInput(iLeakBCtrl.text);
    double iC = parseInput(iLeakCCtrl.text);

    List<double> iList = [];
    if (iLeakACtrl.text.isNotEmpty) iList.add(iA);
    if (iLeakBCtrl.text.isNotEmpty) iList.add(iB);
    if (iLeakCCtrl.text.isNotEmpty) iList.add(iC);

    if (iList.length > 1) {
      double maxI = iList.reduce(max);
      double minI = iList.reduce(min);

      if (minI > 0) {
        final model = FormulaService.getFormulaById('CABLE_Unbalance');
        unbalanceLeakage = model != null
            ? FormulaService.calculate(
                model.formula, {'I_max': maxI, 'I_min': minI})
            : ((maxI - minI) / minI) * 100;
      } else {
        unbalanceLeakage = null;
      }
    } else {
      unbalanceLeakage = null;
    }

    setState(() {});
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    if (darResult != null) {
      cals.add(TestCalculation(
        name: 'DAR Cáp lực (R60s/R15s)',
        inputs: {
          'R_15s': parseInput(r15sCtrl.text),
          'R_60s': parseInput(r60sCtrl.text),
        },
        result: darResult!,
        unit: '(${darEval?.split(' ')[0] ?? ''})',
      ));
    }

    if (piResult != null) {
      cals.add(TestCalculation(
        name: 'PI Cáp lực (R10m/R1m)',
        inputs: {
          'R_1m': parseInput(r60sCtrl.text),
          'R_10m': parseInput(r10mCtrl.text),
        },
        result: piResult!,
        unit: '(${piEval?.split(' ')[0] ?? ''})',
      ));
    }

    if (rResultA != null || rResultB != null || rResultC != null) {
      cals.add(TestCalculation(
        name: 'Điện trở ruột dẫn Cáp 20°C ($_material)',
        inputs: {
          if (rACtrl.text.isNotEmpty) 'Ra': parseInput(rACtrl.text),
          if (rBCtrl.text.isNotEmpty) 'Rb': parseInput(rBCtrl.text),
          if (rCCtrl.text.isNotEmpty) 'Rc': parseInput(rCCtrl.text),
          'T_đo': parseInput(tDoRdcCtrl.text),
        },
        result: deltaRdc ?? max(rResultA ?? 0, max(rResultB ?? 0, rResultC ?? 0)),
        unit: deltaRdc != null ? '% độ lệch' : 'mΩ',
      ));
    }

    if (unbalanceLeakage != null) {
      cals.add(TestCalculation(
        name: 'Bất cân bằng dòng rò Hi-Pot Cáp',
        inputs: {
          if (iLeakACtrl.text.isNotEmpty) 'I_A': parseInput(iLeakACtrl.text),
          if (iLeakBCtrl.text.isNotEmpty) 'I_B': parseInput(iLeakBCtrl.text),
          if (iLeakCCtrl.text.isNotEmpty) 'I_C': parseInput(iLeakCCtrl.text),
        },
        result: unbalanceLeakage!,
        unit: '%',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có phép tính nào để lưu nghen!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Thử nghiệm Cáp Lực',
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
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        ),
      ),
    );
    return isExpanded ? Expanded(child: field) : field;
  }

  @override
  Widget build(BuildContext context) {
    int count = 0;
    if (darResult != null || piResult != null) count++;
    if (rResultA != null || rResultB != null || rResultC != null) count++;
    if (unbalanceLeakage != null) count++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('THỬ NGHIỆM CÁP LỰC'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAllNotes,
        backgroundColor: count > 0 ? AppTheme.myOrangeAccent : Colors.grey,
        icon: const Icon(Icons.bookmark_add),
        label: Text('Lưu Tổ Hợp ($count)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // MODULE 1: ĐIỆN TRỞ CÁCH ĐIỆN CÁP
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '1. ĐIỆN TRỞ CÁCH ĐIỆN CÁP (MΩ)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('R_15s (MΩ)', r15sCtrl, hint: 'VD: 1500'),
                        const SizedBox(width: 8),
                        _buildTextField('R_60s (MΩ)', r60sCtrl, hint: 'VD: 2500'),
                        const SizedBox(width: 8),
                        _buildTextField('R_10m (MΩ)', r10mCtrl, hint: 'VD: 6000'),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTextField('T_đo (°C)', tDoInsCtrl, hint: 'VD: 30'),
                        const SizedBox(width: 8),
                        _buildTextField('T_tc (°C)', tTcInsCtrl, hint: 'VD: 20'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhCachDienCap,
                      child: const Text('TÍNH DAR, PI & QUY ĐỔI R60s'),
                    ),
                    if (darResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'DAR: ${AppFormatters.formatDarPi(darResult!)} - $darEval',
                            style: TextStyle(
                                color: darColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    if (piResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'PI: ${AppFormatters.formatDarPi(piResult!)} - $piEval',
                            style: TextStyle(
                                color: piColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                    if (r60sConverted != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'R60s (20°C): ${AppFormatters.formatInsulation(r60sConverted!)} MΩ',
                            style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 16),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 2: ĐIỆN TRỞ RUỘT DẪN (R_DC)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '2. ĐIỆN TRỞ RUỘT DẪN QUY ĐỔI 20°C (mΩ)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Vật liệu: '),
                        ChoiceChip(
                          label: const Text('Đồng (Cu)'),
                          selected: _material == 'Cu',
                          onSelected: (val) =>
                              setState(() => _material = 'Cu'),
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('Nhôm (Al)'),
                          selected: _material == 'Al',
                          onSelected: (val) =>
                              setState(() => _material = 'Al'),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTextField('Ra (mΩ)', rACtrl, hint: 'VD: 12.345'),
                        const SizedBox(width: 8),
                        _buildTextField('Rb (mΩ)', rBCtrl, hint: 'VD: 12.360'),
                        const SizedBox(width: 8),
                        _buildTextField('Rc (mΩ)', rCCtrl, hint: 'VD: 12.352'),
                      ],
                    ),
                    _buildTextField('T_đo (°C)', tDoRdcCtrl,
                        hint: 'VD: 30', isExpanded: false),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhRdcRuotDan,
                      child: const Text('QUY ĐỔI R_DC VỀ 20°C'),
                    ),
                    if (rResultA != null || rResultB != null || rResultC != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                if (rResultA != null)
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Ra: ${rResultA!.toStringAsFixed(3)} mΩ',
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                if (rResultB != null)
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Rb: ${rResultB!.toStringAsFixed(3)} mΩ',
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ),
                                  ),
                                const SizedBox(width: 6),
                                if (rResultC != null)
                                  Flexible(
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        'Rc: ${rResultC!.toStringAsFixed(3)} mΩ',
                                        style: const TextStyle(
                                            color: Colors.greenAccent,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            if (deltaRdc != null) ...[
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  'ΔR = ${deltaRdc!.toStringAsFixed(2)}% ${deltaRdc! <= 2.0 ? "(✓ Đạt ≤2%)" : "(⚠️ Cảnh báo >2%)"}',
                                  style: TextStyle(
                                      color: deltaRdc! <= 2.0
                                          ? Colors.lightGreenAccent
                                          : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 3: THỬ CHIỆU ĐIỆN ÁP CAO & DÒNG RÒ (HI-POT DC / VLF)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '3. THỬ CHỊU ĐIỆN ÁP CAO & DÒNG RÒ (HI-POT DC / VLF)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    _buildTextField('Điện áp thử U_test (kV)', uTestCtrl,
                        hint: 'VD: 25.0', isExpanded: false),
                    Row(
                      children: [
                        _buildTextField('I_rò Pha A (µA)', iLeakACtrl, hint: 'VD: 2.5'),
                        const SizedBox(width: 8),
                        _buildTextField('I_rò Pha B (µA)', iLeakBCtrl, hint: 'VD: 2.8'),
                        const SizedBox(width: 8),
                        _buildTextField('I_rò Pha C (µA)', iLeakCCtrl, hint: 'VD: 2.6'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhHiPotUnbalance,
                      child: const Text('TÍNH BẤT CÂN BẰNG DÒNG RÒ (%)'),
                    ),
                    if (unbalanceLeakage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Bất cân bằng dòng rò ΔI: ${unbalanceLeakage!.toStringAsFixed(2)}%',
                            style: const TextStyle(
                                color: Colors.cyanAccent,
                                fontSize: 18,
                                fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
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
