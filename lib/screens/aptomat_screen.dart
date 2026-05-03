import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../models/breaker_curve.dart';
import '../services/breaker_curve_manager.dart';
import 'curve_digitizer_screen.dart';
import 'note_detail_screen.dart';
import '../models/test_record.dart';

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

  @override
  void initState() {
    super.initState();
    _loadCurves();
  }

  void _loadCurves() {
    setState(() {
      _curves = BreakerCurveManager.getAllCurves();
      if (_curves.isNotEmpty && _selectedCurve == null) {
        _selectedCurve = _curves.first;
      }
    });
  }

  double parseInput(String val) {
    if (val.isEmpty) return 0;
    return double.tryParse(val.replaceAll(',', '.')) ?? 0;
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
       evaluateResult = "NHẢY QUÁ SỚM";
       resultColor = Colors.orangeAccent;
    } else if (tCut > tMaxLth!) {
       evaluateResult = "NHẢY QUÁ CHẬM - NGUY HIỂM";
       resultColor = Colors.redAccent;
    } else {
       evaluateResult = "ĐẠT";
       resultColor = Colors.greenAccent;
    }
    setState(() {});
  }

  void _saveAllNotes() {
    if (evaluateResult == null || _selectedCurve == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng tính toán trước khi lưu sổ.')),
      );
      return;
    }

    List<TestCalculation> cals = [];
    
    // Thu thập các thông số đã tính toán
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('PHÂN TÍCH APTOMAT'),
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
        backgroundColor: evaluateResult != null ? AppTheme.myOrangeAccent : Colors.grey,
        icon: const Icon(Icons.bookmark_add),
        label: const Text('Lưu Sổ'),
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
                         const Text('CHỌN THƯ VIỆN ĐẶC TUYẾN', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                         IconButton(
                           onPressed: () {
                             Navigator.push(context, MaterialPageRoute(builder: (_) => const CurveDigitizerScreen())).then((value) => _loadCurves());
                           },
                           icon: const Icon(Icons.add_a_photo, color: AppTheme.myBrightBlue),
                           tooltip: 'Chụp ảnh phân tích mới',
                         )
                       ],
                     ),
                     const Divider(),
                     if (_curves.isEmpty)
                       const Padding(
                         padding: EdgeInsets.symmetric(vertical: 12.0),
                         child: Text('Chưa có dữ liệu nào. Vui lòng thêm bằng chụp hình hoặc import file JSON.', style: TextStyle(color: Colors.amberAccent)),
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
                    const Text('THÔNG SỐ ĐẦU VÀO', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const Divider(),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: idmCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Định mức (In)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: tEnvCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Nhiệt độ MTI (°C)', hintText: 'Mặc định 30'))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: TextField(controller: ibomCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Dòng test (I bơm)'))),
                        const SizedBox(width: 8),
                        Expanded(child: TextField(controller: tCutCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Thời gian cắt (s)'))),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                       onPressed: _tinhToanBaoVe,
                       style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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
                        Text('TỶ LỆ QUÁ DÒNG K: ${kCalc?.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('THỜI GIAN LÝ THUYẾT: ${tMinLth?.toStringAsFixed(3)}s ~ ${tMaxLth?.toStringAsFixed(3)}s', style: const TextStyle(fontSize: 16)),
                        const Divider(),
                        Text(
                          evaluateResult!,
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: resultColor),
                          textAlign: TextAlign.center,
                        )
                     ],
                   ),
                 ),
               ),
          ],
        ),
      ),
    );
  }
}
