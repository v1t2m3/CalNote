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

/// Màn hình Tính toán & Đối chiếu Tiêu chuẩn Thử nghiệm DAO CÁCH LY
class DisconnectorCalculatorScreen extends StatefulWidget {
  const DisconnectorCalculatorScreen({super.key});

  @override
  State<DisconnectorCalculatorScreen> createState() => _DisconnectorCalculatorScreenState();
}

class _DisconnectorCalculatorScreenState extends State<DisconnectorCalculatorScreen> {
  String _dclVoltageLevel = '>35kV';

  // 1. Điện trở cách điện Rcđ (MΩ)
  final TextEditingController rCdACtrl = TextEditingController();
  final TextEditingController rCdBCtrl = TextEditingController();
  final TextEditingController rCdCCtrl = TextEditingController();
  double? minRcd;

  // 2. Điện trở tiếp xúc lưỡi dao / ngàm Rtx (μΩ)
  final TextEditingController rTxACtrl = TextEditingController();
  final TextEditingController rTxBCtrl = TextEditingController();
  final TextEditingController rTxCCtrl = TextEditingController();
  final TextEditingController rTxNsxCtrl = TextEditingController();
  double? maxRtx;
  double? deltaRtx; // Độ lệch giữa các pha (%)
  FormulaModel? _selectedRtxFormula;
  CalibratedEquipmentModel? _selectedRtxEquipment;
  UncertaintyResult? _rtxUncertaintyResult;
  Map<String, UncertaintyResult?> _rtxPhaseUncertainty = {};

  // 3. Điện trở tiếp xúc Dao tiếp địa Rtx DTD (μΩ)
  final TextEditingController rTxDtdACtrl = TextEditingController();
  final TextEditingController rTxDtdBCtrl = TextEditingController();
  final TextEditingController rTxDtdCCtrl = TextEditingController();
  final TextEditingController rTxDtdNsxCtrl = TextEditingController();
  double? maxRtxDtd;
  double? deltaRtxDtd;
  FormulaModel? _selectedDtdFormula;
  CalibratedEquipmentModel? _selectedDtdEquipment;
  UncertaintyResult? _dtdUncertaintyResult;
  Map<String, UncertaintyResult?> _dtdPhaseUncertainty = {};

