import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../services/calibration_service.dart';
import '../widgets/uncertainty_widget.dart';
import '../widgets/standard_evaluation_widget.dart';
import '../widgets/equipment_icon_widget.dart';
import '../widgets/formula_selector_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_formatters.dart';
import 'note_detail_screen.dart';

/// Màn hình Tính toán & Đối chiếu Tiêu chuẩn Thử nghiệm RECLOSER / LBS / RMU
class RecloserCalculatorScreen extends StatefulWidget {
  const RecloserCalculatorScreen({super.key});

  @override
  State<RecloserCalculatorScreen> createState() => _RecloserCalculatorScreenState();
}

class _RecloserCalculatorScreenState extends State<RecloserCalculatorScreen> {
  String _deviceType = 'Recloser'; // Recloser, LBS, RMU
  String _voltageLevel = '<=35kV';

  // 1. Điện trở cách điện Rcđ (MΩ)
  final TextEditingController rCdACtrl = TextEditingController();
  final TextEditingController rCdBCtrl = TextEditingController();
  final TextEditingController rCdCCtrl = TextEditingController();
  double? minRcd;

  // 2. Điện trở tiếp xúc Rtx (μΩ)
  final TextEditingController rTxACtrl = TextEditingController();
  final TextEditingController rTxBCtrl = TextEditingController();
  final TextEditingController rTxCCtrl = TextEditingController();
  final TextEditingController rTxNsxCtrl = TextEditingController();
  double? maxRtx;
  double? deltaRtx; // %
  FormulaModel? _selectedRtxFormula;
  CalibratedEquipmentModel? _selectedRtxEquipment;
  UncertaintyResult? _rtxUncertaintyResult;
  Map<String, UncertaintyResult?> _rtxPhaseUncertainty = {};

  // 3. Thời gian thao tác & độ không đồng pha (ms)
  final TextEditingController tACtrl = TextEditingController();
  final TextEditingController tBCtrl = TextEditingController();
  final TextEditingController tCCtrl = TextEditingController();
  String _actionType = 'Close';
  double? timeResult; // delta t (ms)

  @override
  void initState() {
    super.initState();
    final eqs = CalibrationService.getEquipmentsForTest('REC_R_tx');
    if (eqs.isNotEmpty) {
      _selectedRtxEquipment = eqs.first;
    } else {
      final fallbackEqs = CalibrationService.getEquipmentsForTest('MC_R_tx');
      if (fallbackEqs.isNotEmpty) _selectedRtxEquipment = fallbackEqs.first;
    }

    final recFormulas = FormulaService.getFormulasByGroup('REC_R_tx');
    if (recFormulas.isNotEmpty) {
      _selectedRtxFormula = recFormulas.first;
    }
  }

  double parseInput(String val) => AppFormatters.parseInput(val);

  void _tinhCachDien() {
    double rA = parseInput(rCdACtrl.text);
    double rB = parseInput(rCdBCtrl.text);
    double rC = parseInput(rCdCCtrl.text);

    if (rCdACtrl.text.isEmpty && rCdBCtrl.text.isEmpty && rCdCCtrl.text.isEmpty) {
      minRcd = null;
    } else {
      List<double> vals = [];
      if (rCdACtrl.text.isNotEmpty) vals.add(rA);
      if (rCdBCtrl.text.isNotEmpty) vals.add(rB);
      if (rCdCCtrl.text.isNotEmpty) vals.add(rC);
      minRcd = vals.isNotEmpty ? vals.reduce(min) : null;
    }
    setState(() {});
  }

