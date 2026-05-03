import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/test_record.dart';
import '../core/theme/app_theme.dart';
import 'note_view_screen.dart';
import '../services/export_service.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  Box<TestRecord>? _box;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _box = await Hive.openBox<TestRecord>('test_records_v2');
    setState(() {});
  }

  void _deleteRecord(String key) async {
    await _box?.delete(key);
    setState(() {});
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xóa bản ghi này cho rảnh nợ rồi nghen!')),
      );
    }
  }

  void _exportAndShareRecord(TestRecord record) async {
    // Vẫn tạo file nội bộ để lưu trữ ngầm, nhưng chỉ Share text string!
    await ExportService.exportRecordToTxt(record);
    
    // Gửi thẳng text string vào clipboard/Zalo
    await ExportService.shareTxtContent(record);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SỔ TAY THỬ NGHIỆM'),
      ),
      body: _box == null
          ? const Center(child: CircularProgressIndicator())
          : _box!.isEmpty
              ? const Center(
                  child: Text('Chưa có bản ghi nào lưu trong sổ tay hết trơn.',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 16)),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: _box!.length,
                  itemBuilder: (context, index) {
                    final record = _box!.getAt(index);
                    if (record == null) return const SizedBox.shrink();

                    List<String> calcNames = record.calculations.map((c) => c.name).toList();
                    String calcNamesStr = calcNames.join(', ');
                    if (calcNamesStr.length > 35) {
                      calcNamesStr = '${calcNamesStr.substring(0, 32)}...';
                    }

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: AppTheme.myMedNavy, width: 1.5),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: AppTheme.myBrightBlue,
                          child: const Icon(Icons.description, color: Colors.white),
                        ),
                        title: Text(record.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        subtitle: Text(
                          'Tính toán: $calcNamesStr\nNgày lưu: ${record.timestamp.day}/${record.timestamp.month}/${record.timestamp.year}',
                          style: const TextStyle(height: 1.5),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.share, color: Colors.blueAccent),
                              onPressed: () => _exportAndShareRecord(record),
                              tooltip: 'Chia sẻ file Text',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteRecord(record.id),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => NoteViewScreen(record: record),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
