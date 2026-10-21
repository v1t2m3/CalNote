import 'dart:math';
import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/breaker_curve.dart';
import '../services/breaker_curve_manager.dart';
import '../core/utils/app_formatters.dart';
import 'curve_digitizer_screen.dart';
import 'note_detail_screen.dart';
import '../models/test_record.dart';
import '../widgets/equipment_icon_widget.dart';
import '../services/calibration_service.dart';
import '../widgets/uncertainty_widget.dart';
import '../widgets/standard_evaluation_widget.dart';

class AptomatScreen extends StatefulWidget {
  const AptomatScreen({super.key});

  @override
  State<AptomatScreen> createState() => _AptomatScreenState();
}

class _AptomatScreenState extends State<AptomatScreen> {
  List<BreakerCurve> _curves = [];
  BreakerCurve? _selectedCurve;

  final TextEditingController idmCtrl = TextEditingController();
  final TextEditingController tEnvCtrl = TextEditingController(text: '30');
  final TextEditingController ibomCtrl = TextEditingController();
  final TextEditingController tCutCtrl = TextEditingController(); // Thời gian cắt thực tế test

  String? evaluateResult;
  Color resultColor = Colors.grey;
  double? tMinLth;
  double? tMaxLth;
  double? kCalc;

  // MODULE TIẾP XÚC APTOMAT (APT_R_tx)
  final TextEditingController rTxACtrl = TextEditingController();
  final TextEditingController rTxBCtrl = TextEditingController();
  final TextEditingController rTxCCtrl = TextEditingController();
  double? rTxResultA, rTxResultB, rTxResultC;

  CalibratedEquipmentModel? _selectedAptEquipment;
  final Map<String, UncertaintyResult?> _aptRtxPhaseUncertainty = {};

  @override
  void initState() {
    super.initState();
    _loadCurves();
    final eqs = CalibrationService.getEquipmentsForTest('APT_R_tx');
    if (eqs.isNotEmpty) {
      _selectedAptEquipment = eqs.first;
    }
  }

  void _loadCurves() {
    setState(() {
      _curves = BreakerCurveManager.getAllCurves();
      if (_curves.isNotEmpty && _selectedCurve == null) {
        _selectedCurve = _curves.first;
      }
    });
  }

  double parseInput(String val) => AppFormatters.parseInput(val);