  @override
  void initState() {
    super.initState();
    final eqs = CalibrationService.getEquipmentsForTest('DCL_R_tx');
    if (eqs.isNotEmpty) {
      _selectedRtxEquipment = eqs.first;
    } else {
      final fallbackEqs = CalibrationService.getEquipmentsForTest('MC_R_tx');
      if (fallbackEqs.isNotEmpty) _selectedRtxEquipment = fallbackEqs.first;
    }

    final dclFormulas = FormulaService.getFormulasByGroup('DCL_R_tx');
    if (dclFormulas.isNotEmpty) {
      _selectedRtxFormula = dclFormulas.first;
    }

    final dtdEqs = CalibrationService.getEquipmentsForTest('DTD_R_tx');
    if (dtdEqs.isNotEmpty) {
      _selectedDtdEquipment = dtdEqs.first;
    } else if (_selectedRtxEquipment != null) {
      _selectedDtdEquipment = _selectedRtxEquipment;
    }

    final dtdFormulas = FormulaService.getFormulasByGroup('DTD_R_tx');
    if (dtdFormulas.isNotEmpty) {
      _selectedDtdFormula = dtdFormulas.first;
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

      final formula = _selectedRtxFormula ?? FormulaService.getFormulaById('DCL_Rtx_Delta_Nsx');
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
        final dclEqs = CalibrationService.getEquipmentsForTest('DCL_R_tx');
        final eq = _selectedRtxEquipment ?? (dclEqs.isNotEmpty ? dclEqs.first : null);
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

  void _tinhTiepXucDtd() {
    double rA = parseInput(rTxDtdACtrl.text);
    double rB = parseInput(rTxDtdBCtrl.text);
    double rC = parseInput(rTxDtdCCtrl.text);
    double rNsx = parseInput(rTxDtdNsxCtrl.text);

    List<double> vals = [];
    if (rTxDtdACtrl.text.isNotEmpty) vals.add(rA);
    if (rTxDtdBCtrl.text.isNotEmpty) vals.add(rB);
    if (rTxDtdCCtrl.text.isNotEmpty) vals.add(rC);

    if (vals.isEmpty) {
      maxRtxDtd = null;
      deltaRtxDtd = null;
      _dtdUncertaintyResult = null;
      _dtdPhaseUncertainty = {};
    } else {
      maxRtxDtd = vals.reduce(max);
      double mn = vals.reduce(min);
      double avg = vals.reduce((a, b) => a + b) / vals.length;

      final formula = _selectedDtdFormula ?? FormulaService.getFormulaById('DTD_Rtx_Delta_Nsx');
      if (formula != null) {
        try {
          final vars = <String, num>{
            'R_max': maxRtxDtd!,
            'R_min': mn,
            'R_avg': avg,
            'R_nsx': rNsx > 0 ? rNsx : (mn > 0 ? mn : 1.0),
          };
          deltaRtxDtd = FormulaService.calculate(formula.formula, vars);
        } catch (_) {
          deltaRtxDtd = null;
        }
      } else {
        deltaRtxDtd = avg > 0 ? ((maxRtxDtd! - mn) / avg) * 100.0 : 0.0;
      }

      if (CalibrationService.isUncertaintyEnabled) {
        final dtdEqs = CalibrationService.getEquipmentsForTest('DTD_R_tx');
        final eq = _selectedDtdEquipment ?? (dtdEqs.isNotEmpty ? dtdEqs.first : null);
        if (eq != null) {
          _dtdPhaseUncertainty = {};
          if (rTxDtdACtrl.text.isNotEmpty) {
            _dtdPhaseUncertainty['Pha A'] = CalibrationService.calculateUncertainty(
              equipment: eq,
              measuredValue: rA,
              unit: 'µΩ',
            );
          }
          if (rTxDtdBCtrl.text.isNotEmpty) {
            _dtdPhaseUncertainty['Pha B'] = CalibrationService.calculateUncertainty(
              equipment: eq,
              measuredValue: rB,
              unit: 'µΩ',
            );
          }
          if (rTxDtdCCtrl.text.isNotEmpty) {
            _dtdPhaseUncertainty['Pha C'] = CalibrationService.calculateUncertainty(
              equipment: eq,
              measuredValue: rC,
              unit: 'µΩ',
            );
          }
          _dtdUncertaintyResult = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: maxRtxDtd!,
            unit: 'µΩ',
          );
        }
      } else {
        _dtdPhaseUncertainty = {};
        _dtdUncertaintyResult = null;
      }
    }
    setState(() {});
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    if (minRcd != null) {
      cals.add(TestCalculation(
        name: 'Điện trở cách điện Dao Cách Ly (Rcđ)',
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
        name: 'Điện trở tiếp xúc Lưỡi dao chính DCL (Rtx)',
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
          name: 'Độ lệch tiếp xúc DCL ΔRtx (${_selectedRtxFormula?.method ?? 'Mặc định'})',
          inputs: {
            'R_max': maxRtx!,
            if (rTxNsxCtrl.text.isNotEmpty) 'R_nsx': parseInput(rTxNsxCtrl.text),
          },
          result: deltaRtx!,
          unit: '%',
        ));
      }
    }

    if (maxRtxDtd != null) {
      cals.add(TestCalculation(
        name: 'Điện trở tiếp xúc Dao tiếp địa DTD (Rtx)',
        inputs: {
          'Rtx_A': parseInput(rTxDtdACtrl.text),
          'Rtx_B': parseInput(rTxDtdBCtrl.text),
          'Rtx_C': parseInput(rTxDtdCCtrl.text),
          if (rTxDtdNsxCtrl.text.isNotEmpty) 'R_nsx': parseInput(rTxDtdNsxCtrl.text),
        },
        result: maxRtxDtd!,
        unit: 'μΩ',
      ));

      if (deltaRtxDtd != null) {
        cals.add(TestCalculation(
          name: 'Độ lệch tiếp xúc DTD ΔRtx (${_selectedDtdFormula?.method ?? 'Mặc định'})',
          inputs: {
            'R_max': maxRtxDtd!,
            if (rTxDtdNsxCtrl.text.isNotEmpty) 'R_nsx': parseInput(rTxDtdNsxCtrl.text),
          },
          result: deltaRtxDtd!,
          unit: '%',
        ));
      }
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
    if (maxRtxDtd != null) pendingCount++;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            EquipmentIconWidget(categoryCode: 'disconnector', size: 26),
            SizedBox(width: 10),
            Text('TÍNH TOÁN DAO CÁCH LY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
            // CẤP ĐIỆN ÁP
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    const Text('Cấp điện áp:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white70)),
                    const SizedBox(width: 16),
                    ChoiceChip(
                      label: const Text('> 35kV'),
                      selected: _dclVoltageLevel == '>35kV',
                      selectedColor: AppTheme.myOrangeAccent,
                      onSelected: (val) {
                        if (val) setState(() => _dclVoltageLevel = '>35kV');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('≤ 35kV'),
                      selected: _dclVoltageLevel == '<=35kV',
                      selectedColor: AppTheme.myOrangeAccent,
                      onSelected: (val) {
                        if (val) setState(() => _dclVoltageLevel = '<=35kV');
                      },
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
                    const Text(
                      'I. ĐIỆN TRỞ CÁCH ĐIỆN DAO CÁCH LY (MΩ)',
                      style: AppTheme.titleModuleStyle,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rCdACtrl, hint: 'VD: 2500'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rCdBCtrl, hint: 'VD: 2500'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rCdCCtrl, hint: 'VD: 2500'),
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
                          style: const TextStyle(
                            fontSize: AppTheme.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.statusGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      StandardEvaluationWidget(
                        testCode: 'DCL_R_cd',
                        voltageLevel: _dclVoltageLevel,
                        primaryValue: minRcd,
                        unit: 'MΩ',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN CÁCH ĐIỆN DAO CÁCH LY",
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
                    const Text(
                      'II. ĐIỆN TRỞ TIẾP XÚC LƯỠI DAO CHÍNH (μΩ)',
                      style: AppTheme.titleModuleStyle,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rTxACtrl, hint: 'VD: 45.2'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rTxBCtrl, hint: 'VD: 46.1'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rTxCCtrl, hint: 'VD: 45.8'),
                      ],
                    ),
                    FormulaSelectorWidget(
                      groupCode: 'DCL_R_tx',
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
                          hint: 'VD: 45.0',
                          isExpanded: false,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhTiepXuc,
                      child: const Text('TÍNH Rtx & ĐỘ LỆCH PHA (ΔR)'),
                    ),
                    if (maxRtx != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rtx Max: ${AppFormatters.formatRtx(maxRtx)} | ΔR: ${AppFormatters.formatPercent(deltaRtx)}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: (deltaRtx != null && deltaRtx! <= 50.0)
                                ? AppTheme.statusGreen
                                : AppTheme.cbmLevel4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      UncertaintyEquipmentSection(
                        testId: 'DCL_R_tx',
                        selectedEquipment: _selectedRtxEquipment,
                        onEquipmentChanged: (newEq) {
                          setState(() {
                            _selectedRtxEquipment = newEq;
                            if (maxRtx != null) _tinhTiepXuc();
                          });
                        },
                        phaseResults: _rtxPhaseUncertainty.isNotEmpty ? _rtxPhaseUncertainty : null,
                        uncertaintyResult: _rtxUncertaintyResult,
                        standardLimit: 10.0,
                        isUpperBound: true,
                      ),
                      Builder(
                        builder: (context) {
                          final phaseDevs = FormulaService.calculatePhaseDeviations(
                            phaseValues: {
                              if (rTxACtrl.text.isNotEmpty) 'Pha A': parseInput(rTxACtrl.text),
                              if (rTxBCtrl.text.isNotEmpty) 'Pha B': parseInput(rTxBCtrl.text),
                              if (rTxCCtrl.text.isNotEmpty) 'Pha C': parseInput(rTxCCtrl.text),
                            },
                            formulaId: _selectedRtxFormula?.id,
                            rNsx: parseInput(rTxNsxCtrl.text),
                          );

                          return StandardEvaluationWidget(
                            testCode: 'DCL_R_tx',
                            voltageLevel: _dclVoltageLevel,
                            primaryValue: deltaRtx ?? 0.0,
                            phaseValues: phaseDevs.isNotEmpty ? phaseDevs : null,
                            unit: '%',
                            symbol: 'ΔRtx',
                            customTitle: "ĐỐI CHIẾU TIÊU CHUẨN ĐỘ LỆCH TIẾP XÚC DCL",
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE 3: ĐIỆN TRỞ TIẾP XÚC DAO TIẾP ĐỊA (DTD)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'III. ĐIỆN TRỞ TIẾP XÚC DAO TIẾP ĐỊA (μΩ)',
                      style: AppTheme.titleModuleStyle,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rTxDtdACtrl, hint: 'VD: 55.0'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rTxDtdBCtrl, hint: 'VD: 56.2'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rTxDtdCCtrl, hint: 'VD: 54.8'),
                      ],
                    ),
                    FormulaSelectorWidget(
                      groupCode: 'DTD_R_tx',
                      selectedFormula: _selectedDtdFormula,
                      onFormulaChanged: (newF) {
                        setState(() {
                          _selectedDtdFormula = newF;
                          if (maxRtxDtd != null) _tinhTiepXucDtd();
                        });
                      },
                    ),
                    if (_selectedDtdFormula == null ||
                        _selectedDtdFormula!.inputs.contains('R_nsx'))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: _buildTextField(
                          'Rnsx dao tiếp địa (nhà sản xuất / xuất xưởng)',
                          rTxDtdNsxCtrl,
                          hint: 'VD: 50.0',
                          isExpanded: false,
                        ),
                      ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhTiepXucDtd,
                      child: const Text('TÍNH Rtx & ĐỘ LỆCH DAO TIẾP ĐỊA'),
                    ),
                    if (maxRtxDtd != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rtx DTD Max: ${AppFormatters.formatRtx(maxRtxDtd)} | ΔR: ${AppFormatters.formatPercent(deltaRtxDtd)}',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: (deltaRtxDtd != null && deltaRtxDtd! <= 50.0)
                                ? AppTheme.statusGreen
                                : AppTheme.cbmLevel4,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      UncertaintyEquipmentSection(
                        testId: 'DTD_R_tx',
                        selectedEquipment: _selectedDtdEquipment,
                        onEquipmentChanged: (newEq) {
                          setState(() {
                            _selectedDtdEquipment = newEq;
                            if (maxRtxDtd != null) _tinhTiepXucDtd();
                          });
                        },
                        phaseResults: _dtdPhaseUncertainty.isNotEmpty ? _dtdPhaseUncertainty : null,
                        uncertaintyResult: _dtdUncertaintyResult,
                        standardLimit: 50.0,
                        isUpperBound: true,
                      ),
                      Builder(
                        builder: (context) {
                          final dtdDevs = FormulaService.calculatePhaseDeviations(
                            phaseValues: {
                              if (rTxDtdACtrl.text.isNotEmpty) 'Pha A': parseInput(rTxDtdACtrl.text),
                              if (rTxDtdBCtrl.text.isNotEmpty) 'Pha B': parseInput(rTxDtdBCtrl.text),
                              if (rTxDtdCCtrl.text.isNotEmpty) 'Pha C': parseInput(rTxDtdCCtrl.text),
                            },
                            formulaId: _selectedDtdFormula?.id,
                            rNsx: parseInput(rTxDtdNsxCtrl.text),
                          );

                          return StandardEvaluationWidget(
                            testCode: 'DCL_R_tx',
                            voltageLevel: _dclVoltageLevel,
                            primaryValue: deltaRtxDtd ?? 0.0,
                            phaseValues: dtdDevs.isNotEmpty ? dtdDevs : null,
                            unit: '%',
                            symbol: 'ΔRtx',
                            customTitle: "ĐỐI CHIẾU TIÊU CHUẨN TIẾP XÚC DAO TIẾP ĐỊA",
                          );
                        },
                      ),
                    ],
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
