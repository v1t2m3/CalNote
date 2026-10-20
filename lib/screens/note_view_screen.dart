import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/test_record.dart';
import '../core/utils/app_formatters.dart';
import '../core/theme/app_theme.dart';


class NoteViewScreen extends StatelessWidget {
  final TestRecord record;

  const NoteViewScreen({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chi Tiết Bản Ghi'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tiêu đề
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Tên phép thử nghiệm', style: AppTheme.captionStyle),
                    const SizedBox(height: 4),
                    Text(record.title, style: AppTheme.titleModuleStyle),
                    const SizedBox(height: 8),
                    Text('Ngày đo: ${record.timestamp.toString().substring(0, 16)}', style: AppTheme.captionItalic),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Danh sách các thông số
            ...record.calculations.map((calc) => Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tính toán: ${calc.name}', style: const TextStyle(fontSize: AppTheme.fontSizeTitle, fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
                    const Divider(),
                    ...calc.inputs.entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(entry.key, style: const TextStyle(fontSize: AppTheme.fontSizeBody, color: Colors.white70)),
                            Text('${entry.value}', style: AppTheme.bodyBoldWhite),
                          ],
                        ),
                      );
                    }),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('=> Kết quả tính:', style: TextStyle(fontSize: AppTheme.fontSizeBody, fontWeight: FontWeight.bold, color: Colors.white)),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(AppFormatters.formatSmart(calc.result, unit: calc.unit), style: const TextStyle(fontSize: AppTheme.fontSizeBody, fontWeight: FontWeight.bold, color: AppTheme.accentOrange)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )),
            
            const SizedBox(height: 16),

            // Khu vực ảnh đính kèm
            const Text('Hình ảnh đính kèm:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            const SizedBox(height: 8),
            if (record.imagePaths.isEmpty)
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text('Bản ghi này hông có chụp hình máy đo.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.white60)),
              )
            else
              SizedBox(
                height: 200,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: record.imagePaths.length,
                  itemBuilder: (context, index) {
                    final pathStr = record.imagePaths[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: Card(
                        clipBehavior: Clip.antiAlias,
                        elevation: 4,
                        child: kIsWeb 
                            ? Image.network(pathStr, width: 160, height: 200, fit: BoxFit.cover)
                            : Image.file(File(pathStr), width: 160, height: 200, fit: BoxFit.cover),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
