import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

class ReferenceItem {
  final String category;
  final String subCategory;
  final String item;
  final String limit;
  final String standard;

  const ReferenceItem({
    required this.category,
    required this.subCategory,
    required this.item,
    required this.limit,
    required this.standard,
  });
}

class ReferenceStandardScreen extends StatefulWidget {
  const ReferenceStandardScreen({super.key});

  @override
  State<ReferenceStandardScreen> createState() => _ReferenceStandardScreenState();
}

class _ReferenceStandardScreenState extends State<ReferenceStandardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "Tất cả";

  final List<String> _categories = [
    "Tất cả",
    "Tiếp Địa",
    "Máy Biến Áp",
    "Máy Cắt",
    "Dao Cách Ly",
    "Cáp Điện Lực",
    "Chống Sét Van",
    "Biến Dòng / Áp",
  ];

  final List<ReferenceItem> _referenceItems = const [
    // 1. Hệ Thống Nối Đất (Tiếp Địa)
    ReferenceItem(
      category: "Tiếp Địa",
      subCategory: "Nối đất Trạm biến áp 110kV",
      item: "Điện trở nối đất (Rtđ)",
      limit: "≤0.5 Ω (hoặc thỏa mãn điện áp chạm/điện áp bước)",
      standard: "QCVN 01:2020/BCT, TCVN 9358:2012, IEEE Std 80",
    ),
    ReferenceItem(
      category: "Tiếp Địa",
      subCategory: "Nối đất Đường dây 110kV",
      item: "Điện trở nối đất cột",
      limit: "≤10 Ω ÷ 30 Ω (tùy điện trở suất đất vùng)",
      standard: "QCVN 01:2020/BCT, TCVN 9358:2012",
    ),
    ReferenceItem(
      category: "Tiếp Địa",
      subCategory: "Nối đất Trạm / Cột Trung thế (22–35kV)",
      item: "Điện trở nối đất",
      limit: "≤4 Ω ÷ 10 Ω (Trạm phân phối: ≤4 Ω)",
      standard: "TCVN 9358:2012, QCVN QTĐ 8:2010/BCT",
    ),
    ReferenceItem(
      category: "Tiếp Địa",
      subCategory: "Nối đất Hạ thế (0.4kV)",
      item: "Điện trở nối đất trung tính / vỏ",
      limit: "≤4 Ω (nếu nối đất chung: ≤4 Ω)",
      standard: "TCVN 9358:2012, TCVN 7447",
    ),

    // 2. Máy Biến Áp Lực (MBA 110kV & Trung Thế)
    ReferenceItem(
      category: "Máy Biến Áp",
      subCategory: "Điện trở cách điện cuộn dây (MBA)",
      item: "R60s & Hệ số hấp thụ Kht = R60s/R15s",
      limit: "• R60s ≥ 1.000 MΩ (Phía 110kV); ≥ 300 MΩ (Trung thế)\n• Kht ≥ 1.3",
      standard: "TCVN 6306 / IEC 60076, IEEE C57.12.90",
    ),
    ReferenceItem(
      category: "Máy Biến Áp",
      subCategory: "Tổn hao điện môi (tanδ) cuộn dây",
      item: "Tang góc tổn hao tanδ (20°C)",
      limit: "≤0.8% (MBA mới 110kV); ≤1.5% (MBA đang vận hành)",
      standard: "IEC 60076-1, IEEE C57.12.90",
    ),
    ReferenceItem(
      category: "Máy Biến Áp",
      subCategory: "Điện trở một chiều cuộn dây (R1c)",
      item: "Độ lệch giữa các pha / nấc phân áp",
      limit: "Sai lệch giữa các pha ≤2% so với giá trị trung bình",
      standard: "TCVN 6306-1 / IEC 60076-1",
    ),
    ReferenceItem(
      category: "Máy Biến Áp",
      subCategory: "Tỷ số biến áp (K)",
      item: "Tỷ số điện áp các nấc",
      limit: "Sai lệch ≤0.5% so với danh định / nhà sản xuất",
      standard: "TCVN 6306-1 / IEC 60076-1",
    ),
    ReferenceItem(
      category: "Máy Biến Áp",
      subCategory: "Dầu cách điện (Thử điện áp phóng điện)",
      item: "Điện áp đánh thủng cách điện dầu",
      limit: "• ≥60 kV (MBA Phía 110kV)\n• ≥40 kV (MBA Trung thế)",
      standard: "TCVN 7592 / IEC 60156, ASTM D877",
    ),
    ReferenceItem(
      category: "Máy Biến Áp",
      subCategory: "Khí hòa tan trong dầu (DGA)",
      item: "Hàm lượng C2H2, H2, C2H4...",
      limit: "Không phát hiện C2H2 (Acetylen > 1 ppm cần cảnh báo); H2 < 100 ppm",
      standard: "IEC 60599, IEEE C57.104",
    ),

    // 3. Máy Cắt Điện (CB / Recloser)
    ReferenceItem(
      category: "Máy Cắt",
      subCategory: "Điện trở tiếp xúc (Rtx)",
      item: "Điện trở tiếp điểm chính",
      limit: "≤50 ÷ 100 μΩ (Phía 110kV); ≤100 ÷ 200 μΩ (Trung thế) (hoặc theo catalogue NSX)",
      standard: "TCVN 8096 / IEC 62271-100 / IEC 62271-1",
    ),
    ReferenceItem(
      category: "Máy Cắt",
      subCategory: "Thời gian đóng/mở & Độ đồng pha",
      item: "Thời gian thao tác (t_đóng, t_mở)",
      limit: "• t_mở ≤ 40 ms; t_đóng ≤ 100 ms\n• Độ lệch đồng pha giữa các cực ≤2 ÷ 3 ms",
      standard: "IEC 62271-100, TCVN 8096",
    ),
    ReferenceItem(
      category: "Máy Cắt",
      subCategory: "Khí cách điện SF6 (Máy cắt SF6)",
      item: "Độ ẩm & Độ tinh khiết",
      limit: "• Độ ẩm ≤150 ppm (nghiệm thu); ≤300 ppm (định kỳ)\n• Độ tinh khiết ≥97%",
      standard: "IEC 60376, IEC 62271-4",
    ),

    // 4. Dao Cách Ly (DS) / Dao Cắt Phụ Tải (LBS)
    ReferenceItem(
      category: "Dao Cách Ly",
      subCategory: "Điện trở tiếp xúc (Rtx)",
      item: "Tiếp điểm lưỡi dao",
      limit: "≤100 ÷ 200 μΩ (tùy dòng định mức)",
      standard: "IEC 62271-102, TCVN 8096",
    ),
    ReferenceItem(
      category: "Dao Cách Ly",
      subCategory: "Điện trở cách điện",
      item: "Giữa các pha & với đất",
      limit: "≥1.000 MΩ (Phía 110kV); ≥500 MΩ (Trung thế)",
      standard: "IEC 62271-1",
    ),

    // 5. Cáp Điện Lực (Cáp Ngầm & Cáp Hạ Thế)
    ReferenceItem(
      category: "Cáp Điện Lực",
      subCategory: "Điện trở cách điện cáp hạ thế (0.4kV)",
      item: "R_cách_điện (Dùng Megohmmeter 1kV/2.5kV)",
      limit: "≥0.5 MΩ (Quy chuẩn tối thiểu) (Thực tế nên ≥10 MΩ)",
      standard: "TCVN 5935 / IEC 60502-1",
    ),
    ReferenceItem(
      category: "Cáp Điện Lực",
      subCategory: "Điện trở cách điện cáp Trung thế / 110kV",
      item: "R_cách_điện (Dùng Megohmmeter 2.5kV/5kV)",
      limit: "≥1.000 MΩ/km",
      standard: "TCVN 5935 / IEC 60502-2, IEEE 400",
    ),
    ReferenceItem(
      category: "Cáp Điện Lực",
      subCategory: "Thử chịu điện áp tần số thấp (VLF 0.1Hz) - Cáp Trung thế",
      item: "Thử điện áp VLF (2 ÷ 3 U0) trong 15–60 phút",
      limit: "Không bị phóng điện / thủng cách điện trong suốt thời gian thử",
      standard: "IEEE 400.2, IEC 60502-2",
    ),
    ReferenceItem(
      category: "Cáp Điện Lực",
      subCategory: "Thử vỏ bảo vệ cáp ngầm (Outer sheath test)",
      item: "Điện áp DC 5kV/10kV trong 1 phút",
      limit: "Dòng rò ổn định, không bị thủng vỏ (R ≥ 10 MΩ/km)",
      standard: "IEC 60229, TCVN 10889",
    ),

    // 6. Chống Sét Van (LA - Lightning Arrester)
    ReferenceItem(
      category: "Chống Sét Van",
      subCategory: "Điện trở cách điện",
      item: "R_cách_điện ở điện áp thử 2.5kV/5kV",
      limit: "≥2.000 MΩ (với LA 110kV); ≥1.000 MΩ (với LA trung thế)",
      standard: "IEC 60099-4, TCVN 8097",
    ),
    ReferenceItem(
      category: "Chống Sét Van",
      subCategory: "Dòng điện rò ở điện áp làm việc",
      item: "Dòng rò rò rỉ (Total / Resistive Leakage Current)",
      limit: "≤1 ÷ 2 mA (Tổng); Dòng điện trở rò ≤50 ÷ 100 μA (tùy hãng)",
      standard: "IEC 60099-4, IEEE C62.11",
    ),

    // 7. Máy Biến Dòng Điện (CT) & Biến Điện Áp (VT/PT)
    ReferenceItem(
      category: "Biến Dòng / Áp",
      subCategory: "Điện trở cách điện cuộn dây",
      item: "R_cách_điện Sơ cấp & Thứ cấp",
      limit: "• Sơ cấp: ≥1.000 MΩ (110kV), ≥500 MΩ (Trung thế)\n• Thứ cấp: ≥10 MΩ",
      standard: "IEC 61869-1/2/3, TCVN 7697",
    ),
    ReferenceItem(
      category: "Biến Dòng / Áp",
      subCategory: "Tỷ số biến & Sai lệch góc pha",
      item: "Tỷ số dòng/áp & Sai số đo lường/bảo vệ",
      limit: "Đạt cấp chính xác đăng ký (Ví dụ: Cấp 0.2, 0.5, 5P20, 10P20...)",
      standard: "IEC 61869-2 (CT), IEC 61869-3 (VT)",
    ),
    ReferenceItem(
      category: "Biến Dòng / Áp",
      subCategory: "Thử đặc tính từ hóa (CT)",
      item: "Điện áp đầu gối (Knee-point Voltage)",
      limit: "Thỏa mãn đồ thị từ hóa thiết kế / nhà sản xuất",
      standard: "IEC 61869-2",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách dữ liệu theo từ khóa tìm kiếm và nhóm
    final List<ReferenceItem> filteredItems = _referenceItems.where((item) {
      final matchesSearch = item.subCategory.toLowerCase().contains(_searchQuery) ||
          item.item.toLowerCase().contains(_searchQuery) ||
          item.limit.toLowerCase().contains(_searchQuery) ||
          item.standard.toLowerCase().contains(_searchQuery);
      
      final matchesCategory = _selectedCategory == "Tất cả" || item.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("TIÊU CHUẨN THỬ NGHIỆM"),
      ),
      body: Column(
        children: [
          // THANH TÌM KIẾM
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Tìm kiếm hạng mục, tiêu chuẩn...",
                prefixIcon: const Icon(Icons.search, color: AppTheme.myOrangeAccent),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, color: Colors.white70),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = "";
                          });
                        },
                      )
                    : null,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              ),
              onChanged: (val) {
                setState(() {
                  _searchQuery = val.toLowerCase().trim();
                });
              },
            ),
          ),

          // LỰA CHỌN PHÂN LOẠI (CHIPS)
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(category),
                    selected: isSelected,
                    selectedColor: AppTheme.myOrangeAccent,
                    backgroundColor: AppTheme.myDarkNavy,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // DANH SÁCH TIÊU CHUẨN
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      "Không tìm thấy hạng mục nào phù hợp.",
                      style: TextStyle(color: Colors.white38, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Nhãn Đối tượng & Nhóm
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.myOrangeAccent.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppTheme.myOrangeAccent,
                                          width: 0.5),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(
                                          color: AppTheme.myOrangeAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        item.subCategory,
                                        style: const TextStyle(
                                            color: Colors.cyanAccent,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              
                              // Tên Hạng mục đo
                              Text(
                                item.item,
                                style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                              const Divider(height: 16, color: Colors.white12),

                              // Tiêu Chuẩn Đạt (Pass Limit)
                              const Text(
                                "Tiêu chuẩn Đạt (Pass Limit):",
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.limit,
                                style: const TextStyle(
                                    color: Colors.greenAccent,
                                    fontSize: 15,
                                    height: 1.3),
                              ),
                              const SizedBox(height: 8),

                              // Tiêu Chuẩn Tham Chiếu
                              const Text(
                                "Tiêu chuẩn Tham chiếu:",
                                style: TextStyle(
                                    color: Colors.white54,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item.standard,
                                style: const TextStyle(
                                    color: Colors.orangeAccent,
                                    fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
