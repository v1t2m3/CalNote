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
  Map<String, double> _rtxPhaseDeviations = {};
  
  // 3. Thời gian không đồng thời
  final TextEditingController tACtrl = TextEditingController();
  final TextEditingController tBCtrl = TextEditingController();
  final TextEditingController tCCtrl = TextEditingController();
  String _actionType = 'Close'; // Close hoặc Open
  double? timeResult; // delta t đo
  double? effectiveDeltaT; // delta t hiệu chỉnh để so sánh tiêu chuẩn
  bool hasTimeWarning = false;
  CalibratedEquipmentModel? _selectedTimeEquipment;
  UncertaintyResult? _timeDeltaUncertaintyResult;
  Map<String, UncertaintyResult?> _timePhaseUncertainty = {};

  // 4. Phân tích khí SF6
  final TextEditingController sf6PurityCtrl = TextEditingController();
  final TextEditingController sf6HumCtrl = TextEditingController();
  final TextEditingController sf6So2Ctrl = TextEditingController();
  bool _isHumidityDewPoint = false; // false: ppmv, true: °C (điểm sương)
  double? sf6PurityResult; // % (sau hiệu chuẩn nếu bật ĐKĐBĐ)
  double? sf6HumPpmResult; // ppmv quy chuẩn tại 20°C
  double? sf6So2Result; // ppmv
  CalibratedEquipmentModel? _selectedSf6Equipment;
  UncertaintyResult? _sf6PurityUncertaintyResult;

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

    final timeEqs = CalibrationService.getEquipmentsForTest('MC_Time_Delta');
    if (timeEqs.isNotEmpty) {
      _selectedTimeEquipment = timeEqs.first;
    }

    final sf6Eqs = CalibrationService.getEquipmentsForTest('MC_SF6_Purity');
    if (sf6Eqs.isNotEmpty) {
      _selectedSf6Equipment = sf6Eqs.first;
    }
  }

  /// Quy đổi Điểm sương Dew Point (°C) sang Nồng độ ppmv ở 1 atm (101325 Pa) theo IEC 60376
  static double dewPointToPpmv(double tDew) {
    double pw;
    if (tDew >= 0) {
      pw = 611.2 * exp((17.62 * tDew) / (243.12 + tDew));
    } else {
      pw = 611.2 * exp((22.46 * tDew) / (272.62 + tDew));
    }
    return (pw / 101325.0) * 1e6;
  }

  /// Quy đổi ppmv sang Điểm sương Dew Point (°C) ở 1 atm
  static double ppmvToDewPoint(double ppmv) {
    if (ppmv <= 0) return -80.0;
    double pw = (ppmv / 1e6) * 101325.0;
    if (pw <= 0) return -80.0;
    if (pw >= 611.2) {
      double lnRatio = log(pw / 611.2);
      return (243.12 * lnRatio) / (17.62 - lnRatio);
    } else {
      double lnRatio = log(pw / 611.2);
      return (272.62 * lnRatio) / (22.46 - lnRatio);
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
       _rtxPhaseDeviations = {};
       _rtxUncertaintyResult = null;
       _rtxPhaseUncertainty = {};
    } else {
       List<double> vals = [];
       if (rTxACtrl.text.isNotEmpty) vals.add(rA);
       if (rTxBCtrl.text.isNotEmpty) vals.add(rB);
       if (rTxCCtrl.text.isNotEmpty) vals.add(rC);
       maxRtx = vals.reduce(max);
       final formula = _selectedRtxFormula ?? FormulaService.getFormulaById('MC_Rtx_Delta_Nsx');

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

       // Xác định giá trị từng pha cuối cùng (lấy giá trị sau hiệu chuẩn R_hc nếu BẬT ĐKĐBĐ)
       Map<String, double> effectivePhaseValues = {};
       if (CalibrationService.isUncertaintyEnabled && _rtxPhaseUncertainty.isNotEmpty) {
         if (rTxACtrl.text.isNotEmpty && _rtxPhaseUncertainty['Pha A'] != null) {
           effectivePhaseValues['Pha A'] = _rtxPhaseUncertainty['Pha A']!.correctedValue;
         }
         if (rTxBCtrl.text.isNotEmpty && _rtxPhaseUncertainty['Pha B'] != null) {
           effectivePhaseValues['Pha B'] = _rtxPhaseUncertainty['Pha B']!.correctedValue;
         }
         if (rTxCCtrl.text.isNotEmpty && _rtxPhaseUncertainty['Pha C'] != null) {
           effectivePhaseValues['Pha C'] = _rtxPhaseUncertainty['Pha C']!.correctedValue;
         }
       } else {
         if (rTxACtrl.text.isNotEmpty) effectivePhaseValues['Pha A'] = rA;
         if (rTxBCtrl.text.isNotEmpty) effectivePhaseValues['Pha B'] = rB;
         if (rTxCCtrl.text.isNotEmpty) effectivePhaseValues['Pha C'] = rC;
       }

       // Tính độ lệch tiếp xúc và độ lệch % từng pha từ giá trị cuối cùng để đối chiếu tiêu chuẩn
       if (effectivePhaseValues.isNotEmpty) {
         final effVals = effectivePhaseValues.values.toList();
         double effMax = effVals.reduce(max);
         double effMin = effVals.reduce(min);
         double effAvg = effVals.reduce((a, b) => a + b) / effVals.length;

         if (formula != null) {
           try {
             final vars = <String, num>{
               'R_max': effMax,
               'R_min': effMin,
               'R_avg': effAvg,
               'R_nsx': rNsx > 0 ? rNsx : (effMin > 0 ? effMin : 1.0),
             };
             deltaRtx = FormulaService.calculate(formula.formula, vars);
           } catch (_) {
             deltaRtx = null;
           }
         } else {
           deltaRtx = effAvg > 0 ? ((effMax - effMin) / effAvg) * 100.0 : 0.0;
         }

         _rtxPhaseDeviations = FormulaService.calculatePhaseDeviations(
           phaseValues: effectivePhaseValues,
           formulaId: formula?.id,
           rNsx: rNsx,
         );
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
      effectiveDeltaT = null;
      _timePhaseUncertainty = {};
      _timeDeltaUncertaintyResult = null;
      setState(() {});
      return;
    }

    List<double> rawVals = [];
    if (tACtrl.text.isNotEmpty) rawVals.add(tA);
    if (tBCtrl.text.isNotEmpty) rawVals.add(tB);
    if (tCCtrl.text.isNotEmpty) rawVals.add(tC);

    double tMax = rawVals.reduce(max);
    double tMin = rawVals.reduce(min);
    timeResult = tMax - tMin;

    if (CalibrationService.isUncertaintyEnabled) {
      final eqs = CalibrationService.getEquipmentsForTest('MC_Time_Delta');
      final eq = _selectedTimeEquipment ?? (eqs.isNotEmpty ? eqs.first : null);
      if (eq != null) {
        _timePhaseUncertainty = {};
        if (tACtrl.text.isNotEmpty) {
          _timePhaseUncertainty['Pha A'] = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: tA,
            unit: 'ms',
          );
        }
        if (tBCtrl.text.isNotEmpty) {
          _timePhaseUncertainty['Pha B'] = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: tB,
            unit: 'ms',
          );
        }
        if (tCCtrl.text.isNotEmpty) {
          _timePhaseUncertainty['Pha C'] = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: tC,
            unit: 'ms',
          );
        }

        // Tìm pha có thời gian hiệu chỉnh max và min
        List<double> correctedPhaseTimes = [];
        double? uTMax;
        double? uTMin;
        double maxTCorr = -1e9;
        double minTCorr = 1e9;

        for (var entry in _timePhaseUncertainty.entries) {
          if (entry.value != null) {
            double cVal = entry.value!.correctedValue;
            correctedPhaseTimes.add(cVal);
            if (cVal > maxTCorr) {
              maxTCorr = cVal;
              uTMax = entry.value!.expandedUncertainty;
            }
            if (cVal < minTCorr) {
              minTCorr = cVal;
              uTMin = entry.value!.expandedUncertainty;
            }
          }
        }

        if (correctedPhaseTimes.isNotEmpty) {
          double deltaThc = maxTCorr - minTCorr;
          double uDeltaT = sqrt(pow(uTMax ?? 0.0, 2) + pow(uTMin ?? 0.0, 2));

          _timeDeltaUncertaintyResult = UncertaintyResult(
            measuredValue: timeResult!,
            correction: deltaThc - timeResult!,
            correctedValue: deltaThc,
            uPercent: eq.scales.isNotEmpty && eq.scales.first.ranges.isNotEmpty
                ? eq.scales.first.ranges.first.uPercent
                : 0.01,
            expandedUncertainty: uDeltaT,
            k: eq.k,
            confidenceLevel: eq.confidenceLevel,
            minBound: deltaThc - uDeltaT,
            maxBound: deltaThc + uDeltaT,
            unit: 'ms',
            equipment: eq,
            range: eq.scales.isNotEmpty && eq.scales.first.ranges.isNotEmpty
                ? eq.scales.first.ranges.first
                : null,
          );
          effectiveDeltaT = deltaThc;
        } else {
          _timeDeltaUncertaintyResult = null;
          effectiveDeltaT = timeResult;
        }
      } else {
        _timePhaseUncertainty = {};
        _timeDeltaUncertaintyResult = null;
        effectiveDeltaT = timeResult;
      }
    } else {
      _timePhaseUncertainty = {};
      _timeDeltaUncertaintyResult = null;
      effectiveDeltaT = timeResult;
    }

    final limit = _actionType == 'Close' ? 4.0 : 2.0;
    hasTimeWarning = (effectiveDeltaT ?? 0.0) > limit;
    setState(() {});
  }

  void _tinhSF6() {
    double purityRaw = parseInput(sf6PurityCtrl.text);
    double humRaw = parseInput(sf6HumCtrl.text);
    double so2Raw = parseInput(sf6So2Ctrl.text);

    // 1. Độ tinh khiết SF6
    if (sf6PurityCtrl.text.isNotEmpty) {
      if (CalibrationService.isUncertaintyEnabled) {
        final eqs = CalibrationService.getEquipmentsForTest('MC_SF6_Purity');
        final eq = _selectedSf6Equipment ?? (eqs.isNotEmpty ? eqs.first : null);
        if (eq != null) {
          _sf6PurityUncertaintyResult = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: purityRaw,
            unit: '%',
          );
          sf6PurityResult = _sf6PurityUncertaintyResult!.correctedValue;
        } else {
          _sf6PurityUncertaintyResult = null;
          sf6PurityResult = purityRaw;
        }
      } else {
        _sf6PurityUncertaintyResult = null;
        sf6PurityResult = purityRaw;
      }
    } else {
      sf6PurityResult = null;
      _sf6PurityUncertaintyResult = null;
    }

    // 2. Độ ẩm SF6
    if (sf6HumCtrl.text.isNotEmpty) {
      if (_isHumidityDewPoint) {
        sf6HumPpmResult = dewPointToPpmv(humRaw);
      } else {
        sf6HumPpmResult = humRaw;
      }
    } else {
      sf6HumPpmResult = null;
    }

    // 3. Hàm lượng SO2
    if (sf6So2Ctrl.text.isNotEmpty) {
      sf6So2Result = so2Raw;
    } else {
      sf6So2Result = null;
    }

    setState(() {});
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

    if (effectiveDeltaT != null || timeResult != null) {
      double resVal = effectiveDeltaT ?? timeResult!;
      String uStr = '';
      if (_timePhaseUncertainty.isNotEmpty) {
        final eq = _selectedTimeEquipment;
        final parts = _timePhaseUncertainty.entries
            .where((e) => e.value != null)
            .map((e) =>
                '${e.key}: ${e.value!.correctedValue.toStringAsFixed(2)}±${e.value!.expandedUncertainty.toStringAsFixed(2)}')
            .join(', ');
        uStr = ' [ISO 17025: $parts ms (${eq?.type ?? ''} SN:${eq?.serial ?? ''})]';
      }
      cals.add(TestCalculation(
        name: (_actionType == 'Close' ? 'Độ không đồng thời (Đóng)' : 'Độ không đồng thời (Cắt)') + uStr,
        inputs: {
          't_A': parseInput(tACtrl.text),
          't_B': parseInput(tBCtrl.text),
          't_C': parseInput(tCCtrl.text)
        },
        result: resVal,
        unit: 'ms',
      ));
    }

    if (sf6PurityResult != null) {
      String uStr = '';
      if (_sf6PurityUncertaintyResult != null) {
        final res = _sf6PurityUncertaintyResult!;
        uStr = ' [ISO 17025: X_hc=${res.correctedValue.toStringAsFixed(3)} ± ${res.expandedUncertainty.toStringAsFixed(3)}% (${res.equipment.type} SN:${res.equipment.serial})]';
      }
      cals.add(TestCalculation(
        name: 'Độ tinh khiết khí SF6$uStr',
        inputs: {'Purity_do': parseInput(sf6PurityCtrl.text)},
        result: sf6PurityResult!,
        unit: '%',
      ));
    }

    if (sf6HumPpmResult != null) {
      String dewPointStr = '';
      if (_isHumidityDewPoint) {
        dewPointStr = ' (Tdew: ${parseInput(sf6HumCtrl.text)} °C)';
      }
      cals.add(TestCalculation(
        name: 'Độ ẩm khí SF6$dewPointStr',
        inputs: {
          if (_isHumidityDewPoint) 'T_dew': parseInput(sf6HumCtrl.text) else 'Hum_ppm': parseInput(sf6HumCtrl.text),
        },
        result: sf6HumPpmResult!,
        unit: 'ppmv',
      ));
    }

    if (sf6So2Result != null) {
      cals.add(TestCalculation(
        name: 'Hàm lượng SO2 trong khí SF6',
        inputs: {'SO2_do': parseInput(sf6So2Ctrl.text)},
        result: sf6So2Result!,
        unit: 'ppm',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Chưa có thông số nào được tính. Hãy bấm nút tính toán trước nghen!')),
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
    if (effectiveDeltaT != null || timeResult != null) pendingCount++;
    if (sf6PurityResult != null || sf6HumPpmResult != null || sf6So2Result != null) pendingCount++;

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
                      selected: _cbVoltageLevel == '>35kV',
                      selectedColor: AppTheme.myOrangeAccent,
                      onSelected: (val) {
                        if (val) setState(() => _cbVoltageLevel = '>35kV');
                      },
                    ),
                    const SizedBox(width: 8),
                    ChoiceChip(
                      label: const Text('≤ 35kV'),
                      selected: _cbVoltageLevel == '<=35kV',
                      selectedColor: AppTheme.myOrangeAccent,
                      onSelected: (val) {
                        if (val) setState(() => _cbVoltageLevel = '<=35kV');
                      },
                    ),
                  ],
                ),
              ),
            ),

            // MODULE 1: ĐIỆN TRỞ CÁCH ĐIỆN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('I. ĐIỆN TRỞ CÁCH ĐIỆN (MΩ)',
                        style: AppTheme.titleModuleStyle),
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
                          style: AppTheme.bodyBoldPass,
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
                    const Text('II. ĐIỆN TRỞ TIẾP XÚC (μΩ)',
                        style: AppTheme.titleModuleStyle),
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
                            fontSize: AppTheme.fontSizeBody,
                            fontWeight: FontWeight.bold,
                            color: (deltaRtx != null && deltaRtx! <= 50.0) ? AppTheme.statusGreen : AppTheme.cbmLevel4,
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
                      StandardEvaluationWidget(
                        testCode: 'MC_R_tx',
                        voltageLevel: _cbVoltageLevel,
                        primaryValue: deltaRtx ?? 0.0,
                        phaseValues: _rtxPhaseDeviations.isNotEmpty ? _rtxPhaseDeviations : null,
                        unit: '%',
                        symbol: 'ΔRtx',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN ĐỘ LỆCH TIẾP XÚC MÁY CẮT",
                      ),
                    ],
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
                    const Text('III. ĐỘ KHÔNG ĐỒNG THỜI(ms)',
                        style: AppTheme.titleModuleStyle),
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
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Độ không đồng thời Δt${CalibrationService.isUncertaintyEnabled ? " (sau hiệu chuẩn)" : ""}: ${(effectiveDeltaT ?? timeResult!).toStringAsFixed(2)} ms',
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeBody,
                            fontWeight: FontWeight.bold,
                            color: hasTimeWarning ? AppTheme.cbmLevel4 : AppTheme.statusGreen,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      if (hasTimeWarning)
                        Padding(
                          padding: const EdgeInsets.only(top: 4.0),
                          child: Text(
                              '* Cảnh báo: Δt vượt ngưỡng cho phép (${_actionType == 'Close' ? '4ms' : '2ms'})!',
                              style: const TextStyle(
                                  color: AppTheme.cbmLevel4,
                                  fontSize: AppTheme.fontSizeCaption,
                                  fontStyle: FontStyle.italic,
                                  fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center),
                        ),
                      UncertaintyEquipmentSection(
                        testId: 'MC_Time_Delta',
                        selectedEquipment: _selectedTimeEquipment,
                        onEquipmentChanged: (newEq) {
                          setState(() {
                            _selectedTimeEquipment = newEq;
                            if (timeResult != null) {
                              _tinhThoiGian();
                            }
                          });
                        },
                        phaseResults: _timePhaseUncertainty.isNotEmpty ? _timePhaseUncertainty : null,
                        uncertaintyResult: _timeDeltaUncertaintyResult,
                        standardLimit: _actionType == 'Close' ? 4.0 : 2.0,
                        isUpperBound: true,
                      ),
                      StandardEvaluationWidget(
                        testCode: _actionType == 'Close' ? 'MC_Time_Close' : 'MC_Time_Open',
                        voltageLevel: _cbVoltageLevel,
                        primaryValue: effectiveDeltaT ?? timeResult,
                        unit: 'ms',
                        customTitle: "ĐỐI CHIẾU TIÊU CHUẨN THỜI GIAN",
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE 4: PHÂN TÍCH KHÍ SF6
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('IV. PHÂN TÍCH KHÍ SF6',
                        style: AppTheme.titleModuleStyle),
                    const Divider(),
                    // 1. Độ tinh khiết (%)
                    _buildTextField('1. Độ tinh khiết SF6 (%)', sf6PurityCtrl,
                        hint: 'VD: 99.5', isExpanded: false),
                    const SizedBox(height: 8),

                    // 2. Độ ẩm SF6
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: _buildTextField(
                            _isHumidityDewPoint
                                ? '2. Độ ẩm (Điểm sương °C)'
                                : '2. Độ ẩm SF6 (ppmv)',
                            sf6HumCtrl,
                            hint: _isHumidityDewPoint ? 'VD: -42.5' : 'VD: 150',
                            isExpanded: false,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: ChoiceChip(
                            label: Text(
                              _isHumidityDewPoint ? 'Đơn vị: °C' : 'Đơn vị: ppmv',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            selected: _isHumidityDewPoint,
                            selectedColor: AppTheme.myOrangeAccent,
                            onSelected: (val) {
                              setState(() {
                                double cur = parseInput(sf6HumCtrl.text);
                                if (cur != 0 || sf6HumCtrl.text.isNotEmpty) {
                                  if (val) {
                                    double dew = ppmvToDewPoint(cur);
                                    sf6HumCtrl.text = dew.toStringAsFixed(1);
                                  } else {
                                    double ppm = dewPointToPpmv(cur);
                                    sf6HumCtrl.text = ppm.toStringAsFixed(1);
                                  }
                                }
                                _isHumidityDewPoint = val;
                                if (sf6HumPpmResult != null) _tinhSF6();
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    if (_isHumidityDewPoint && sf6HumCtrl.text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
                        child: Text(
                          '≈ Quy đổi tương đương: ${dewPointToPpmv(parseInput(sf6HumCtrl.text)).toStringAsFixed(1)} ppmv (tại 20°C, 1 atm)',
                          style: const TextStyle(color: Colors.amberAccent, fontSize: 13, fontStyle: FontStyle.italic),
                        ),
                      ),
                    const SizedBox(height: 8),

                    // 3. Hàm lượng SO2
                    _buildTextField('3. Hàm lượng SO2 (ppmv)', sf6So2Ctrl,
                        hint: 'VD: 5.0', isExpanded: false),
                    const SizedBox(height: 12),

                    ElevatedButton(
                      onPressed: _tinhSF6,
                      child: const Text('TÍNH KHÍ SF6'),
                    ),

                    if (sf6PurityResult != null || sf6HumPpmResult != null || sf6So2Result != null) ...[
                      // Khối ĐKĐBĐ cho thiết bị đo SF6
                      UncertaintyEquipmentSection(
                        testId: 'MC_SF6_Purity',
                        selectedEquipment: _selectedSf6Equipment,
                        onEquipmentChanged: (newEq) {
                          setState(() {
                            _selectedSf6Equipment = newEq;
                            if (sf6PurityResult != null) {
                              _tinhSF6();
                            }
                          });
                        },
                        uncertaintyResult: _sf6PurityUncertaintyResult,
                        standardLimit: 97.0,
                        isUpperBound: false,
                      ),

                      // Tiêu chuẩn Độ tinh khiết
                      if (sf6PurityResult != null)
                        StandardEvaluationWidget(
                          testCode: 'MC_SF6_Purity',
                          voltageLevel: _cbVoltageLevel,
                          primaryValue: sf6PurityResult,
                          unit: '%',
                          symbol: 'Purity',
                          customTitle: "ĐỐI CHIẾU TIÊU CHUẨN ĐỘ TINH KHIẾT SF6",
                        ),

                      // Tiêu chuẩn Độ ẩm
                      if (sf6HumPpmResult != null)
                        StandardEvaluationWidget(
                          testCode: 'MC_SF6_Hum',
                          voltageLevel: _cbVoltageLevel,
                          primaryValue: sf6HumPpmResult,
                          unit: 'ppm',
                          symbol: 'Humidity',
                          customTitle: "ĐỐI CHIẾU TIÊU CHUẨN ĐỘ ẨM SF6",
                        ),

                      // Tiêu chuẩn SO2
                      if (sf6So2Result != null)
                        StandardEvaluationWidget(
                          testCode: 'MC_SF6_SO2',
                          voltageLevel: _cbVoltageLevel,
                          primaryValue: sf6So2Result,
                          unit: 'ppm',
                          symbol: 'SO2',
                          customTitle: "ĐỐI CHIẾU TIÊU CHUẨN HÀM LƯỢNG SO2",
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
