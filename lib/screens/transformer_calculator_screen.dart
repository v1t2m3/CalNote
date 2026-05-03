import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mte_calculator_pro/models/test_record.dart';
import '../services/formula_service.dart';
import '../core/theme/app_theme.dart';
import 'note_detail_screen.dart';


class TransformerCalculatorScreen extends StatefulWidget {
  const TransformerCalculatorScreen({super.key});

  @override
  State<TransformerCalculatorScreen> createState() =>
      _TransformerCalculatorScreenState();
}

class _TransformerCalculatorScreenState
    extends State<TransformerCalculatorScreen> {
  // M1. CÁCH ĐIỆN
  final TextEditingController rcCHCtrl = TextEditingController();
  final TextEditingController rcCVCtrl = TextEditingController();
  final TextEditingController rcHVCtrl = TextEditingController();
  double? minRcd;

  // M2. ĐIỆN TRỞ MỘT CHIỀU
  final TextEditingController rDoACtrl = TextEditingController();
  final TextEditingController rDoBCtrl = TextEditingController();
  final TextEditingController rDoCCtrl = TextEditingController();
  final TextEditingController tDoCtrl = TextEditingController();
  final TextEditingController tTcCtrl = TextEditingController();
  String _material = 'Dong';
  double? rResultA, rResultB, rResultC, deltaR;

  // M3. TỶ SỐ BIẾN
  final TextEditingController kDmCtrl = TextEditingController();
  final TextEditingController kTtACtrl = TextEditingController();
  final TextEditingController kTtBCtrl = TextEditingController();
  final TextEditingController kTtCCtrl = TextEditingController();
  double? errA, errB, errC;

  // M4. KHÔNG TẢI
  final TextEditingController i0ACtrl = TextEditingController();
  final TextEditingController i0BCtrl = TextEditingController();
  final TextEditingController i0CCtrl = TextEditingController();
  final TextEditingController i0DmCtrl = TextEditingController();
  final TextEditingController p0ACtrl = TextEditingController();
  final TextEditingController p0BCtrl = TextEditingController();
  final TextEditingController p0CCtrl = TextEditingController();
  double? i0Percent, p0Total;

  // M5. NGẮN MẠCH
  final TextEditingController ukACtrl = TextEditingController();
  final TextEditingController ukBCtrl = TextEditingController();
  final TextEditingController ukCCtrl = TextEditingController();
  final TextEditingController ukDmCtrl = TextEditingController();
  final TextEditingController pkACtrl = TextEditingController();
  final TextEditingController pkBCtrl = TextEditingController();
  final TextEditingController pkCCtrl = TextEditingController();
  double? ukPercent, pkTotal;

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
  }

  void _tinhCachDien() {
    double rCH = parseInput(rcCHCtrl.text);
    double rCV = parseInput(rcCVCtrl.text);
    double rHV = parseInput(rcHVCtrl.text);

    if (rcCHCtrl.text.isEmpty && rcCVCtrl.text.isEmpty && rcHVCtrl.text.isEmpty) {
      minRcd = null;
    } else {
      List<double> vals = [];
      if (rcCHCtrl.text.isNotEmpty) vals.add(rCH);
      if (rcCVCtrl.text.isNotEmpty) vals.add(rCV);
      if (rcHVCtrl.text.isNotEmpty) vals.add(rHV);
      minRcd = vals.reduce(min);
    }
    setState(() {});
  }

  void _tinhDienTroDC() {
    double rA = parseInput(rDoACtrl.text);
    double rB = parseInput(rDoBCtrl.text);
    double rC = parseInput(rDoCCtrl.text);
    double tdo = parseInput(tDoCtrl.text);
    double ttc = parseInput(tTcCtrl.text);

    String testId = _material == 'Dong' ? 'MBA_R_dc' : 'MBA_R_dc_Al';
    final model = FormulaService.getFormulaById(testId);
    
    // Hardcode k để dự phòng lỡ file json lỗi
    double kMat = _material == 'Dong' ? 235.0 : 225.0;

    try {
      if (rDoACtrl.text.isNotEmpty) {
        rResultA = model != null ? FormulaService.calculate(model.formula, {'R_do': rA, 'T_do': tdo, 'T_tc': ttc}) : (rA * ((kMat + ttc)/(kMat + tdo)));
      } else { rResultA = null; }

      if (rDoBCtrl.text.isNotEmpty) {
        rResultB = model != null ? FormulaService.calculate(model.formula, {'R_do': rB, 'T_do': tdo, 'T_tc': ttc}) : (rB * ((kMat + ttc)/(kMat + tdo)));
      } else { rResultB = null; }

      if (rDoCCtrl.text.isNotEmpty) {
        rResultC = model != null ? FormulaService.calculate(model.formula, {'R_do': rC, 'T_do': tdo, 'T_tc': ttc}) : (rC * ((kMat + ttc)/(kMat + tdo)));
      } else { rResultC = null; }

      List<double> validRs = [];
      if (rResultA != null) validRs.add(rResultA!);
      if (rResultB != null) validRs.add(rResultB!);
      if (rResultC != null) validRs.add(rResultC!);

      if (validRs.length > 1) {
        double maxR = validRs.reduce(max);
        double minR = validRs.reduce(min);
        double avgR = validRs.reduce((a, b) => a + b) / validRs.length;

        final errModel = FormulaService.getFormulaById('MBA_Unbalance');
        if (errModel != null) {
          deltaR = FormulaService.calculate(errModel.formula, {'R_max': maxR, 'R_min': minR, 'R_avg': avgR});
        } else {
          deltaR = ((maxR - minR) / avgR) * 100;
        }
      } else {
        deltaR = null;
      }
      
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tính Đ.Trở: $e')));
    }
  }

  void _tinhTySoBien() {
    double kDm = parseInput(kDmCtrl.text);
    double kA = parseInput(kTtACtrl.text);
    double kB = parseInput(kTtBCtrl.text);
    double kC = parseInput(kTtCCtrl.text);

    if (kDm == 0 || (kTtACtrl.text.isEmpty && kTtBCtrl.text.isEmpty && kTtCCtrl.text.isEmpty)) return;

    final model = FormulaService.getFormulaById('MBA_K_error');

    try {
      if (kTtACtrl.text.isNotEmpty) {
        errA = model != null ? FormulaService.calculate(model.formula, {'K_tt': kA, 'K_dm': kDm}) : (((kA - kDm)/kDm)*100);
      } else { errA = null; }

      if (kTtBCtrl.text.isNotEmpty) {
        errB = model != null ? FormulaService.calculate(model.formula, {'K_tt': kB, 'K_dm': kDm}) : (((kB - kDm)/kDm)*100);
      } else { errB = null; }

      if (kTtCCtrl.text.isNotEmpty) {
        errC = model != null ? FormulaService.calculate(model.formula, {'K_tt': kC, 'K_dm': kDm}) : (((kC - kDm)/kDm)*100);
      } else { errC = null; }

      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Lỗi tính Tỷ số: $e')));
    }
  }

  void _tinhKhongTai() {
    double ia = parseInput(i0ACtrl.text);
    double ib = parseInput(i0BCtrl.text);
    double ic = parseInput(i0CCtrl.text);
    double idm = parseInput(i0DmCtrl.text);

    double pa = parseInput(p0ACtrl.text);
    double pb = parseInput(p0BCtrl.text);
    double pc = parseInput(p0CCtrl.text);

    List<double> iList = [];
    if (i0ACtrl.text.isNotEmpty) iList.add(ia);
    if (i0BCtrl.text.isNotEmpty) iList.add(ib);
    if (i0CCtrl.text.isNotEmpty) iList.add(ic);

    if (iList.isNotEmpty) {
      double avgI = iList.reduce((a,b)=>a+b) / iList.length;
      if (idm > 0) {
        final model = FormulaService.getFormulaById('MBA_NoLoad');
        if (model != null) {
          i0Percent = FormulaService.calculate(model.formula, {'I0_avg': avgI, 'I_dm': idm});
        } else {
          i0Percent = (avgI / idm) * 100;
        }
      } else { i0Percent = null; }
    } else { i0Percent = null; }

    if (p0ACtrl.text.isNotEmpty || p0BCtrl.text.isNotEmpty || p0CCtrl.text.isNotEmpty) {
       p0Total = pa + pb + pc; // p0 is additive
    } else { p0Total = null; }
    
    setState(() {});
  }

  void _tinhNganMach() {
    double ua = parseInput(ukACtrl.text);
    double ub = parseInput(ukBCtrl.text);
    double uc = parseInput(ukCCtrl.text);
    double udm = parseInput(ukDmCtrl.text);

    double pa = parseInput(pkACtrl.text);
    double pb = parseInput(pkBCtrl.text);
    double pc = parseInput(pkCCtrl.text);

    List<double> uList = [];
    if (ukACtrl.text.isNotEmpty) uList.add(ua);
    if (ukBCtrl.text.isNotEmpty) uList.add(ub);
    if (ukCCtrl.text.isNotEmpty) uList.add(uc);

    if (uList.isNotEmpty) {
      double avgU = uList.reduce((a,b)=>a+b) / uList.length;
      if (udm > 0) {
        final model = FormulaService.getFormulaById('MBA_ShortCircuit');
        if (model != null) {
          ukPercent = FormulaService.calculate(model.formula, {'Uk_avg': avgU, 'U_dm': udm});
        } else {
          ukPercent = (avgU / udm) * 100;
        }
      } else { ukPercent = null; }
    } else { ukPercent = null; }

    if (pkACtrl.text.isNotEmpty || pkBCtrl.text.isNotEmpty || pkCCtrl.text.isNotEmpty) {
       pkTotal = pa + pb + pc;
    } else { pkTotal = null; }
    
    setState(() {});
  }

  void _saveAllNotes() {
    List<TestCalculation> cals = [];

    if (minRcd != null) {
      cals.add(TestCalculation(
        name: 'Điện trở cách điện (Min)',
        inputs: {
          if (rcCHCtrl.text.isNotEmpty) 'C-H': parseInput(rcCHCtrl.text),
          if (rcCVCtrl.text.isNotEmpty) 'C-V': parseInput(rcCVCtrl.text),
          if (rcHVCtrl.text.isNotEmpty) 'H-V': parseInput(rcHVCtrl.text)
        },
        result: minRcd!,
        unit: 'MΩ',
      ));
    }

    if (rResultA != null || rResultB != null || rResultC != null) {
      double theResult = deltaR ?? max(rResultA ?? 0, max(rResultB ?? 0, rResultC ?? 0));
      String theUnit = deltaR != null 
          ? '% sai lệch (Max Rtc: ${theResult.toStringAsFixed(3)} mΩ)'
          : 'mΩ';
      if (deltaR != null) {
        double maxTemp = 0;
        if (rResultA != null) maxTemp = max(maxTemp, rResultA!);
        if (rResultB != null) maxTemp = max(maxTemp, rResultB!);
        if (rResultC != null) maxTemp = max(maxTemp, rResultC!);
        theUnit = '% sai lệch (Max Rtc: ${maxTemp.toStringAsFixed(3)} mΩ)';
      }

      cals.add(TestCalculation(
        name: _material == 'Dong'
            ? 'Quy đổi điện trở DC (Đồng)'
            : 'Quy đổi điện trở DC (Nhôm)',
        inputs: {
          if (rDoACtrl.text.isNotEmpty) 'Ra': parseInput(rDoACtrl.text),
          if (rDoBCtrl.text.isNotEmpty) 'Rb': parseInput(rDoBCtrl.text),
          if (rDoCCtrl.text.isNotEmpty) 'Rc': parseInput(rDoCCtrl.text),
          if (tDoCtrl.text.isNotEmpty) 'T_do': parseInput(tDoCtrl.text),
          if (tTcCtrl.text.isNotEmpty) 'T_tc': parseInput(tTcCtrl.text)
        },
        result: theResult,
        unit: theUnit,
      ));
    }

    if (errA != null || errB != null || errC != null) {
      double maxErr = 0;
      if (errA != null) maxErr = max(maxErr, errA!.abs());
      if (errB != null) maxErr = max(maxErr, errB!.abs());
      if (errC != null) maxErr = max(maxErr, errC!.abs());

      cals.add(TestCalculation(
        name: 'Sai số Tỷ số biến (Max)',
        inputs: {
          'K_dm': parseInput(kDmCtrl.text),
          if (kTtACtrl.text.isNotEmpty) 'Ka': parseInput(kTtACtrl.text),
          if (kTtBCtrl.text.isNotEmpty) 'Kb': parseInput(kTtBCtrl.text),
          if (kTtCCtrl.text.isNotEmpty) 'Kc': parseInput(kTtCCtrl.text)
        },
        result: maxErr,
        unit: '%',
      ));
    }

    if (i0Percent != null || p0Total != null) {
      cals.add(TestCalculation(
        name: 'Đo không tải MBA',
        inputs: {
          if (i0ACtrl.text.isNotEmpty) 'I_A': parseInput(i0ACtrl.text),
          if (i0BCtrl.text.isNotEmpty) 'I_B': parseInput(i0BCtrl.text),
          if (i0CCtrl.text.isNotEmpty) 'I_C': parseInput(i0CCtrl.text),
          if (p0ACtrl.text.isNotEmpty) 'P_A': parseInput(p0ACtrl.text),
          if (p0BCtrl.text.isNotEmpty) 'P_B': parseInput(p0BCtrl.text),
          if (p0CCtrl.text.isNotEmpty) 'P_C': parseInput(p0CCtrl.text),
        },
        result: i0Percent ?? p0Total ?? 0,
        unit: i0Percent != null ? '% (Po: $p0Total)' : 'W',
      ));
    }

    if (ukPercent != null || pkTotal != null) {
      cals.add(TestCalculation(
        name: 'Đo ngắn mạch MBA',
        inputs: {
          if (ukACtrl.text.isNotEmpty) 'U_A': parseInput(ukACtrl.text),
          if (ukBCtrl.text.isNotEmpty) 'U_B': parseInput(ukBCtrl.text),
          if (ukCCtrl.text.isNotEmpty) 'U_C': parseInput(ukCCtrl.text),
          if (pkACtrl.text.isNotEmpty) 'P_A': parseInput(pkACtrl.text),
          if (pkBCtrl.text.isNotEmpty) 'P_B': parseInput(pkBCtrl.text),
          if (pkCCtrl.text.isNotEmpty) 'P_C': parseInput(pkCCtrl.text),
        },
        result: ukPercent ?? pkTotal ?? 0,
        unit: ukPercent != null ? '% (Pk: $pkTotal)' : 'W',
      ));
    }

    if (cals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Bạn chưa cập nhật hay tính toán bất kì hạng mục nào. Hãy tính thử trước nhé!')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => NoteDetailScreen(
          calculations: cals,
          deviceName: 'Máy Biến Áp',
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, {bool isExpanded = true}) {
    final field = Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        decoration: InputDecoration(
          labelText: label,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
        ),
      ),
    );
    return isExpanded ? Expanded(child: field) : field;
  }

  @override
  Widget build(BuildContext context) {
    int pendingCount = 0;
    if (minRcd != null) pendingCount++;
    if (rResultA != null || rResultB != null || rResultC != null) pendingCount++;
    if (errA != null || errB != null || errC != null) pendingCount++;
    if (i0Percent != null || p0Total != null) pendingCount++;
    if (ukPercent != null || pkTotal != null) pendingCount++;

    return Scaffold(
      appBar: AppBar(
        title: const Text('TÍNH TOÁN MBA 3 PHA'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveAllNotes,
        backgroundColor: pendingCount > 0 ? AppTheme.myOrangeAccent : Colors.grey,
        icon: const Icon(Icons.bookmark_add),
        label: Text('Lưu Tổ Hợp ($pendingCount)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // MODULE 1: CÁCH ĐIỆN ---------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('1. ĐiỆN TRỞ CÁCH ĐIỆN (MΩ)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('C-H', rcCHCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('C-V', rcCVCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('H-V', rcHVCtrl),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: _tinhCachDien,
                      child: const Text('CẬP NHẬT Rcd'),
                    ),
                    if (minRcd != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'R_cd Min: ${minRcd!.toStringAsFixed(0)} MΩ',
                          style: const TextStyle(color: Colors.greenAccent, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // MODULE 2: Đ.TRỞ 1 CHIỀU ---------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('2. ĐIỆN TRỞ MỘT CHIỀU QUY ĐỔI (mΩ)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                      children: [
                        _buildTextField('Ra', rDoACtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Rb', rDoBCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Rc', rDoCCtrl),
                      ],
                    ),
                    Row(
                      children: [
                        _buildTextField('T_đo (°C)', tDoCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('T_tc (°C)', tTcCtrl),
                      ],
                    ),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Cuộn dây: ', style: TextStyle(fontSize: 14)),
                        Radio<String>(value: 'Dong', groupValue: _material, activeColor: AppTheme.myOrangeAccent, onChanged: (val) => setState(() => _material = val!)),
                        const Text('Đồng'),
                        Radio<String>(value: 'Nhom', groupValue: _material, activeColor: AppTheme.myOrangeAccent, onChanged: (val) => setState(() => _material = val!)),
                        const Text('Nhôm'),
                      ],
                    ),
                    ElevatedButton(onPressed: _tinhDienTroDC, child: const Text('TÍNH QUY ĐỔI & LỆCH PHA')),
                    if (rResultA != null || rResultB != null || rResultC != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Text('A: ${rResultA?.toStringAsFixed(2) ?? '-'}', style: const TextStyle(color: Colors.white70)),
                          Text('B: ${rResultB?.toStringAsFixed(2) ?? '-'}', style: const TextStyle(color: Colors.white70)),
                          Text('C: ${rResultC?.toStringAsFixed(2) ?? '-'}', style: const TextStyle(color: Colors.white70)),
                        ],
                      ),
                      if (deltaR != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.myMedNavy, borderRadius: BorderRadius.circular(8)),
                          child: Text(
                            'ΔR: ${deltaR!.toStringAsFixed(2)} %',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: deltaR! > 2.0 ? Colors.redAccent : Colors.lightGreenAccent),
                          ),
                        ),
                        if (deltaR! > 2.0)
                          const Padding(
                            padding: EdgeInsets.only(top: 4),
                            child: Text('CẢNH BÁO: Lệch pha > 2%!', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold), textAlign: TextAlign.center,),
                          ),
                      ]
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // MODULE 3: TỶ SỐ BIẾN ---------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('3. SAI LỆCH TỶ SỐ BIẾN (%)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myBrightBlue)),
                    const Divider(),
                    _buildTextField('K Định mức (K_dm)', kDmCtrl, isExpanded: false),
                    Row(
                      children: [
                        _buildTextField('Ka đo', kTtACtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Kb đo', kTtBCtrl),
                        const SizedBox(width: 8),
                        _buildTextField('Kc đo', kTtCCtrl),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _tinhTySoBien, child: const Text('TÍNH SAI SỐ %')),
                    if (errA != null || errB != null || errC != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (errA != null) Text('A: ${errA!.toStringAsFixed(2)}%', style: TextStyle(color: errA!.abs() > 0.5 ? Colors.redAccent : Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                          if (errB != null) Text('B: ${errB!.toStringAsFixed(2)}%', style: TextStyle(color: errB!.abs() > 0.5 ? Colors.redAccent : Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                          if (errC != null) Text('C: ${errC!.toStringAsFixed(2)}%', style: TextStyle(color: errC!.abs() > 0.5 ? Colors.redAccent : Colors.lightGreenAccent, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ]
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // MODULE 4: KHÔNG TẢI ---------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('4. KHÔNG TẢI',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                       children: [
                         _buildTextField('Ioa', i0ACtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Iob', i0BCtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Ioc', i0CCtrl),
                       ],
                    ),
                    _buildTextField('I định mức (Để tính I0%)', i0DmCtrl, isExpanded: false),
                    Row(
                       children: [
                         _buildTextField('Poa', p0ACtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Pob', p0BCtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Poc', p0CCtrl),
                       ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _tinhKhongTai, child: const Text('CẬP NHẬT GIAO TỬ')),
                    if (i0Percent != null || p0Total != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Io: ${i0Percent?.toStringAsFixed(2) ?? '-'} %  |  Po: ${p0Total?.toStringAsFixed(1) ?? '-'} (W / kW)',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // MODULE 5: NGẮN MẠCH ---------------------------------
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('5. NGẮN MẠCH',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.myBrightBlue)),
                    const Divider(),
                    Row(
                       children: [
                         _buildTextField('Uka', ukACtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Ukb', ukBCtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Ukc', ukCCtrl),
                       ],
                    ),
                    _buildTextField('U pha định mức (Tính Uk%)', ukDmCtrl, isExpanded: false),
                    Row(
                       children: [
                         _buildTextField('Pka', pkACtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Pkb', pkBCtrl),
                         const SizedBox(width: 8),
                         _buildTextField('Pkc', pkCCtrl),
                       ],
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(onPressed: _tinhNganMach, child: const Text('CẬP NHẬT GIAO TỬ')),
                    if (ukPercent != null || pkTotal != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Uk: ${ukPercent?.toStringAsFixed(2) ?? '-'} %  |  Pk: ${pkTotal?.toStringAsFixed(1) ?? '-'} (W / kW)',
                          style: const TextStyle(color: Colors.orangeAccent, fontSize: 16, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      )
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 80), // Cách dưới 
          ],
        ),
      ),
    );
  }
}