  void _tinhTiepXucAptomat() {
    double ra = parseInput(rTxACtrl.text);
    double rb = parseInput(rTxBCtrl.text);
    double rc = parseInput(rTxCCtrl.text);

    rTxResultA = rTxACtrl.text.isNotEmpty ? ra : null;
    rTxResultB = rTxBCtrl.text.isNotEmpty ? rb : null;
    rTxResultC = rTxCCtrl.text.isNotEmpty ? rc : null;

    _aptRtxPhaseUncertainty.clear();
    if (CalibrationService.isUncertaintyEnabled) {
      final eqs = CalibrationService.getEquipmentsForTest('APT_R_tx');
      final eq = _selectedAptEquipment ?? (eqs.isNotEmpty ? eqs.first : null);
      if (eq != null) {
        if (rTxACtrl.text.isNotEmpty && ra > 0) {
          _aptRtxPhaseUncertainty['Cực A'] = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: ra,
            unit: 'microΩ',
          );
        }
        if (rTxBCtrl.text.isNotEmpty && rb > 0) {
          _aptRtxPhaseUncertainty['Cực B'] = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: rb,
            unit: 'microΩ',
          );
        }
        if (rTxCCtrl.text.isNotEmpty && rc > 0) {
          _aptRtxPhaseUncertainty['Cực C'] = CalibrationService.calculateUncertainty(
            equipment: eq,
            measuredValue: rc,
            unit: 'microΩ',
          );
        }
      }
    }
    setState(() {});
  }


  void _tinhToanBaoVe() {
    if (_selectedCurve == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng chọn loại Aptomat!')));
      return;
    }
    double iDm = parseInput(idmCtrl.text);
    double iBom = parseInput(ibomCtrl.text);
    double tCut = parseInput(tCutCtrl.text);
    double tEnv = parseInput(tEnvCtrl.text);

    if (iDm <= 0 || iBom <= 0 || tCut <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng nhập Dòng định mức, Dòng bơm và Thời gian chạm cắt!')));
      return;
    }

    // 1. Hiệu chỉnh dòng điện định mức theo nhiệt độ (Thường tiêu chuẩn là 30 độ C)
    double iDmHieuChinh = BreakerCurveManager.applyTempCorrection(iDm, tEnv, 30.0);

    // 2. Tính hệ số k = I_bom / I_dm
    double k = iBom / iDmHieuChinh;
    kCalc = k;

    // 3. Truy xuất thời gian (Nội suy log-log)
    final limits = BreakerCurveManager.evaluateTripTimeLimits(_selectedCurve!, k);
    tMinLth = limits['tMin'];
    tMaxLth = limits['tMax'];

    // 4. Đánh giá vùng Nhanh / Chậm 
    if (tMinLth == 0 && tMaxLth == 0) {
       evaluateResult = "Không tìm thấy dữ liệu đặc tuyến tại K = ${k.toStringAsFixed(2)}";
       resultColor = Colors.grey;
       setState((){});
       return;
    }

    if (tCut < tMinLth!) {
       evaluateResult = "KHÔNG ĐẠT (Nhảy quá sớm)";
       resultColor = AppTheme.cbmLevel4;
    } else if (tCut > tMaxLth!) {
       evaluateResult = "KHÔNG ĐẠT (Nhảy quá chậm)";
       resultColor = AppTheme.cbmLevel4;
    } else {
       evaluateResult = "ĐẠT";
       resultColor = AppTheme.statusGreen;
    }
    setState(() {});
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];
    
    // Thu thập các thông số đã tính toán tác động
    if (evaluateResult != null && _selectedCurve != null) {
      cals.add(TestCalculation(
        name: 'Kiểm tra Aptomat (${_selectedCurve!.brand} - Type ${_selectedCurve!.type})',
        inputs: {
          'I_đm': parseInput(idmCtrl.text),
          'I_bơm': parseInput(ibomCtrl.text),
          'Nhiệt độ': parseInput(tEnvCtrl.text),
          'K_bội số': double.parse(kCalc!.toStringAsFixed(2)),
        },
        result: parseInput(tCutCtrl.text),
        unit: 's ($evaluateResult | Theo t_lythuyet: ${tMinLth?.toStringAsFixed(2)}s ~ ${tMaxLth?.toStringAsFixed(2)}s)',
      ));
    }

    // Thu thập thông số tiếp xúc cực
    if (rTxResultA != null || rTxResultB != null || rTxResultC != null) {
      final effA = (CalibrationService.isUncertaintyEnabled && _aptRtxPhaseUncertainty['Cực A'] != null)
          ? _aptRtxPhaseUncertainty['Cực A']!.correctedValue
          : rTxResultA;
      final effB = (CalibrationService.isUncertaintyEnabled && _aptRtxPhaseUncertainty['Cực B'] != null)
          ? _aptRtxPhaseUncertainty['Cực B']!.correctedValue
          : rTxResultB;
      final effC = (CalibrationService.isUncertaintyEnabled && _aptRtxPhaseUncertainty['Cực C'] != null)
          ? _aptRtxPhaseUncertainty['Cực C']!.correctedValue
          : rTxResultC;

      final validEffs = [effA, effB, effC].whereType<double>().toList();
      double maxR = validEffs.isNotEmpty ? validEffs.reduce(max) : 0.0;
      cals.add(TestCalculation(
        name: 'Điện trở tiếp xúc cực Aptomat (μΩ)',
        inputs: {
          if (rTxResultA != null) 'Ra': effA ?? 0.0,
          if (rTxResultB != null) 'Rb': effB ?? 0.0,
          if (rTxResultC != null) 'Rc': effC ?? 0.0,
        },
        result: maxR,
        unit: 'μΩ',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tính toán trước khi lưu sổ.')),
      );
      return;
    }

    // Chuyển sang màn hình Note Detail
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Aptomat (MCB/MCCB)',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = (evaluateResult != null ? 1 : 0) +
        (rTxResultA != null || rTxResultB != null || rTxResultC != null ? 1 : 0);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            EquipmentIconWidget(categoryCode: 'aptomat', size: 26),
            SizedBox(width: 10),
            Text('PHÂN TÍCH APTOMAT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_upload),
            tooltip: 'Import JSON',
            onPressed: () async {
               String res = await BreakerCurveManager.importJson();
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(res)));
               _loadCurves();
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAllNotes,
        backgroundColor: pendingCount > 0 ? AppTheme.accentOrange : Colors.grey,
        icon: const Icon(Icons.bookmark_add),
        label: Text('Lưu Sổ ($pendingCount)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // MODULE CHỌN ĐẶC TUYẾN
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                     Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         const Text(
                           'I. CHỌN THƯ VIỆN ĐẶC TUYẾN',
                           style: AppTheme.titleModuleStyle,
                         ),
                         IconButton(
                           onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const CurveDigitizerScreen())).then((value) => _loadCurves());
                           },
                           icon: const Icon(Icons.add_a_photo, color: AppTheme.accentOrange),
                           tooltip: 'Chụp ảnh phân tích mới',
                         )
                       ],
                     ),
                     const Divider(),
                     if (_curves.isEmpty)
                       const Padding(
                         padding: EdgeInsets.symmetric(vertical: 12.0),
                         child: Text(
                           'Chưa có dữ liệu nào. Vui lòng thêm bằng chụp hình hoặc import file JSON.',
                           style: AppTheme.captionItalic,
                         ),
                       )
                     else
                       DropdownButtonFormField<BreakerCurve>(
                         isExpanded: true,
                         value: _selectedCurve,
                         items: _curves.map((c) => DropdownMenuItem(
                           value: c,
                           child: Text('${c.brand} - ${c.series} (Type ${c.type})'),
                         )).toList(),
                         onChanged: (val) {
                           setState(() {
                             _selectedCurve = val;
                             evaluateResult = null; // Reset kết quả khi đổi loại khác
                           });
                         },
                       ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE THÔNG SỐ VÀ NHIỆT ĐỘ
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'II. THÔNG SỐ ĐẦU VÀO & THỜI GIAN CẮT',
                      style: AppTheme.titleModuleStyle,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: idmCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Định mức (In)', hintText: 'VD: 16'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: tEnvCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Nhiệt độ MTI (°C)', hintText: 'Mặc định 30'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: ibomCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Dòng test (I bơm)', hintText: 'VD: 40.8'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: tCutCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Thời gian cắt (s)', hintText: 'VD: 0.045'))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                       onPressed: _tinhToanBaoVe,
                       child: const Text('PHÂN TÍCH TÁC ĐỘNG')
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // MODULE KẾT QUẢ ĐÁNH GIÁ ĐẠT HAY KHÔNG
            if (evaluateResult != null)
               Card(
                 child: Container(
                   padding: const EdgeInsets.all(16),
                   decoration: BoxDecoration(
                     border: Border.all(color: resultColor, width: 2),
                     borderRadius: BorderRadius.circular(12),
                   ),
                   child: Column(
                     children: [
                        Text(
                          'TỶ LỆ QUÁ DÒNG K: ${kCalc?.toStringAsFixed(2)}',
                          style: AppTheme.bodyBoldWhite,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'THỜI GIAN LÝ THUYẾT: ${tMinLth?.toStringAsFixed(3)}s ~ ${tMaxLth?.toStringAsFixed(3)}s',
                          style: AppTheme.captionStyle,
                        ),
                        const Divider(),
                        Text(
                          evaluateResult!,
                          style: TextStyle(
                            fontSize: AppTheme.fontSizeTitle,
                            fontWeight: FontWeight.bold,
                            color: resultColor,
                          ),
                          textAlign: TextAlign.center,
                        )
                     ],
                   ),
                 ),
               ),
            const SizedBox(height: 12),

            // MODULE III: ĐIỆN TRỞ TIẾP XÚC CÁC CỰC APTOMAT (μΩ)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'III. ĐIỆN TRỞ TIẾP XÚC TIẾP ĐIỂM (μΩ)',
                      style: AppTheme.titleModuleStyle,
                    ),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: rTxACtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cực A (μΩ)', hintText: 'VD: 150'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: rTxBCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cực B (μΩ)', hintText: 'VD: 160'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: rTxCCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(labelText: 'Cực C (μΩ)', hintText: 'VD: 155'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhTiepXucAptomat,
                      child: const Text('TÍNH TIẾP XÚC APTOMAT'),
                    ),
                    if (rTxResultA != null || rTxResultB != null || rTxResultC != null)
                      Builder(
                        builder: (context) {
                          final effA = (CalibrationService.isUncertaintyEnabled &&
                                  _aptRtxPhaseUncertainty['Cực A'] != null)
                              ? _aptRtxPhaseUncertainty['Cực A']!.correctedValue
                              : rTxResultA;
                          final effB = (CalibrationService.isUncertaintyEnabled &&
                                  _aptRtxPhaseUncertainty['Cực B'] != null)
                              ? _aptRtxPhaseUncertainty['Cực B']!.correctedValue
                              : rTxResultB;
                          final effC = (CalibrationService.isUncertaintyEnabled &&
                                  _aptRtxPhaseUncertainty['Cực C'] != null)
                              ? _aptRtxPhaseUncertainty['Cực C']!.correctedValue
                              : rTxResultC;

                          final validEffs = [effA, effB, effC].whereType<double>().toList();
                          final maxEff = validEffs.isNotEmpty ? validEffs.reduce(max) : 0.0;

                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    if (effA != null)
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Cực A: ${effA.toStringAsFixed(1)} μΩ',
                                            style: const TextStyle(
                                              color: AppTheme.statusGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: AppTheme.fontSizeBody,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    if (effB != null)
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Cực B: ${effB.toStringAsFixed(1)} μΩ',
                                            style: const TextStyle(
                                              color: AppTheme.statusGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: AppTheme.fontSizeBody,
                                            ),
                                          ),
                                        ),
                                      ),
                                    const SizedBox(width: 6),
                                    if (effC != null)
                                      Flexible(
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown,
                                          child: Text(
                                            'Cực C: ${effC.toStringAsFixed(1)} μΩ',
                                            style: const TextStyle(
                                              color: AppTheme.statusGreen,
                                              fontWeight: FontWeight.bold,
                                              fontSize: AppTheme.fontSizeBody,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                StandardEvaluationWidget(
                                  testCode: 'APT_R_tx',
                                  voltageLevel: '<=35kV',
                                  primaryValue: maxEff,
                                  phaseValues: {
                                    if (effA != null) 'Cực A': effA,
                                    if (effB != null) 'Cực B': effB,
                                    if (effC != null) 'Cực C': effC,
                                  },
                                  unit: 'μΩ',
                                  customTitle: 'ĐỐI CHIẾU TIÊU CHUẨN TIẾP XÚC APTOMAT',
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    UncertaintyEquipmentSection(
                      testId: 'APT_R_tx',
                      selectedEquipment: _selectedAptEquipment,
                      onEquipmentChanged: (newEq) {
                        setState(() {
                          _selectedAptEquipment = newEq;
                          if (rTxResultA != null || rTxResultB != null || rTxResultC != null) {
                            _tinhTiepXucAptomat();
                          }
                        });
                      },
                      phaseResults: _aptRtxPhaseUncertainty.isNotEmpty ? _aptRtxPhaseUncertainty : null,
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
