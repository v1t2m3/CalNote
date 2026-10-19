import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/calibration_service.dart';
import '../widgets/uncertainty_widget.dart';
import '../widgets/standard_evaluation_widget.dart';
import '../widgets/equipment_icon_widget.dart';
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
  double? maxRtx;
  double? deltaRtx; // Độ lệch giữa các pha (%)
  CalibratedEquipmentModel? _selectedRtxEquipment;
  UncertaintyResult? _rtxUncertaintyResult;
  Map<String, UncertaintyResult?> _rtxPhaseUncertainty = {};

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
      if (vals.length > 1) {
        double mn = vals.reduce(min);
        double avg = vals.reduce((a, b) => a + b) / vals.length;
        deltaRtx = avg > 0 ? ((maxRtx! - mn) / avg) * 100.0 : 0.0;
      } else {
        deltaRtx = 0.0;
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
        name: 'Điện trở tiếp xúc Dao Cách Ly (Rtx)',
        inputs: {
          'Rtx_A': parseInput(rTxACtrl.text),
          'Rtx_B': parseInput(rTxBCtrl.text),
          'Rtx_C': parseInput(rTxCCtrl.text),
          'Delta_Rtx': deltaRtx ?? 0.0,
        },
        result: maxRtx!,
        unit: 'μΩ',
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
                      '1. ĐIỆN TRỞ CÁCH ĐIỆN (MΩ)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myOrangeAccent),
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
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
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
                      '2. ĐIỆN TRỞ TIẾP XÚC LƯỠI DAO (μΩ)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myOrangeAccent),
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
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: (deltaRtx != null && deltaRtx! <= 10.0) ? Colors.greenAccent : Colors.redAccent,
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
                          double rA = parseInput(rTxACtrl.text);
                          double rB = parseInput(rTxBCtrl.text);
                          double rC = parseInput(rTxCCtrl.text);
                          List<double> valid = [
                            if (rTxACtrl.text.isNotEmpty) rA,
                            if (rTxBCtrl.text.isNotEmpty) rB,
                            if (rTxCCtrl.text.isNotEmpty) rC,
                          ];
                          Map<String, double> phaseDevs = {};
                          if (valid.length > 1) {
                            double avg = valid.reduce((a, b) => a + b) / valid.length;
                            if (avg > 0) {
                              if (rTxACtrl.text.isNotEmpty) phaseDevs['Pha A'] = ((rA - avg).abs() / avg) * 100.0;
                              if (rTxBCtrl.text.isNotEmpty) phaseDevs['Pha B'] = ((rB - avg).abs() / avg) * 100.0;
                              if (rTxCCtrl.text.isNotEmpty) phaseDevs['Pha C'] = ((rC - avg).abs() / avg) * 100.0;
                            }
                          }
                          return StandardEvaluationWidget(
                            testCode: 'DCL_R_tx',
                            voltageLevel: _dclVoltageLevel,
                            primaryValue: deltaRtx ?? 0.0,
                            phaseValues: phaseDevs.isNotEmpty ? phaseDevs : null,
                            unit: '%',
                            customTitle: "ĐỐI CHIẾU TIÊU CHUẨN ĐỘ LỆCH TIẾP XÚC DCL",
                          );
                        },
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
