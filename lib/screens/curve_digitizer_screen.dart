import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../core/theme/app_theme.dart';
import '../models/breaker_curve.dart';
import '../services/breaker_curve_manager.dart';
import 'note_detail_screen.dart';


class CurveDigitizerScreen extends StatefulWidget {
  const CurveDigitizerScreen({super.key});

  @override
  State<CurveDigitizerScreen> createState() => _CurveDigitizerScreenState();
}

class _CurveDigitizerScreenState extends State<CurveDigitizerScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // Calibration Info
  final TextEditingController kMinCtrl = TextEditingController(text: '1');
  final TextEditingController kMaxCtrl = TextEditingController(text: '100');
  final TextEditingController tMinCtrl = TextEditingController(text: '0.01');
  final TextEditingController tMaxCtrl = TextEditingController(text: '10000');
  
  // Trạng thái: 0 = Calibration BL, 1 = Calibration TR, 2 = Chấm Min, 3 = Chấm Max
  int _mode = 0; 
  
  Offset? _blPoint; // Bottom-Left (Pixel)
  Offset? _trPoint; // Top-Right (Pixel)

  List<Offset> _minTracePx = [];
  List<Offset> _maxTracePx = [];

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery, // Hoặc camera
      imageQuality: 50, // NÉN DUNG LƯỢNG ẢNH xuống 50%
    );
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
        _blPoint = null;
        _trPoint = null;
        _minTracePx.clear();
        _maxTracePx.clear();
        _mode = 0; // Reset mode
      });
    }
  }

  void _handleTap(TapUpDetails details) {
    if (_imageFile == null) return;
    final pos = details.localPosition;
    setState(() {
      if (_mode == 0) {
        _blPoint = pos; // Neo góc dưới trái
      } else if (_mode == 1) {
        _trPoint = pos; // Neo góc trên phải
      } else if (_mode == 2) {
        if (_blPoint != null && _trPoint != null) {
           _minTracePx.add(pos);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thiết lập Trục toạ độ trước!')));
        }
      } else if (_mode == 3) {
        if (_blPoint != null && _trPoint != null) {
           _maxTracePx.add(pos);
        } else {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vui lòng thiết lập Trục toạ độ trước!')));
        }
      }
    });
  }

  double _pxToVal(double px, double pMin, double pMax, double vMin, double vMax, bool isYAxis) {
    // Vì trục Y pixel đi từ trên xuống dưới (0 ở top)
    double ratio;
    if (isYAxis) {
       // O(min) nằm ở dưới (pMax là px lớn nhất = bottom)
       ratio = (pMax - px) / (pMax - pMin);
    } else {
       // O(min) nằm ở trái (pMin = left)
       ratio = (px - pMin) / (pMax - pMin);
    }
    
    // Log Scale
    if (vMin <= 0 || vMax <= 0) return vMin;
    double logV1 = log(vMin) / ln10;
    double logV2 = log(vMax) / ln10;
    double logV = logV1 + ratio * (logV2 - logV1);
    return pow(10, logV).toDouble();
  }

  void _processAndSave() async {
     if (_minTracePx.isEmpty || _maxTracePx.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cần chấm đủ cả dải Min và dải Max!')));
        return;
     }

     double kvMin = double.tryParse(kMinCtrl.text) ?? 1;
     double kvMax = double.tryParse(kMaxCtrl.text) ?? 100;
     double tvMin = double.tryParse(tMinCtrl.text) ?? 0.01;
     double tvMax = double.tryParse(tMaxCtrl.text) ?? 10000;

     double pLeft = _blPoint!.dx;
     double pRight = _trPoint!.dx;
     double pBottom = _blPoint!.dy; // pixel y lớn (nằm dưới)
     double pTop = _trPoint!.dy;    // pixel y nhỏ (nằm trên)

     // Convert trace points to log logic
     List<CurvePoint> finalPts = [];

     // Gộp 2 dải. (Gỉa sử gộp theo mốc k của rải Min làm chuẩn để nội suy rải Max)
     // Hoặc lấy tất cả k của cả 2 rải, gộp chung, rồi nội suy lẫn nhau.
     // Đơn giản nhất: Ta sắp xếp _minTracePx và _maxTracePx theo pixel X
     _minTracePx.sort((a,b) => a.dx.compareTo(b.dx));
     _maxTracePx.sort((a,b) => a.dx.compareTo(b.dx));

     // Lấy tất cả giá trị X (k) được chấm từ Min
     for (var pt in _minTracePx) {
         double kVal = _pxToVal(pt.dx, pLeft, pRight, kvMin, kvMax, false);
         double tMinVal = _pxToVal(pt.dy, pTop, pBottom, tvMin, tvMax, true);
         
         // Nội suy ra tMaxVal trên rải MaxPx từ toạ độ X hiện tại
         double tMaxVal = _findMatchingYInTrace(pt.dx, _maxTracePx, pTop, pBottom, tvMin, tvMax);

         finalPts.add(CurvePoint(k: double.parse(kVal.toStringAsFixed(3)), tMin: double.parse(tMinVal.toStringAsFixed(3)), tMax: double.parse(tMaxVal.toStringAsFixed(3))));
     }

     // Build object
     final curve = BreakerCurve(
       id: 'Hãng_${DateTime.now().millisecondsSinceEpoch}', // ID tạm
       brand: 'Custom Brand',
       series: 'Custom Series',
       type: 'C',
       points: finalPts,
     );

     // Có thể hiển thị màn hinh cho người dùng nhập Tên hãng, Series rồi lưu.
     _showSaveDialog(curve);
  }

  double _findMatchingYInTrace(double pxX, List<Offset> tracePx, double pTop, double pBottom, double tvMin, double tvMax) {
     if (tracePx.isEmpty) return tvMax;
     if (pxX <= tracePx.first.dx) return _pxToVal(tracePx.first.dy, pTop, pBottom, tvMin, tvMax, true);
     if (pxX >= tracePx.last.dx) return _pxToVal(tracePx.last.dy, pTop, pBottom, tvMin, tvMax, true);

     for (int i=0; i<tracePx.length-1; i++) {
        if (pxX >= tracePx[i].dx && pxX <= tracePx[i+1].dx) {
            // Linear interpolate on pixel space Y
            double ratio = (pxX - tracePx[i].dx) / (tracePx[i+1].dx - tracePx[i].dx);
            double pyY = tracePx[i].dy + ratio*(tracePx[i+1].dy - tracePx[i].dy);
            return _pxToVal(pyY, pTop, pBottom, tvMin, tvMax, true);
        }
     }
     return tvMax;
  }

  void _showSaveDialog(BreakerCurve baseCurve) {
     final brandCtrl = TextEditingController(text: 'ABB');
     final seriesCtrl = TextEditingController(text: 'S200');
     final typeCtrl = TextEditingController(text: 'C');

     showDialog(
       context: context,
       builder: (ctx) => AlertDialog(
          title: const Text('Lưu Đặc Tuyến'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
               TextField(controller: brandCtrl, decoration: const InputDecoration(labelText: 'Hãng sản xuất')),
               TextField(controller: seriesCtrl, decoration: const InputDecoration(labelText: 'Dòng máy (Series)')),
               TextField(controller: typeCtrl, decoration: const InputDecoration(labelText: 'Loại (Type B/C/D)')),
            ],
          ),
          actions: [
             TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
             ElevatedButton(
                onPressed: () async {
                   final finalCurve = BreakerCurve(
                      id: '${brandCtrl.text}_${seriesCtrl.text}_${typeCtrl.text}'.replaceAll(' ', ''),
                      brand: brandCtrl.text,
                      series: seriesCtrl.text,
                      type: typeCtrl.text,
                      points: baseCurve.points,
                   );
                   await BreakerCurveManager.saveCurve(finalCurve);
                   if (!mounted) return;
                   Navigator.pop(ctx);
                   ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Lưu đặc tuyến thành công!')));
                },
                child: const Text('Lưu')
             )
          ],
       )
     );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PHÂN TÍCH ẢNH CATALOGUE'),
        actions: [
           IconButton(icon: const Icon(Icons.camera_alt), onPressed: _pickImage)
        ],
      ),
      body: Column(
        children: [
          Container(
             padding: const EdgeInsets.all(8),
             color: AppTheme.myMedNavy,
             child: Column(
                children: [
                   const Text(
                     "⚠️ KẾT QUẢ ĐỌC ĐIỂM TRÊN APP CHỈ MANG TÍNH THAM KHẢO!\nVùng cắt nhanh (t < 0.1s) thường rất méo trên Catalogue ảnh chụp nền hãy cẩn trọng vùng ngắn mạch.",
                     style: TextStyle(color: Colors.amberAccent, fontSize: 13, fontWeight: FontWeight.bold),
                   ),
                   const Divider(color: Colors.white24),
                   Row(
                      children: [
                         Expanded(child: TextField(controller: kMinCtrl, decoration: const InputDecoration(labelText: 'X-min (Hệ số K)'))),
                         const SizedBox(width: 4),
                         Expanded(child: TextField(controller: kMaxCtrl, decoration: const InputDecoration(labelText: 'X-max (Hệ số K)'))),
                         const SizedBox(width: 4),
                         Expanded(child: TextField(controller: tMinCtrl, decoration: const InputDecoration(labelText: 'Y-min (Thời gian)'))),
                         const SizedBox(width: 4),
                         Expanded(child: TextField(controller: tMaxCtrl, decoration: const InputDecoration(labelText: 'Y-max (Thời gian)'))),
                      ],
                   )
                ],
             ),
          ),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(label: const Text('1. Neo Góc Trái Dưới'), selected: _mode == 0, onSelected: (v) => setState(() => _mode = 0)),
              ChoiceChip(label: const Text('2. Neo Góc Phải Trên'), selected: _mode == 1, onSelected: (v) => setState(() => _mode = 1)),
              ChoiceChip(label: const Text('3. Chấm Dải Min'), selected: _mode == 2, onSelected: (v) => setState(() => _mode = 2)),
              ChoiceChip(label: const Text('4. Chấm Dải Max'), selected: _mode == 3, onSelected: (v) => setState(() => _mode = 3)),
            ],
          ),
          Expanded(
            child: _imageFile == null
              ? const Center(child: Text('Vui lòng bật biểu tượng Camera ở góc trên bên phải để chụp/chọn ảnh'))
              : InteractiveViewer( // Hỗ trợ Zoom mượt mà
                  maxScale: 10,
                  child: GestureDetector(
                    onTapUp: _handleTap,
                    child: Stack(
                      children: [
                         Image.file(_imageFile!, fit: BoxFit.contain, width: double.infinity, height: double.infinity),
                         // Vẽ các điểm neo
                         if (_blPoint != null) Positioned(left: _blPoint!.dx-10, top: _blPoint!.dy-10, child: const Icon(Icons.gps_fixed, color: Colors.blueAccent)),
                         if (_trPoint != null) Positioned(left: _trPoint!.dx-10, top: _trPoint!.dy-10, child: const Icon(Icons.gps_fixed, color: Colors.blue)),
                         
                         // Vẽ dải Min
                         ..._minTracePx.map((p) => Positioned(left: p.dx-5, top: p.dy-5, child: const Icon(Icons.circle, size: 10, color: Colors.greenAccent))),
                         
                         // Vẽ dải Max
                         ..._maxTracePx.map((p) => Positioned(left: p.dx-5, top: p.dy-5, child: const Icon(Icons.circle, size: 10, color: Colors.redAccent))),
                      ],
                    ),
                  )
              ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _processAndSave,
        backgroundColor: AppTheme.myOrangeAccent,
        child: const Icon(Icons.save),
      ),
    );
  }
}
