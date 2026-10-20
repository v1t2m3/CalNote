import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../services/calibration_service.dart';
import '../widgets/uncertainty_widget.dart';
import '../widgets/standard_evaluation_widget.dart';
import '../widgets/formula_selector_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_formatters.dart';
import 'note_detail_screen.dart';
import '../widgets/equipment_icon_widget.dart';


class CircuitBreakerScreen extends StatefulWidget {
  const CircuitBreakerScreen({super.key});

  @override
  State<CircuitBreakerScreen> createState() => _CircuitBreakerScreenState();
}

class _CircuitBreakerScreenState extends State<CircuitBreakerScreen> {
  String _cbVoltageLevel = '>35kV';

  // 1. Điện trở cách điện
  final TextEditingController rCdACtrl = TextEditingController();
  final TextEditingController rCdBCtrl = TextEditingController();
  final TextEditingController rCdCCtrl = TextEditingController();
  double? minRcd;

  // 2. Điện trở tiếp xúc
  final TextEditingController rTxACtrl = TextEditingController();
  final TextEditingController rTxBCtrl = TextEditingController();
  final TextEditingController rTxCCtrl = TextEditingController();
  final TextEditingController rTxNsxCtrl = TextEditingController();
  final TextEditingController resolutionCtrl = TextEditingController();
  double? maxRtx;
  double? deltaRtx;
  FormulaModel? _selectedRtxFormula;
  CalibratedEquipmentModel? _selectedRtxEquipment;
  UncertaintyResult? _rtxUncertaintyResult;
  Map<String, UncertaintyResult?> _rtxPhaseUncertainty = {};
  
  // 3. Thời gian không đồng thời
  final TextEditingController tACtrl = TextEditingController();
  final TextEditingController tBCtrl = TextEditingController();
  final TextEditingController tCCtrl = TextEditingController();
  String _actionType = 'Close'; // Close hoặc Open
  double? timeResult; // delta t
  bool hasTimeWarning = false;

