import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/reference_standard_service.dart';

class ReferenceStandardScreen extends StatefulWidget {
  const ReferenceStandardScreen({super.key});

  @override
  State<ReferenceStandardScreen> createState() =>
      _ReferenceStandardScreenState();
}

class _ReferenceStandardScreenState extends State<ReferenceStandardScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  String _selectedCategory = "Tất cả";

  List<ReferenceItemModel> _referenceItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  void _loadItems() {
    setState(() {
      _referenceItems = ReferenceStandardService.getAllStandards();
    });
  }

  List<String> get _categories {
    final categories = _referenceItems.map((e) => e.category).toSet().toList();
    categories.sort();
    return ["Tất cả", ...categories];
  }

  @override
  Widget build(BuildContext context) {
    // Lọc danh sách dữ liệu theo từ khóa tìm kiếm và nhóm
    final List<ReferenceItemModel> filteredItems = _referenceItems.where((item) {
      final matchesSearch =
          item.subCategory.toLowerCase().contains(_searchQuery) ||
              item.item.toLowerCase().contains(_searchQuery) ||
              item.limit.toLowerCase().contains(_searchQuery) ||
              item.standard.toLowerCase().contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == "Tất cả" || item.category == _selectedCategory;

      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("TIÊU CHUẨN THỬ NGHIỆM"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () {
              _loadItems();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã cập nhật lại danh sách tiêu chuẩn")),
              );
            },
          )
        ],
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
                prefixIcon:
                    const Icon(Icons.search, color: AppTheme.myOrangeAccent),
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
                contentPadding:
                    const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
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

          // DANH SÁCH THÔNG TIN TIÊU CHUẨN
          Expanded(
            child: filteredItems.isEmpty
                ? const Center(
                    child: Text(
                      "Không tìm thấy tiêu chuẩn nào phù hợp.",
                      style: TextStyle(color: Colors.white54, fontSize: 16),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      final item = filteredItems[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        color: AppTheme.myMedNavy,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: AppTheme.myOrangeAccent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Nhãn Đối tượng & Nhóm
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppTheme.myOrangeAccent
                                          .withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(
                                          color: AppTheme.myOrangeAccent,
                                          width: 0.8),
                                    ),
                                    child: Text(
                                      item.category,
                                      style: const TextStyle(
                                        color: AppTheme.myOrangeAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      item.subCategory,
                                      textAlign: TextAlign.end,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
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
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Giới hạn Tiêu chuẩn
                              const Text(
                                "Quy định / Giới hạn:",
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
                                    color: Colors.orangeAccent, fontSize: 14),
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
