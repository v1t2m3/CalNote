import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../services/calibration_service.dart';
import '../widgets/uncertainty_widget.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_formatters.dart';
import 'note_detail_screen.dart';
import '../widgets/equipment_icon_widget.dart';


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

  CalibratedEquipmentModel? _selectedTituEquipment;
  UncertaintyResult? _tituUncertaintyResult;

  @override
  void initState() {
    super.initState();
    final eqs = CalibrationService.getEquipmentsForTest('TITU_Ratio_Error');
    if (eqs.isNotEmpty) {
      _selectedTituEquipment = eqs.first;
    }
  }

  double parseInput(String val) => AppFormatters.parseInput(val);


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

      if (CalibrationService.isUncertaintyEnabled) {
        final eqs = CalibrationService.getEquipmentsForTest('TITU_Ratio_Error');
        final eq = _selectedTituEquipment ?? (eqs.isNotEmpty ? eqs.first : null);
        if (eq != null) {
          // Tính hiệu chuẩn trực tiếp trên tỷ số biến K_tt
          final rawRes = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: ktt,
            unit: '',
          );
          double fHc = ((rawRes.correctedValue - kdm) / kdm) * 100.0;
          double fMin = min(
            ((rawRes.minBound - kdm) / kdm) * 100.0,
            ((rawRes.maxBound - kdm) / kdm) * 100.0,
          );
          double fMax = max(
            ((rawRes.minBound - kdm) / kdm) * 100.0,
            ((rawRes.maxBound - kdm) / kdm) * 100.0,
          );
          double stdLimit = double.tryParse(_accuracyClass) ?? 0.5;
          _tituUncertaintyResult = rawRes.withDerived(
            derivedName: 'Sai số f_hc (Class $_accuracyClass)',
            derivedCorrected: fHc,
            derivedMinBound: fMin,
            derivedMaxBound: fMax,
            derivedUnit: '%',
            standardLimit: stdLimit,
            isUpperBound: true,
          );
        }
      } else {
        _tituUncertaintyResult = null;
      }
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tính: $e')));
    }
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    if (errorResult != null) {
      String uBString = '';
      if (_tituUncertaintyResult != null) {
        final res = _tituUncertaintyResult!;
        String derStr = res.derivedCorrected != null
            ? ' (f_hc: ${res.derivedCorrected! >= 0 ? "+" : ""}${res.derivedCorrected!.toStringAsFixed(2)}%)'
            : '';
        uBString = ' [ISO 17025: Ktt_hc=${res.correctedValue.toStringAsFixed(4)}$derStr (${res.equipment.type} SN:${res.equipment.serial})]';
      } else {
        double resolution = parseInput(resolutionCtrl.text);
        if (resolution > 0) {
          double uB = resolution / (2 * sqrt(3));
          uBString = ' (uB: ${uB.toStringAsFixed(4)})';
        }
      }

      cals.add(TestCalculation(
        name: 'Sai số tỷ số TI/TU (Class $_accuracyClass)$uBString',
        inputs: {
          'K_dm': parseInput(kDmCtrl.text),
          'K_tt': parseInput(kTtCtrl.text)
        },
        result: errorResult!,
        unit: '%',
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
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
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
        title: const Row(
          children: [
            EquipmentIconWidget(categoryCode: 'instrument_transformer', size: 26),
            SizedBox(width: 10),
            Text('TÍNH TOÁN TI / TU', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'I. SAI SỐ TỶ SỐ BIẾN DÒNG / ÁP (TI / TU)',
                      style: AppTheme.titleModuleStyle,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('K Định Mức', kDmCtrl, hint: 'VD: 100.0000')),
                        const SizedBox(width: 8),
                        Expanded(child: _buildTextField('K Thực Tế', kTtCtrl, hint: 'VD: 100.0452')),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildTextField('Độ phân giải (tuỳ chọn)', resolutionCtrl, hint: 'VD: 0.0001'),
                    const SizedBox(height: 8),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Cấp chính xác: ',
                            style: TextStyle(fontSize: AppTheme.fontSizeBody, color: Colors.white70)),
                        Radio<String>(
                          value: '0.2',
                          groupValue: _accuracyClass,
                          activeColor: AppTheme.accentOrange,
                          onChanged: (val) => setState(() => _accuracyClass = val!),
                        ),
                        const Text('Class 0.2', style: TextStyle(color: Colors.white)),
                        Radio<String>(
                          value: '0.5',
                          groupValue: _accuracyClass,
                          activeColor: AppTheme.accentOrange,
                          onChanged: (val) => setState(() => _accuracyClass = val!),
                        ),
                        const Text('Class 0.5', style: TextStyle(color: Colors.white)),
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
                              style: const TextStyle(color: AppTheme.accentOrange, fontSize: AppTheme.fontSizeCaption),
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
                                    fontSize: AppTheme.fontSizeTitle, fontWeight: FontWeight.bold, color: Colors.white)),
                            Expanded(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text('${errorResult! >= 0 ? "+" : ""}${errorResult!.toStringAsFixed(4)} %',
                                    style: TextStyle(
                                      fontSize: AppTheme.fontSizeTitle,
                                      fontWeight: FontWeight.bold,
                                      color: isFailed ? AppTheme.cbmLevel4 : AppTheme.statusGreen,
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
                            'KẾT LUẬN: KHÔNG ĐẠT CẤP CHÍNH XÁC',
                            style: TextStyle(
                              color: AppTheme.cbmLevel4,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontSizeBody,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.only(top: 8.0),
                          child: Text(
                            'KẾT LUẬN: ĐẠT CẤP CHÍNH XÁC',
                            style: TextStyle(
                              color: AppTheme.statusGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: AppTheme.fontSizeBody,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                    ],
                    UncertaintyEquipmentSection(
                      testId: 'TITU_Ratio_Error',
                      selectedEquipment: _selectedTituEquipment,
                      onEquipmentChanged: (newEq) {
                        setState(() {
                          _selectedTituEquipment = newEq;
                          if (errorResult != null) {
                            _tinhSaiSo();
                          }
                        });
                      },
                      uncertaintyResult: _tituUncertaintyResult,
                      standardLimit: double.tryParse(_accuracyClass),
                      isUpperBound: true,
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