  @override
  void initState() {
    super.initState();
    final eqs = CalibrationService.getEquipmentsForTest('MC_R_tx');
    if (eqs.isNotEmpty) {
      _selectedRtxEquipment = eqs.first;
    }
    final rtxFormulas = FormulaService.getFormulasByGroup('MC_R_tx');
    if (rtxFormulas.isNotEmpty) {
      _selectedRtxFormula = rtxFormulas.first;
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
    double rNsx = parseInput(rTxNsxCtrl.text);

    if (rTxACtrl.text.isEmpty && rTxBCtrl.text.isEmpty && rTxCCtrl.text.isEmpty) {
       maxRtx = null;
       deltaRtx = null;
       _rtxUncertaintyResult = null;
       _rtxPhaseUncertainty = {};
    } else {
       List<double> vals = [];
       if (rTxACtrl.text.isNotEmpty) vals.add(rA);
       if (rTxBCtrl.text.isNotEmpty) vals.add(rB);
       if (rTxCCtrl.text.isNotEmpty) vals.add(rC);
       maxRtx = vals.reduce(max);
       double minR = vals.reduce(min);
       double avgR = vals.reduce((a, b) => a + b) / vals.length;

       final formula = _selectedRtxFormula ?? FormulaService.getFormulaById('MC_Rtx_Delta_Nsx');
       if (formula != null) {
         try {
           final vars = <String, num>{
             'R_max': maxRtx!,
             'R_min': minR,
             'R_avg': avgR,
             'R_nsx': rNsx > 0 ? rNsx : (minR > 0 ? minR : 1.0),
           };
           deltaRtx = FormulaService.calculate(formula.formula, vars);
         } catch (_) {
           deltaRtx = null;
         }
       }

       if (CalibrationService.isUncertaintyEnabled) {
         final eqs = CalibrationService.getEquipmentsForTest('MC_R_tx');
         final eq = _selectedRtxEquipment ?? (eqs.isNotEmpty ? eqs.first : null);
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
      String uBString = '';
      if (_rtxPhaseUncertainty.isNotEmpty) {
        final eq = _selectedRtxEquipment;
        final parts = _rtxPhaseUncertainty.entries
            .where((e) => e.value != null)
            .map((e) =>
                '${e.key}: ${e.value!.correctedValue.toStringAsFixed(1)}±${e.value!.expandedUncertainty.toStringAsFixed(1)}')
            .join(', ');
        uBString = ' [ISO 17025: $parts µΩ (${eq?.type ?? ''} SN:${eq?.serial ?? ''})]';
      } else if (_rtxUncertaintyResult != null) {
        final res = _rtxUncertaintyResult!;
        uBString = ' [ISO 17025: X_hc=${res.correctedValue.toStringAsFixed(2)} ± ${res.expandedUncertainty.toStringAsFixed(2)} ${res.unit} (${res.equipment.type} SN:${res.equipment.serial})]';
      } else {
        double resolution = parseInput(resolutionCtrl.text);
        if (resolution > 0) {
          double uB = resolution / (2 * sqrt(3));
          uBString = ' (uB: ${uB.toStringAsFixed(4)})';
        }
      }

      cals.add(TestCalculation(
        name: 'Điện trở tiếp xúc (Max)$uBString',
        inputs: {
          'R_txA': parseInput(rTxACtrl.text),
          'R_txB': parseInput(rTxBCtrl.text),
          'R_txC': parseInput(rTxCCtrl.text),
          if (rTxNsxCtrl.text.isNotEmpty) 'R_nsx': parseInput(rTxNsxCtrl.text),
        },
        result: _rtxUncertaintyResult?.correctedValue ?? maxRtx!,
        unit: 'μΩ', 
      ));

      if (deltaRtx != null) {
        cals.add(TestCalculation(
          name: 'Độ lệch tiếp xúc ΔRtx (${_selectedRtxFormula?.method ?? 'Mặc định'})',
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
        title: const Row(
          children: [
            EquipmentIconWidget(categoryCode: 'circuit_breaker', size: 26),
            SizedBox(width: 10),
            Text('TÍNH TOÁN MÁY CẮT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
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
            // BỘ CHỌN CẤP ĐIỆN ÁP MÁY CẮT
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: AppTheme.myMedNavy,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.myOrangeAccent.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.toggle_on, color: AppTheme.myOrangeAccent, size: 22),
                  const SizedBox(width: 8),
                  const Text(
                    "Cấp điện áp MC: ",
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  const Spacer(),
                  ChoiceChip(
                    label: const Text("> 35kV (Cao thế)"),
                    selected: _cbVoltageLevel == '>35kV',
                    selectedColor: AppTheme.myOrangeAccent,
                    backgroundColor: AppTheme.myDarkNavy,
                    labelStyle: TextStyle(
                      color: _cbVoltageLevel == '>35kV' ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _cbVoltageLevel = '>35kV');
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: const Text("≤ 35kV (Trung thế)"),
                    selected: _cbVoltageLevel == '<=35kV',
                    selectedColor: AppTheme.myOrangeAccent,
                    backgroundColor: AppTheme.myDarkNavy,
                    labelStyle: TextStyle(
                      color: _cbVoltageLevel == '<=35kV' ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    onSelected: (val) {
                      if (val) setState(() => _cbVoltageLevel = '<=35kV');
                    },
                  ),
                ],
              ),
            ),

            // MODULE 1: ĐIỆN TRỞ CÁCH ĐIỆN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('1. ĐIỆN TRỞ CÁCH ĐIỆN (MΩ)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myOrangeAccent)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rCdACtrl, hint: 'VD: 5000'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rCdBCtrl, hint: 'VD: 5000'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rCdCCtrl, hint: 'VD: 5000'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhCachDien,
                      child: const Text('TÍNH Rcd'),
                    ),
                    if (minRcd != null) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rcd thấp nhất: ${AppFormatters.formatInsulation(minRcd)}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.greenAccent),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      StandardEvaluationWidget(
                        testCode: 'MC_R_cd',
                        voltageLevel: _cbVoltageLevel,
                        primaryValue: minRcd,
                        unit: 'MΩ',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN CÁCH ĐIỆN MÁY CẮT",
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
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('2. ĐIỆN TRỞ TIẾP XÚC (μΩ)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myOrangeAccent)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A', rTxACtrl, hint: 'VD: 35.4'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B', rTxBCtrl, hint: 'VD: 35.4'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C', rTxCCtrl, hint: 'VD: 35.4'),
                      ],
                    ),
                    FormulaSelectorWidget(
                      groupCode: 'MC_R_tx',
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
                          hint: 'VD: 35.0',
                          isExpanded: false,
                        ),
                      ),
                    _buildTextField('Độ phân giải thiết bị đo', resolutionCtrl, hint: 'VD: 0.1', isExpanded: false),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhTiepXuc,
                      child: const Text('TÍNH Rtx & ĐỘ LỆCH (ΔR)'),
                    ),
                    if (maxRtx != null) ...[
                       Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Rtx Max: ${AppFormatters.formatRtx(maxRtx)}${deltaRtx != null ? ' | ΔR: ${AppFormatters.formatPercent(deltaRtx)}' : ''}',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: (deltaRtx != null && deltaRtx! <= 50.0) ? Colors.greenAccent : Colors.redAccent,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                       Builder(
                         builder: (context) {
                           double res = parseInput(resolutionCtrl.text);
                           if (res > 0 && !CalibrationService.isUncertaintyEnabled) {
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
                       ),
                    ],
                    UncertaintyEquipmentSection(
                      testId: 'MC_R_tx',
                      selectedEquipment: _selectedRtxEquipment,
                      onEquipmentChanged: (newEq) {
                        setState(() {
                          _selectedRtxEquipment = newEq;
                          if (maxRtx != null) {
                            _tinhTiepXuc();
                          }
                        });
                      },
                      phaseResults: _rtxPhaseUncertainty.isNotEmpty ? _rtxPhaseUncertainty : null,
                      uncertaintyResult: _rtxUncertaintyResult,
                      standardLimit: 100.0,
                      isUpperBound: true,
                    ),
                    if (maxRtx != null)
                      StandardEvaluationWidget(
                        testCode: 'MC_R_tx',
                        voltageLevel: _cbVoltageLevel,
                        primaryValue: deltaRtx ?? 0.0,
                        phaseValues: {
                          if (rTxACtrl.text.isNotEmpty) 'Pha A': parseInput(rTxACtrl.text),
                          if (rTxBCtrl.text.isNotEmpty) 'Pha B': parseInput(rTxBCtrl.text),
                          if (rTxCCtrl.text.isNotEmpty) 'Pha C': parseInput(rTxCCtrl.text),
                        },
                        unit: '%',
                        symbol: 'ΔRtx',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN ĐỘ LỆCH TIẾP XÚC MÁY CẮT",
                      ),
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
                    const Text('3. ĐỘ KHÔNG ĐỒNG THỜI THỜI GIAN (ms)',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.myOrangeAccent)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Pha A (ms)', tACtrl, hint: 'VD: 58.2'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha B (ms)', tBCtrl, hint: 'VD: 58.2'),
                        const SizedBox(width: 8),
                        _buildTextField('Pha C (ms)', tCCtrl, hint: 'VD: 58.2'),
                      ],
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Thao tác: ',
                            style: TextStyle(fontSize: 16, color: Colors.white70)),
                        Radio<String>(
                          value: 'Close',
                          groupValue: _actionType,
                          activeColor: AppTheme.myOrangeAccent,
                          onChanged: (val) => setState(() => _actionType = val!),
                        ),
                        const Text('Đóng', style: TextStyle(color: Colors.white)),
                        Radio<String>(
                          value: 'Open',
                          groupValue: _actionType,
                          activeColor: AppTheme.myOrangeAccent,
                          onChanged: (val) => setState(() => _actionType = val!),
                        ),
                        const Text('Cắt', style: TextStyle(color: Colors.white)),
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
                                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('${timeResult!.toStringAsFixed(1)} ms',
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
                      StandardEvaluationWidget(
                        testCode: _actionType == 'Close' ? 'MC_Time_Close' : 'MC_Time_Open',
                        voltageLevel: _cbVoltageLevel,
                        primaryValue: timeResult,
                        unit: 'ms',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN THỜI GIAN THAO TÁC",
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