  void _tinhTiepXuc() {
    double rA = parseInput(rTxACtrl.text);
    double rB = parseInput(rTxBCtrl.text);
    double rC = parseInput(rTxCCtrl.text);
    double rNsx = parseInput(rTxNsxCtrl.text);

    List<double> vals = [];
    if (rTxACtrl.text.isNotEmpty) vals.add(rA);
    if (rTxBCtrl.text.isNotEmpty) vals.add(rB);
    if (rTxCCtrl.text.isNotEmpty) vals.add(rC);

    if (vals.isEmpty) {
      maxRtx = null;
      deltaRtx = null;
      _rtxUncertaintyResult = null;
      _rtxPhaseUncertainty = {};
    } else {
      maxRtx = vals.reduce(max);
      double mn = vals.reduce(min);
      double avg = vals.reduce((a, b) => a + b) / vals.length;

      final formula = _selectedRtxFormula ?? FormulaService.getFormulaById('REC_Rtx_Delta_Nsx');
      if (formula != null) {
        try {
          final vars = <String, num>{
            'R_max': maxRtx!,
            'R_min': mn,
            'R_avg': avg,
            'R_nsx': rNsx > 0 ? rNsx : (mn > 0 ? mn : 1.0),
          };
          deltaRtx = FormulaService.calculate(formula.formula, vars);
        } catch (_) {
          deltaRtx = null;
        }
      } else {
        deltaRtx = avg > 0 ? ((maxRtx! - mn) / avg) * 100.0 : 0.0;
      }

      if (CalibrationService.isUncertaintyEnabled) {
        final eq = _selectedRtxEquipment;
        if (eq != null) {
          _rtxPhaseUncertainty = {};
          if (rTxACtrl.text.isNotEmpty) {
            _rtxPhaseUncertainty['Pha A'] = CalibrationService.calculateUncertainty(
              equipment: eq,
              measuredValue: rA,
              unit: 'µΩ',
            );
          }
          if (rTxBCtrl.text.isNotEmpty) {
            _rtxPhaseUncertainty['Pha B'] = CalibrationService.calculateUncertainty(
              equipment: eq,
              measuredValue: rB,
              unit: 'µΩ',
            );
          }
          if (rTxCCtrl.text.isNotEmpty) {
            _rtxPhaseUncertainty['Pha C'] = CalibrationService.calculateUncertainty(
              equipment: eq,
              measuredValue: rC,
              unit: 'µΩ',
            );
          }
          _rtxUncertaintyResult = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: maxRtx!,
            unit: 'µΩ',
          );
        }
      } else {
        _rtxPhaseUncertainty = {};
        _rtxUncertaintyResult = null;
      }
    }
    setState(() {});
  }

  void _tinhThoiGian() {
    double tA = parseInput(tACtrl.text);
    double tB = parseInput(tBCtrl.text);
    double tC = parseInput(tCCtrl.text);

    if (tACtrl.text.isEmpty && tBCtrl.text.isEmpty && tCCtrl.text.isEmpty) {
      timeResult = null;
      return;
    }

    List<double> vals = [];
    if (tACtrl.text.isNotEmpty) vals.add(tA);
    if (tBCtrl.text.isNotEmpty) vals.add(tB);
    if (tCCtrl.text.isNotEmpty) vals.add(tC);

    if (vals.length > 1) {
      double tMax = vals.reduce(max);
      double tMin = vals.reduce(min);
      timeResult = tMax - tMin;
    } else {
      timeResult = 0.0;
    }
    setState(() {});
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    if (minRcd != null) {
      cals.add(TestCalculation(
        name: 'Điện trở cách điện $_deviceType (Rcđ)',
        inputs: {
          'Rcd_A': parseInput(rCdACtrl.text),
          'Rcd_B': parseInput(rCdBCtrl.text),
          'Rcd_C': parseInput(rCdCCtrl.text),
        },
        result: minRcd!,
        unit: 'MΩ',
      ));
    }

    if (maxRtx != null) {
      cals.add(TestCalculation(
        name: 'Điện trở tiếp xúc $_deviceType (Rtx)',
        inputs: {
          'Rtx_A': parseInput(rTxACtrl.text),
          'Rtx_B': parseInput(rTxBCtrl.text),
          'Rtx_C': parseInput(rTxCCtrl.text),
          if (rTxNsxCtrl.text.isNotEmpty) 'R_nsx': parseInput(rTxNsxCtrl.text),
        },
        result: maxRtx!,
        unit: 'μΩ',
      ));

      if (deltaRtx != null) {
        cals.add(TestCalculation(
          name: 'Độ lệch tiếp xúc $_deviceType ΔRtx (${_selectedRtxFormula?.method ?? 'Mặc định'})',
          inputs: {
            'R_max': maxRtx!,
            if (rTxNsxCtrl.text.isNotEmpty) 'R_nsx': parseInput(rTxNsxCtrl.text),
          },
          result: deltaRtx!,
          unit: '%',
        ));
      }
    }

    if (timeResult != null) {
      cals.add(TestCalculation(
        name: 'Thời gian thao tác $_deviceType (${_actionType == 'Close' ? 'Đóng' : 'Cắt'})',
        inputs: {
          't_A': parseInput(tACtrl.text),
          't_B': parseInput(tBCtrl.text),
          't_C': parseInput(tCCtrl.text),
        },
        result: timeResult!,
        unit: 'ms',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tính toán ít nhất một phép đo trước khi lưu!')),
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
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
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
        title: Row(
          children: [
            const EquipmentIconWidget(categoryCode: 'recloser_lbs', size: 26),
            const SizedBox(width: 10),
            Text('TÍNH TOÁN $_deviceType'.toUpperCase(),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAllNotes,
        backgroundColor: AppTheme.myOrangeAccent,
        icon: const Icon(Icons.bookmark_add, color: Colors.white),
        label: Text(
          pendingCount > 0 ? 'Lưu Tổ Hợp ($pendingCount)' : 'Lưu Kết Quả',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          children: [
            // CHỌN THIẾT BỊ VÀ ĐIỆN ÁP
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const Text('Thiết bị: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(width: 8),
                        for (final type in ['Recloser', 'LBS', 'RMU']) ...[
                          ChoiceChip(
                            label: Text(type),
                            selected: _deviceType == type,
                            selectedColor: AppTheme.myOrangeAccent,
                            onSelected: (val) {
                              if (val) setState(() => _deviceType = type);
                            },
                          ),
                          const SizedBox(width: 6),
                        ],
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        const Text('Cấp điện áp: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('≤ 35kV (Mặc định)'),
                          selected: _voltageLevel == '<=35kV',
                          selectedColor: AppTheme.myOrangeAccent,
                          onSelected: (val) {
                            if (val) setState(() => _voltageLevel = '<=35kV');
                          },
                        ),
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: const Text('> 35kV'),
                          selected: _voltageLevel == '>35kV',
                          selectedColor: AppTheme.myOrangeAccent,
                          onSelected: (val) {
                            if (val) setState(() => _voltageLevel = '>35kV');
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // MODULE 1: ĐIỆN TRỞ CÁCH ĐIỆN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('1. ĐIỆN TRỞ CÁCH ĐIỆN (Rcđ - MΩ)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myOrangeAccent)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rCdACtrl, hint: 'VD: 3000'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rCdBCtrl, hint: 'VD: 3000'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rCdCCtrl, hint: 'VD: 3000'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhCachDien,
                      child: const Text('ĐÁNH GIÁ CÁCH ĐIỆN'),
                    ),
                    if (minRcd != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rcđ thấp nhất: ${AppFormatters.formatInsulation(minRcd)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      StandardEvaluationWidget(
                        testCode: 'MC_R_cd',
                        voltageLevel: _voltageLevel,
                        primaryValue: minRcd,
                        unit: 'MΩ',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN CÁCH ĐIỆN $_deviceType",
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE 2: ĐIỆN TRỞ TIẾP XÚC
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('2. ĐIỆN TRỞ TIẾP XÚC (Rtx - μΩ)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myOrangeAccent)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rTxACtrl, hint: 'VD: 42.0'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rTxBCtrl, hint: 'VD: 43.5'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rTxCCtrl, hint: 'VD: 42.8'),
                      ],
                    ),
                    FormulaSelectorWidget(
                      groupCode: 'REC_R_tx',
                      selectedFormula: _selectedRtxFormula,
                      onFormulaChanged: (newF) {
                        setState(() {
                          _selectedRtxFormula = newF;
                          if (maxRtx != null) _tinhTiepXuc();
                        });
                      },
                    ),
                    if (_selectedRtxFormula == null ||
                        _selectedRtxFormula!.inputs.contains('R_nsx'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildTextField(
                          'Rnsx (nhà sản xuất / xuất xưởng)',
                          rTxNsxCtrl,
                          hint: 'VD: 40.0',
                          isExpanded: false,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhTiepXuc,
                      child: const Text('TÍNH Rtx & ĐỘ LỆCH PHA'),
                    ),
                    if (maxRtx != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rtx Max: ${AppFormatters.formatRtx(maxRtx)}${deltaRtx != null ? ' | ΔR: ${AppFormatters.formatPercent(deltaRtx)}' : ''}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: (deltaRtx != null && deltaRtx! <= 50.0)
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      UncertaintyEquipmentSection(
                        testId: 'REC_R_tx',
                        selectedEquipment: _selectedRtxEquipment,
                        onEquipmentChanged: (newEq) {
                          setState(() {
                            _selectedRtxEquipment = newEq;
                            if (maxRtx != null) _tinhTiepXuc();
                          });
                        },
                        phaseResults: _rtxPhaseUncertainty.isNotEmpty ? _rtxPhaseUncertainty : null,
                        uncertaintyResult: _rtxUncertaintyResult,
                        standardLimit: 100.0,
                        isUpperBound: true,
                      ),
                      StandardEvaluationWidget(
                        testCode: 'MC_R_tx',
                        voltageLevel: _voltageLevel,
                        primaryValue: deltaRtx ?? 0.0,
                        phaseValues: {
                          if (rTxACtrl.text.isNotEmpty) 'Pha A': parseInput(rTxACtrl.text),
                          if (rTxBCtrl.text.isNotEmpty) 'Pha B': parseInput(rTxBCtrl.text),
                          if (rTxCCtrl.text.isNotEmpty) 'Pha C': parseInput(rTxCCtrl.text),
                        },
                        unit: '%',
                        symbol: 'ΔRtx',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN ĐỘ LỆCH TIẾP XÚC $_deviceType",
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE 3: THỜI GIAN THAO TÁC & KHÔNG ĐỒNG PHA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('3. THỜI GIAN THAO TÁC (ms)',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myOrangeAccent)),
                        DropdownButton<String>(
                          value: _actionType,
                          dropdownColor: AppTheme.myDarkNavy,
                          items: const [
                            DropdownMenuItem(value: 'Close', child: Text('Đóng (Close)', style: TextStyle(color: Colors.white))),
                            DropdownMenuItem(value: 'Open', child: Text('Cắt (Open)', style: TextStyle(color: Colors.white))),
                          ],
                          onChanged: (val) {
                            if (val != null) {
                              setState(() {
                                _actionType = val;
                                if (timeResult != null) _tinhThoiGian();
                              });
                            }
                          },
                        ),
                      ],
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('t Pha A', tACtrl, hint: 'VD: 55.2'),
                        const SizedBox(width: 8),
                        _buildTextField('t Pha B', tBCtrl, hint: 'VD: 56.0'),
                        const SizedBox(width: 8),
                        _buildTextField('t Pha C', tCCtrl, hint: 'VD: 55.8'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhThoiGian,
                      child: const Text('TÍNH ĐỘ KHÔNG ĐỒNG PHA (Δt)'),
                    ),
                    if (timeResult != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Độ không đồng pha Δt: ${AppFormatters.formatTimeMs(timeResult)}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: (_actionType == 'Close' ? timeResult! <= 4.0 : timeResult! <= 2.0)
                                ? Colors.greenAccent
                                : Colors.redAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      StandardEvaluationWidget(
                        testCode: _actionType == 'Close' ? 'MC_Time_Close' : 'MC_Time_Open',
                        voltageLevel: _voltageLevel,
                        primaryValue: timeResult,
                        unit: 'ms',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN THỜI GIAN $_deviceType",
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 70),
          ],
        ),
      ),
    );
  }
}
