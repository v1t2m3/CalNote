import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import 'note_detail_screen.dart';

class DigitalRelayScreen extends StatefulWidget {
  const DigitalRelayScreen({super.key});

  @override
  State<DigitalRelayScreen> createState() => _DigitalRelayScreenState();
}

class _DigitalRelayScreenState extends State<DigitalRelayScreen> {
  // MODULE 1: F50 / F51 QUÁ DÒNG
  final TextEditingController iFCtrl = TextEditingController();
  final TextEditingController iSetCtrl = TextEditingController();
  final TextEditingController tmsCtrl = TextEditingController(text: '0.1');
  final TextEditingController tMeasuredCtrl = TextEditingController();
  String _curveType = 'IEC Normal Inverse';

  double? tTheoryResult;
  double? tTimeErrorPercent;

  // MODULE 2: F67 QUÁ DÒNG CÓ HƯỚNG
  final TextEditingController mtaCtrl = TextEditingController(text: '45');
  final TextEditingController angleUCtrl = TextEditingController(text: '0');
  final TextEditingController angleICtrl = TextEditingController(text: '45');
  String? directionZoneEval;
  Color directionZoneColor = Colors.grey;

  // MODULE 3: F21 BẢO VỆ KHOẢNG CÁCH
  final TextEditingController z0Ctrl = TextEditingController();
  final TextEditingController z1Ctrl = TextEditingController();
  final TextEditingController zDoCtrl = TextEditingController();
  final TextEditingController zSetCtrl = TextEditingController();
  double? k0Result;
  double? zErrorPercent;

  // MODULE 4: F87T SO LỆCH MÁY BIẾN ÁP
  final TextEditingController iHCtrl = TextEditingController();
  final TextEditingController iLCtrl = TextEditingController();
  final TextEditingController i1hCtrl = TextEditingController();
  final TextEditingController i2hCtrl = TextEditingController();

  double? iDiffResult;
  double? iBiasResult;
  double? slopeResult;
  double? harmonic2Result;

  // MODULE 5: F87B & F87L SO LỆCH THANH CÁI & ĐƯỜNG DÂY
  final TextEditingController iACtrl = TextEditingController();
  final TextEditingController iBCtrl = TextEditingController();
  final TextEditingController iCCapCtrl = TextEditingController();
  double? lineDiffCompResult;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  // 1. TÍNH F50 / F51
  void _tinhF51() {
    double iF = parseInput(iFCtrl.text);
    double iSet = parseInput(iSetCtrl.text);
    double tms = parseInput(tmsCtrl.text);
    double tMeasured = parseInput(tMeasuredCtrl.text);

    if (iF == 0 || iSet == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dòng điện phải lớn hơn 0!')),
      );
      return;
    }

