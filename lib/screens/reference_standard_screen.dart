import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/reference_standard_service.dart';

class ReferenceStandardScreen extends StatefulWidget {
  const ReferenceStandardScreen({super.key});

  @override
  State<ReferenceStandardScreen> createState() =>
      _ReferenceStandardScreenState();
}

class _ReferenceStandardScreenState extends State<ReferenceStandardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = "";
  String _selectedVoltage = "ALL"; // "ALL", "<=35kV", "110kV"

  List<ReferenceItemModel> _standardsList = [];
  List<TT02ItemModel> _tt02List = [];
  List<CbmItemModel> _cbmList = [];

  final List<Map<String, dynamic>> _deviceCategories = const [
    {
      'code': 'transformer',
      'name': 'Máy Biến Áp',
      'icon': Icons.flash_on,
      'color': Colors.amberAccent
    },
    {
      'code': 'circuit_breaker',
      'name': 'Máy Cắt & Tủ Đóng Cắt',
      'icon': Icons.toggle_on,
      'color': Colors.lightBlueAccent
    },
    {
      'code': 'disconnector',
      'name': 'Dao Cách Ly & Cầu Chì',
      'icon': Icons.alt_route,
      'color': Colors.orangeAccent
    },
    {
      'code': 'surge_arrester',
      'name': 'Chống Sét Van',
      'icon': Icons.bolt,
      'color': Colors.yellowAccent
    },
    {
      'code': 'instrument_transformer',
      'name': 'Biến Dòng & Biến Áp (TI/TU)',
      'icon': Icons.settings_input_component,
      'color': Colors.cyanAccent
    },
    {
      'code': 'cable',
      'name': 'Cáp Điện Lực',
      'icon': Icons.cable,
      'color': Colors.greenAccent
    },
    {
      'code': 'grounding',
      'name': 'Hệ Thống Nối Đất',
      'icon': Icons.horizontal_rule,
      'color': Colors.tealAccent
    },
    {
      'code': 'relay_safety',
      'name': 'Rơ Le & Dụng Cụ An Toàn',
      'icon': Icons.security,
      'color': Colors.purpleAccent
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _loadAllData() {
    setState(() {
      _standardsList = ReferenceStandardService.getAllStandards();
      _tt02List = ReferenceStandardService.getAllTT02();
      _cbmList = ReferenceStandardService.getAllCBM();
    });
  }

  int _getItemCountForCategory(String catCode, int tabIndex) {
    bool matchesVoltage(String level) {
      if (_selectedVoltage == "ALL") return true;
      return level == _selectedVoltage || level == "ALL";
    }

    if (tabIndex == 0) {
      return _standardsList
          .where((e) => e.categoryCode == catCode && matchesVoltage(e.voltageLevel))
          .length;
    } else if (tabIndex == 1) {
      return _tt02List
          .where((e) => e.categoryCode == catCode && matchesVoltage(e.voltageLevel))
          .length;
    } else {
      return _cbmList
          .where((e) => e.categoryCode == catCode && matchesVoltage(e.voltageLevel))
          .length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("TRA CỨU TIÊU CHUẨN THIẾT BỊ"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Làm mới dữ liệu',
            onPressed: () {
              _loadAllData();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Đã cập nhật lại toàn bộ tiêu chuẩn")),
              );
            },
          )
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.myOrangeAccent,
          indicatorWeight: 3,
          labelColor: AppTheme.myOrangeAccent,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          tabs: const [
            Tab(icon: Icon(Icons.science), text: "Thử Nghiệm"),
            Tab(icon: Icon(Icons.verified_user), text: "Kiểm Định TT02"),
            Tab(icon: Icon(Icons.analytics), text: "Đánh Giá CBM"),
          ],
        ),
      ),
      body: Column(
        children: [
          // MỨC 2: BỘ LỌC CẤP ĐIỆN ÁP & THANH TÌM KIẾM
          Container(
            color: AppTheme.myDarkNavy,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: [
                // Thanh Tìm kiếm
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "Tìm kiếm hạng mục, tiêu chuẩn, thiết bị...",
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
                const SizedBox(height: 8),

                // Bộ lọc Cấp Điện Áp
                Row(
                  children: [
                    const Text(
                      "Cấp điện áp: ",
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _buildVoltageChip("Tất cả", "ALL"),
                    const SizedBox(width: 6),
                    _buildVoltageChip("≤ 35kV (Trung thế)", "<=35kV"),
                    const SizedBox(width: 6),
                    _buildVoltageChip("110kV (Cao thế)", "110kV"),
                  ],
                ),
              ],
            ),
          ),

          // MỨC 3: THIẾT BỊ / ĐỐI TƯỢNG ĐO DẠNG CARDS HOẶC DANH SÁCH HẠNG MỤC
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStandardTabContent(0),
                _buildStandardTabContent(1),
                _buildStandardTabContent(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageChip(String label, String value) {
    final isSelected = _selectedVoltage == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.myOrangeAccent,
      backgroundColor: AppTheme.myMedNavy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedVoltage = value;
          });
        }
      },
    );
  }

  Widget _buildStandardTabContent(int tabIndex) {
    // Nếu có tìm kiếm từ khóa, hiển thị danh sách kết quả trực tiếp
    if (_searchQuery.isNotEmpty) {
      return _buildSearchResultsView(tabIndex);
    }

    // Nếu không có tìm kiếm, hiển thị MỨC 3: CARDS THIẾT BỊ
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "CHỌN THIẾT BỊ CẦN TRA CỨU:",
            style: TextStyle(
              color: AppTheme.myOrangeAccent,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.15,
              ),
              itemCount: _deviceCategories.length,
              itemBuilder: (context, index) {
                final dev = _deviceCategories[index];
                final count = _getItemCountForCategory(dev['code'], tabIndex);
                final IconData iconData = dev['icon'];
                final Color iconColor = dev['color'];

                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => DeviceDetailStandardScreen(
                          categoryCode: dev['code'],
                          categoryName: dev['name'],
                          initialTabIndex: tabIndex,
                          voltageLevel: _selectedVoltage,
                        ),
                      ),
                    );
                  },
                  customBorder: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Card(
                    color: AppTheme.myMedNavy,
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(
                        color: count > 0
                            ? iconColor.withValues(alpha: 0.5)
                            : Colors.white10,
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(iconData, size: 40, color: iconColor),
                          const SizedBox(height: 8),
                          Text(
                            dev['name'],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black38,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              "$count chỉ tiêu",
                              style: TextStyle(
                                color: count > 0 ? Colors.greenAccent : Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
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

  Widget _buildSearchResultsView(int tabIndex) {
    bool matchesVoltage(String level) {
      if (_selectedVoltage == "ALL") return true;
      return level == _selectedVoltage || level == "ALL";
    }

    if (tabIndex == 0) {
      final items = _standardsList.where((item) {
        final matchSearch = item.subCategory.toLowerCase().contains(_searchQuery) ||
            item.item.toLowerCase().contains(_searchQuery) ||
            item.limit.toLowerCase().contains(_searchQuery) ||
            item.standard.toLowerCase().contains(_searchQuery);
        return matchSearch && matchesVoltage(item.voltageLevel);
      }).toList();

      if (items.isEmpty) return _buildEmptyState();

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildStandardCard(item, 0);
        },
      );
    } else if (tabIndex == 1) {
      final items = _tt02List.where((item) {
        final matchSearch = item.subCategory.toLowerCase().contains(_searchQuery) ||
            item.item.toLowerCase().contains(_searchQuery) ||
            item.limit.toLowerCase().contains(_searchQuery) ||
            item.standard.toLowerCase().contains(_searchQuery);
        return matchSearch && matchesVoltage(item.voltageLevel);
      }).toList();

      if (items.isEmpty) return _buildEmptyState();

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildTT02Card(item, 1);
        },
      );
    } else {
      final items = _cbmList.where((item) {
        final matchSearch = item.subCategory.toLowerCase().contains(_searchQuery) ||
            item.item.toLowerCase().contains(_searchQuery) ||
            item.good.toLowerCase().contains(_searchQuery) ||
            item.poor.toLowerCase().contains(_searchQuery);
        return matchSearch && matchesVoltage(item.voltageLevel);
      }).toList();

      if (items.isEmpty) return _buildEmptyState();

      return ListView.builder(
        padding: const EdgeInsets.all(12),
        itemCount: items.length,
        itemBuilder: (context, index) {
          final item = items[index];
          return _buildCbmCard(item, 2);
        },
      );
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text(
        "Không tìm thấy chỉ tiêu nào phù hợp với bộ lọc.",
        style: TextStyle(color: Colors.white54, fontSize: 15),
      ),
    );
  }

  Widget _buildStandardCard(ReferenceItemModel item, int currentTab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.myMedNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: AppTheme.myOrangeAccent.withValues(alpha: 0.4), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text(item.category,
                      style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: AppTheme.myOrangeAccent,
                  padding: EdgeInsets.zero,
                ),
                Text(
                  item.subCategory,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.item,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text("Quy định / Giới hạn:",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(item.limit,
                style: const TextStyle(
                    color: Colors.greenAccent, fontSize: 14, height: 1.3)),
            const SizedBox(height: 8),
            const Text("Tiêu chuẩn Tham chiếu:",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(item.standard,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
            const SizedBox(height: 8),
            const Text("Hành động khuyến cáo xử lý:",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(item.recommendation,
                style: const TextStyle(color: Colors.cyanAccent, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildTT02Card(TT02ItemModel item, int currentTab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.myMedNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: Colors.lightBlueAccent.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: const Text("Thông tư 02/2025/TT-BCT",
                      style: TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.blueAccent,
                ),
                Text(
                  item.subCategory,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text("Hạng mục kiểm định: ${item.item}",
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text("Chu kỳ kiểm định: ${item.period}",
                style: const TextStyle(color: Colors.yellowAccent, fontSize: 13)),
            const SizedBox(height: 8),
            const Text("Ngưỡng Yêu Cầu 'ĐẠT':",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(item.limit,
                style: const TextStyle(
                    color: Colors.greenAccent, fontSize: 13, height: 1.3)),
            const SizedBox(height: 8),
            const Text("Căn cứ Quy chuẩn / Tiêu chuẩn:",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(item.standard,
                style: const TextStyle(color: Colors.orangeAccent, fontSize: 13)),
          ],
        ),
      ),
    );
  }

  Widget _buildCbmCard(CbmItemModel item, int currentTab) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppTheme.myMedNavy,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
            color: Colors.purpleAccent.withValues(alpha: 0.5), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Chip(
                  label: Text("CBM (${item.voltageLevel})",
                      style: const TextStyle(fontSize: 11, color: Colors.white)),
                  backgroundColor: Colors.purpleAccent,
                ),
                Text(
                  item.subCategory,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontStyle: FontStyle.italic),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(item.item,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // THANH 4 MỨC CBM (TỐT, KHÁ, TB, XẤU)
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  _buildCbmLevelRow("🟢 Tốt (Mức 1):", item.good, Colors.greenAccent),
                  const Divider(color: Colors.white12, height: 8),
                  _buildCbmLevelRow("🟡 Khá (Mức 2):", item.fair, Colors.yellowAccent),
                  const Divider(color: Colors.white12, height: 8),
                  _buildCbmLevelRow("🟠 Trung bình (Mức 3):", item.average, Colors.orangeAccent),
                  const Divider(color: Colors.white12, height: 8),
                  _buildCbmLevelRow("🔴 Xấu (Mức 4):", item.poor, Colors.redAccent),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text("Hành động xử lý khi Xấu / Không đạt:",
                style: TextStyle(color: Colors.white54, fontSize: 12)),
            Text(item.recommendation,
                style: const TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildCbmLevelRow(String title, String val, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Expanded(
          child: Text(val,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }
}

/// MÀN HÌNH CHI TIẾT HẠNG MỤC THIẾT BỊ CÓ TÍNH NĂNG CHUYỂN ĐỔI / SO SÁNH NHANH
class DeviceDetailStandardScreen extends StatefulWidget {
  final String categoryCode;
  final String categoryName;
  final int initialTabIndex;
  final String voltageLevel;

  const DeviceDetailStandardScreen({
    super.key,
    required this.categoryCode,
    required this.categoryName,
    required this.initialTabIndex,
    required this.voltageLevel,
  });

  @override
  State<DeviceDetailStandardScreen> createState() =>
      _DeviceDetailStandardScreenState();
}

class _DeviceDetailStandardScreenState extends State<DeviceDetailStandardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _currentVoltage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: 3, vsync: this, initialIndex: widget.initialTabIndex);
    _currentVoltage = widget.voltageLevel;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.categoryName),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.myOrangeAccent,
          labelColor: AppTheme.myOrangeAccent,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: "🧪 Thử Nghiệm"),
            Tab(text: "📋 Kiểm Định TT02"),
            Tab(text: "📊 Đánh Giá CBM"),
          ],
        ),
      ),
      body: Column(
        children: [
          // Lựa chọn cấp điện áp nhanh ở màn hình chi tiết
          Container(
            color: AppTheme.myDarkNavy,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            child: Row(
              children: [
                const Text("Cấp điện áp: ",
                    style: TextStyle(color: Colors.white70, fontSize: 13)),
                const SizedBox(width: 8),
                _buildVoltageChip("Tất cả", "ALL"),
                const SizedBox(width: 6),
                _buildVoltageChip("≤ 35kV", "<=35kV"),
                const SizedBox(width: 6),
                _buildVoltageChip("110kV", "110kV"),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStandardView(),
                _buildTT02View(),
                _buildCbmView(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVoltageChip(String label, String value) {
    final isSelected = _currentVoltage == value;
    return ChoiceChip(
      label: Text(label, style: const TextStyle(fontSize: 12)),
      selected: isSelected,
      selectedColor: AppTheme.myOrangeAccent,
      backgroundColor: AppTheme.myMedNavy,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.white70,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _currentVoltage = value;
          });
        }
      },
    );
  }

  bool _matchesVoltage(String level) {
    if (_currentVoltage == "ALL") return true;
    return level == _currentVoltage || level == "ALL";
  }

  Widget _buildStandardView() {
    final allItems = ReferenceStandardService.getAllStandards();
    final filtered = allItems
        .where((e) =>
            e.categoryCode == widget.categoryCode && _matchesVoltage(e.voltageLevel))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState("Chưa có Tiêu chuẩn Thử nghiệm cho thiết bị này.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.myMedNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: AppTheme.myOrangeAccent, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.subCategory,
                        style: const TextStyle(
                            color: AppTheme.myOrangeAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    _buildCompareToggleButton(0),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.item,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text("Quy định / Giới hạn:",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(item.limit,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 14, height: 1.3)),
                const SizedBox(height: 8),
                const Text("Tiêu chuẩn tham chiếu:",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(item.standard,
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 13)),
                const SizedBox(height: 8),
                const Text("Gợi ý xử lý khi không đạt:",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(item.recommendation,
                    style:
                        const TextStyle(color: Colors.cyanAccent, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTT02View() {
    final allItems = ReferenceStandardService.getAllTT02();
    final filtered = allItems
        .where((e) =>
            e.categoryCode == widget.categoryCode && _matchesVoltage(e.voltageLevel))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState(
          "Chưa có Tiêu chuẩn Kiểm định TT02 cho thiết bị này.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.myMedNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.blueAccent, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.subCategory,
                        style: const TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    _buildCompareToggleButton(1),
                  ],
                ),
                const SizedBox(height: 6),
                Text("Hạng mục: ${item.item}",
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                Text("Chu kỳ kiểm định quy định: ${item.period}",
                    style: const TextStyle(
                        color: Colors.yellowAccent, fontSize: 13)),
                const SizedBox(height: 8),
                const Text("Yêu cầu Ngưỡng Giá Trị 'ĐẠT' Chi Tiết:",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(item.limit,
                    style: const TextStyle(
                        color: Colors.greenAccent, fontSize: 13, height: 1.3)),
                const SizedBox(height: 8),
                const Text("Quy chuẩn / Tiêu chuẩn áp dụng:",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(item.standard,
                    style: const TextStyle(
                        color: Colors.orangeAccent, fontSize: 13)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCbmView() {
    final allItems = ReferenceStandardService.getAllCBM();
    final filtered = allItems
        .where((e) =>
            e.categoryCode == widget.categoryCode && _matchesVoltage(e.voltageLevel))
        .toList();

    if (filtered.isEmpty) {
      return _buildEmptyState("Chưa có Tiêu chuẩn CBM cho thiết bị này.");
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final item = filtered[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          color: AppTheme.myMedNavy,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.purpleAccent, width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(item.subCategory,
                        style: const TextStyle(
                            color: Colors.purpleAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    _buildCompareToggleButton(2),
                  ],
                ),
                const SizedBox(height: 6),
                Text(item.item,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),

                // THANH 4 MỨC ĐÁNH GIÁ CBM
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      _buildCbmLevelRow("🟢 Tốt (Mức 1):", item.good, Colors.greenAccent),
                      const Divider(color: Colors.white12, height: 8),
                      _buildCbmLevelRow("🟡 Khá (Mức 2):", item.fair, Colors.yellowAccent),
                      const Divider(color: Colors.white12, height: 8),
                      _buildCbmLevelRow("🟠 Trung bình (Mức 3):", item.average, Colors.orangeAccent),
                      const Divider(color: Colors.white12, height: 8),
                      _buildCbmLevelRow("🔴 Xấu (Mức 4):", item.poor, Colors.redAccent),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Text("Hành động xử lý khi Xấu / Không đạt:",
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
                Text(item.recommendation,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCompareToggleButton(int currentTab) {
    return PopupMenuButton<int>(
      tooltip: 'Chuyển đổi tiêu chuẩn so sánh',
      icon: const Icon(Icons.swap_horiz, color: Colors.white70),
      color: AppTheme.myDarkNavy,
      onSelected: (targetIndex) {
        _tabController.animateTo(targetIndex);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 0,
          enabled: currentTab != 0,
          child: const Row(
            children: [
              Icon(Icons.science, color: AppTheme.myOrangeAccent, size: 18),
              SizedBox(width: 8),
              Text("Xem Tiêu chuẩn Thử nghiệm",
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 1,
          enabled: currentTab != 1,
          child: const Row(
            children: [
              Icon(Icons.verified_user, color: Colors.blueAccent, size: 18),
              SizedBox(width: 8),
              Text("Xem Kiểm định TT02",
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
        PopupMenuItem(
          value: 2,
          enabled: currentTab != 2,
          child: const Row(
            children: [
              Icon(Icons.analytics, color: Colors.purpleAccent, size: 18),
              SizedBox(width: 8),
              Text("Xem Đánh giá CBM",
                  style: TextStyle(color: Colors.white, fontSize: 13)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCbmLevelRow(String title, String val, Color color) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(title,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        Expanded(
          child: Text(val,
              style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String msg) {
    return Center(
      child: Text(
        msg,
        style: const TextStyle(color: Colors.white54, fontSize: 15),
      ),
    );
  }
}
