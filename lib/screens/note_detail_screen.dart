import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/test_record.dart';
import '../services/export_service.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';


class NoteDetailScreen extends StatefulWidget {
  final List<TestCalculation> calculations;
  final String deviceName;

  const NoteDetailScreen({
    super.key,
    required this.calculations,
    this.deviceName = 'Thiết bị',
  });

  @override
  State<NoteDetailScreen> createState() => _NoteDetailScreenState();
}

class _NoteDetailScreenState extends State<NoteDetailScreen> {
  final TextEditingController _titleController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _attachedImages = [];

  @override
  void initState() {
    super.initState();
    String defaultName = '${widget.deviceName} - ${DateFormat('dd/MM/yyyy - HH:mm').format(DateTime.now())}';
    _titleController.text = defaultName;
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (image != null) {
        if (kIsWeb) {
          setState(() {
            _attachedImages.add(image);
          });
        } else {
          final directory = await getApplicationDocumentsDirectory();
          final String newPath = '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
          await File(image.path).copy(newPath);

          setState(() {
            _attachedImages.add(XFile(newPath));
          });
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cắt cái rẹt! Cất hình xong gòi nghen bồ.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi chụp hình: $e. Coi lại quyền camera coi!')),
        );
      }
    }
  }

  Future<void> _saveToNote() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ghi cái tên cẩn thận đặng mai mốt còn kiếm chớ đại ca!')),
      );
      return;
    }

    try {
      final box = await Hive.openBox<TestRecord>('test_records_v2'); // Sử dụng box mới do cấu trúc thay đổi
      
      final newRecord = TestRecord(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _titleController.text.trim(),
        calculations: widget.calculations,
        timestamp: DateTime.now(),
        imagePaths: _attachedImages.map((e) => e.path).toList(),
      );

      // Lưu file xuất dưới dạng .txt
      String? savedTxtPath = await ExportService.exportRecordToTxt(newRecord);

      // Lưu Local DB
      await box.put(newRecord.id, newRecord);

      if (mounted) {
        String msg = 'Đã lưu vô sổ cái rụp. Yên tâm đi nhậu thôi!';
        if (savedTxtPath != null) {
           msg += '\nĐã tạo file TXT tại: $savedTxtPath';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 4)),
        );
        Navigator.pop(context); // Trở về
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ghi hông được ồi: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lưu Sổ Tay Hiện Trường'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // TextField nhập tên
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _titleController,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: 'Tên phép thử nghiệm',
                    border: OutlineInputBorder(),
                    hintText: 'Nhập tên hoặc để mặc định',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Danh sách các thông số
            ...widget.calculations.map((calc) => Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tính toán: ${calc.name}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                    const Divider(),
                    ...calc.inputs.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: 16)),
                            Text('${entry.value}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('=> Kết quả tính:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${calc.result.toStringAsFixed(3)} ${calc.unit}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
                      ],
                    ),
                  ],
                ),
              ),
            )),

            const SizedBox(height: 16),

            // Khu vực ảnh đính kèm
            const Text('Hình ảnh đính kèm (cho tất cả phép đo):', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            if (_attachedImages.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Chưa có chộp tấm hình nào nghen.', style: TextStyle(fontStyle: FontStyle.italic)),
              )
            else
              SizedBox(
                height: 150,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _attachedImages.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Card(
                          clipBehavior: Clip.antiAlias,
                          child: kIsWeb 
                              ? Image.network(_attachedImages[index].path, width: 120, height: 150, fit: BoxFit.cover)
                              : Image.file(File(_attachedImages[index].path), width: 120, height: 150, fit: BoxFit.cover),
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _attachedImages.removeAt(index);
                              });
                            },
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            
            const SizedBox(height: 24),
            
            // Nút bấm
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickImage,
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Chụp Thêm Hình'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveToNote,
                    icon: const Icon(Icons.save),
                    label: const Text('Lưu Sổ & File Text'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    ),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