    if (iF <= iSet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Dòng sự cố phải lớn hơn dòng cài đặt (I_f > I_set)!')),
      );
      return;
    }

    try {
      if (_curveType == 'IEC Normal Inverse') {
        final model = FormulaService.getFormulaById('RL_IDMT_NormalInverse');
        tTheoryResult = model != null
            ? FormulaService.calculate(
                model.formula, {'I_f': iF, 'I_set': iSet, 'TMS': tms})
            : (0.14 / (pow((iF / iSet), 0.02) - 1)) * tms;
      } else if (_curveType == 'IEC Very Inverse') {
        final model = FormulaService.getFormulaById('RL_F51_IEC_VeryInverse');
        tTheoryResult = model != null
            ? FormulaService.calculate(
                model.formula, {'I': iF, 'I_s': iSet, 'TMS': tms})
            : (13.5 / ((iF / iSet) - 1)) * tms;
      } else if (_curveType == 'IEC Extremely Inverse') {
        final model =
            FormulaService.getFormulaById('RL_F51_IEC_ExtremelyInverse');
        tTheoryResult = model != null
            ? FormulaService.calculate(
                model.formula, {'I': iF, 'I_s': iSet, 'TMS': tms})
            : (80 / (pow((iF / iSet), 2) - 1)) * tms;
      } else if (_curveType == 'IEC Long Time Inverse') {
        final model = FormulaService.getFormulaById('RL_F51_IEC_LongTime');
        tTheoryResult = model != null
            ? FormulaService.calculate(
                model.formula, {'I': iF, 'I_s': iSet, 'TMS': tms})
            : (120 / ((iF / iSet) - 1)) * tms;
      }

      if (tMeasured > 0 && tTheoryResult != null && tTheoryResult! > 0) {
        tTimeErrorPercent =
            ((tMeasured - tTheoryResult!) / tTheoryResult!) * 100;
      } else {
        tTimeErrorPercent = null;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính F51: $e')),
      );
    }
  }

  // 2. TÍNH F67
  void _tinhF67() {
    double mta = parseInput(mtaCtrl.text);
    double uAngle = parseInput(angleUCtrl.text);
    double iAngle = parseInput(angleICtrl.text);

    double phi = iAngle - uAngle;
    while (phi > 180) {
      phi -= 360;
    }
    while (phi < -180) {
      phi += 360;
    }

    double minZone = mta - 90;
    double maxZone = mta + 90;

    bool isTrip = (phi >= minZone && phi <= maxZone);

    if (isTrip) {
      directionZoneEval = 'VÙNG TÁC ĐỘNG (FORWARD TRIP ZONE)';
      directionZoneColor = Colors.greenAccent;
    } else {
      directionZoneEval = 'VÙNG KHÓA / NHÌN NGƯỢC (REVERSE BLOCK ZONE)';
      directionZoneColor = Colors.redAccent;
    }

    setState(() {});
  }

  // 3. TÍNH F21
  void _tinhF21() {
    double z0 = parseInput(z0Ctrl.text);
    double z1 = parseInput(z1Ctrl.text);
    double zDo = parseInput(zDoCtrl.text);
    double zSet = parseInput(zSetCtrl.text);

    try {
      if (z1 > 0 && z0Ctrl.text.isNotEmpty) {
        final model = FormulaService.getFormulaById('RL_F21_K0_Factor');
        k0Result = model != null
            ? FormulaService.calculate(
                model.formula, {'Z_0': z0, 'Z_1': z1})
            : (z0 - z1) / (3 * z1);
      } else {
        k0Result = null;
      }

      if (zSet > 0 && zDoCtrl.text.isNotEmpty) {
        final modelZ = FormulaService.getFormulaById('RL_F21_Z_Error');
        zErrorPercent = modelZ != null
            ? FormulaService.calculate(
                modelZ.formula, {'Z_do': zDo, 'Z_set': zSet})
            : ((zDo - zSet) / zSet) * 100;
      } else {
        zErrorPercent = null;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính F21: $e')),
      );
    }
  }

  // 4. TÍNH F87T
  void _tinhF87T() {
    double iH = parseInput(iHCtrl.text);
    double iL = parseInput(iLCtrl.text);
    double i1h = parseInput(i1hCtrl.text);
    double i2h = parseInput(i2hCtrl.text);

    try {
      if (iHCtrl.text.isNotEmpty || iLCtrl.text.isNotEmpty) {
        final modelIdiff = FormulaService.getFormulaById('RL_F87T_Idiff');
        iDiffResult = modelIdiff != null
            ? FormulaService.calculate(
                modelIdiff.formula, {'I_H': iH, 'I_L': iL})
            : (iH - iL).abs();

        final modelIbias = FormulaService.getFormulaById('RL_F87T_Ibias');
        iBiasResult = modelIbias != null
            ? FormulaService.calculate(
                modelIbias.formula, {'I_H': iH, 'I_L': iL})
            : (iH + iL) / 2;

        if (iBiasResult != null && iBiasResult! > 0 && iDiffResult != null) {
          final modelSlope = FormulaService.getFormulaById('RL_F87T_Slope');
          slopeResult = modelSlope != null
              ? FormulaService.calculate(modelSlope.formula,
                  {'I_diff': iDiffResult!, 'I_bias': iBiasResult!})
              : (iDiffResult! / iBiasResult!) * 100;
        } else {
          slopeResult = null;
        }
      } else {
        iDiffResult = null;
        iBiasResult = null;
        slopeResult = null;
      }

      if (i1h > 0 && i2hCtrl.text.isNotEmpty) {
        final modelH2 = FormulaService.getFormulaById('RL_F87T_Harmonic2');
        harmonic2Result = modelH2 != null
            ? FormulaService.calculate(
                modelH2.formula, {'I_2h': i2h, 'I_1h': i1h})
            : (i2h / i1h) * 100;
      } else {
        harmonic2Result = null;
      }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính F87T: $e')),
      );
    }
  }

  // 5. TÍNH F87L
  void _tinhF87L() {
    double iA = parseInput(iACtrl.text);
    double iB = parseInput(iBCtrl.text);
    double iCap = parseInput(iCCapCtrl.text);

    try {
      lineDiffCompResult = (iA + iB - iCap).abs();
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi tính F87L: $e')),
      );
    }
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    if (tTheoryResult != null) {
      cals.add(TestCalculation(
        name: 'Thời gian F51 ($_curveType)',
        inputs: {
          'I_set': parseInput(iSetCtrl.text),
          'I_f': parseInput(iFCtrl.text),
          'TMS': parseInput(tmsCtrl.text),
        },
        result: tTheoryResult!,
        unit: 's',
      ));
    }

    if (directionZoneEval != null) {
      cals.add(TestCalculation(
        name: 'Hướng bảo vệ F67 (MTA=${mtaCtrl.text}°)',
        inputs: {
          '∠U': parseInput(angleUCtrl.text),
          '∠I': parseInput(angleICtrl.text),
        },
        result: parseInput(angleICtrl.text) - parseInput(angleUCtrl.text),
        unit: '° (${directionZoneEval?.split(' ')[0] ?? ''})',
      ));
    }

    if (k0Result != null) {
      cals.add(TestCalculation(
        name: 'Hệ số bù đất K0 (F21)',
        inputs: {
          'Z_0': parseInput(z0Ctrl.text),
          'Z_1': parseInput(z1Ctrl.text),
        },
        result: k0Result!,
        unit: '',
      ));
    }

    if (iDiffResult != null) {
      cals.add(TestCalculation(
        name: 'So lệch MBA F87T (Slope: ${slopeResult?.toStringAsFixed(1) ?? 0}%)',
        inputs: {
          'I_Cao': parseInput(iHCtrl.text),
          'I_Hạ': parseInput(iLCtrl.text),
        },
        result: iDiffResult!,
        unit: 'A',
      ));
    }

    if (lineDiffCompResult != null) {
      cals.add(TestCalculation(
        name: 'So lệch Đường dây F87L (Đã bù I_dung)',
        inputs: {
          'I_A': parseInput(iACtrl.text),
          'I_B': parseInput(iBCtrl.text),
          'I_dung': parseInput(iCCapCtrl.text),
        },
        result: lineDiffCompResult!,
        unit: 'A',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa có kết quả tính nào để lưu!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Rơ Le Số Chuyên Sâu',
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
              const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
        ),
      ),
    );
    return isExpanded ? Expanded(child: field) : field;
  }

  @override
  Widget build(BuildContext context) {
    int count = 0;
    if (tTheoryResult != null) count++;
    if (directionZoneEval != null) count++;
    if (k0Result != null) count++;
    if (iDiffResult != null) count++;
    if (lineDiffCompResult != null) count++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('RƠ LE SỐ CHUYÊN SÂU'),
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
            // MODULE 1: F50 / F51 QUÁ DÒNG
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '1. F50/F51: QUÁ DÒNG CẮT NHANH & CÓ THỜI GIAN',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    DropdownButtonFormField<String>(
                      initialValue: _curveType,
                      decoration:
                          const InputDecoration(labelText: 'Đặc tuyến IDMT'),
                      items: [
                        'IEC Normal Inverse',
                        'IEC Very Inverse',
                        'IEC Extremely Inverse',
                        'IEC Long Time Inverse'
                      ]
                          .map((e) => DropdownMenuItem(
                              value: e, child: Text(e)))
                          .toList(),
                      onChanged: (val) =>
                          setState(() => _curveType = val!),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildTextField('I_set (A)', iSetCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('I_sự cố (A)', iFCtrl),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTextField('Bội số TMS', tmsCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('t_đo thực tế (s)', tMeasuredCtrl),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhF51,
                      child: const Text('TÍNH THỜI GIAN CẮT TÍNH TOÁN'),
                    ),
                    if (tTheoryResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          't_lý thuyết = ${tTheoryResult!.toStringAsFixed(3)} s',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (tTimeErrorPercent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Sai số thời gian Δt = ${tTimeErrorPercent! >= 0 ? "+" : ""}${tTimeErrorPercent!.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: tTimeErrorPercent!.abs() <= 5.0
                                  ? Colors.lightGreenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 2: F67 CÓ HƯỚNG
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '2. F67: QUÁ DÒNG CÓ HƯỚNG & GÓC NHẠY MTA',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    _buildTextField('Góc nhạy cực đại MTA (°)', mtaCtrl,
                        isExpanded: false),
                    Row(
                      children: [
                        _buildTextField('Góc Điện áp ∠U (°)', angleUCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Góc Dòng điện ∠I (°)', angleICtrl),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhF67,
                      child: const Text('KIỂM TRA HƯỚNG BẢO VỆ'),
                    ),
                    if (directionZoneEval != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: directionZoneColor.withAlpha(50),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: directionZoneColor),
                        ),
                        child: Text(
                          directionZoneEval!,
                          style: TextStyle(
                              color: directionZoneColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ]
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 3: F21 KHOẢNG CÁCH
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '3. F21: BẢO VỆ KHOẢNG CÁCH & HỆ SỐ BÙ ĐẤT (K0)',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Z_1 (Ω)', z1Ctrl, hint: 'Thứ tự thuận'),
                        const SizedBox(width: 8),
                        _buildTextField('Z_0 (Ω)', z0Ctrl, hint: 'Thứ tự không'),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTextField('Z_đo (Ω)', zDoCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Z_cài đặt (Ω)', zSetCtrl),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhF21,
                      child: const Text('TÍNH K0 & SAI SỐ TỔNG TRỞ F21'),
                    ),
                    if (k0Result != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Hệ số bù đất K0 = ${k0Result!.toStringAsFixed(3)}',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (zErrorPercent != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Sai số tổng trở ΔZ = ${zErrorPercent! >= 0 ? "+" : ""}${zErrorPercent!.toStringAsFixed(2)}%',
                          style: TextStyle(
                              color: zErrorPercent!.abs() <= 5.0
                                  ? Colors.lightGreenAccent
                                  : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 4: F87T SO LỆCH MBA
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '4. F87T: BẢO VỆ SO LỆCH MÁY BIẾN ÁP 110kV',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('I_Cao quy đổi (A)', iHCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('I_Hạ quy đổi (A)', iLCtrl),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTextField('Sóng hài 1 (100%)', i1hCtrl, hint: 'I_50Hz'),
                        const SizedBox(width: 8),
                        _buildTextField('Sóng hài 2 (A)', i2hCtrl, hint: 'I_100Hz'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhF87T,
                      child: const Text('TÍNH SO LỆCH, DÒNG HÃM & SÓNG HÀI BẬC 2'),
                    ),
                    if (iDiffResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Dòng so lệch I_diff = ${iDiffResult!.toStringAsFixed(3)} A',
                          style: const TextStyle(
                              color: Colors.cyanAccent,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (iBiasResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Dòng hãm I_bias = ${iBiasResult!.toStringAsFixed(3)} A (Slope: ${slopeResult?.toStringAsFixed(1) ?? 0}%)',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    if (harmonic2Result != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          'Hàm lượng Sóng hài 2: ${harmonic2Result!.toStringAsFixed(1)}% ${harmonic2Result! >= 15.0 ? "(✓ Khóa đóng điện)" : "(Không khóa)"}',
                          style: TextStyle(
                              color: harmonic2Result! >= 15.0
                                  ? Colors.orangeAccent
                                  : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                          textAlign: TextAlign.center,
                        ),
                      ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 8),

            // MODULE 5: F87B & F87L
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      '5. F87B / F87L: SO LỆCH THANH CÁI & ĐƯỜNG DÂY',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.myOrangeAccent),
                    ),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Dòng đầu A / Nút 1 (A)', iACtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Dòng đầu B / Nút 2 (A)', iBCtrl),
                      ],
                    ),
                    _buildTextField('Dòng dung nạp bù I_dung (A)', iCCapCtrl,
                        hint: 'Chỉ áp dụng F87L', isExpanded: false),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _tinhF87L,
                      child: const Text('TÍNH SO LỆCH ĐƯỜNG DÂY (BÙ DÒNG DUNG)'),
                    ),
                    if (lineDiffCompResult != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Dòng so lệch F87L (Đã bù): ${lineDiffCompResult!.toStringAsFixed(3)} A',
                          style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 17,
                              fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
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
