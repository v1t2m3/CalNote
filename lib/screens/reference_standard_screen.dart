import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/reference_standard_service.dart';
import '../widgets/equipment_icon_widget.dart';

class ReferenceStandardScreen extends StatefulWidget {
  const ReferenceStandardScreen({super.key});

  static bool matchCategory(dynamic e, String catCode) =>
      _ReferenceStandardScreenState.matchCategory(e, catCode);

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
      'svg': 'assets/icons/high_voltage/may_bien_ap.svg',
      'icon': Icons.electrical_services,
    },
    {
      'code': 'circuit_breaker',
      'name': 'Máy Cắt & Tủ Đóng Cắt',
      'svg': 'assets/icons/high_voltage/may_cat.svg',
      'icon': Icons.power_settings_new,
    },
    {
      'code': 'disconnector',
      'name': 'Dao Cách Ly & Cầu Chì',
      'svg': 'assets/icons/high_voltage/dao_cach_ly.svg',
      'icon': Icons.power_off,
    },
    {
      'code': 'recloser_lbs',
      'name': 'Recloser, LBS, RMU',
      'svg': 'assets/icons/high_voltage/recloser_lbs.svg',
      'icon': Icons.tune,
    },
    {
      'code': 'surge_arrester',
      'name': 'Chống Sét Van',
      'svg': 'assets/icons/high_voltage/chong_set_van.svg',
      'icon': Icons.flash_on,
    },
    {
      'code': 'instrument_transformer',
      'name': 'Biến Dòng & Biến Áp (TI/TU)',
      'svg': 'assets/icons/high_voltage/TU_TI.svg',
      'icon': Icons.donut_large,
    },
    {
      'code': 'cable',
      'name': 'Cáp Điện Lực & Cáp Ngầm',
      'svg': 'assets/icons/high_voltage/cap_ngam.svg',
      'icon': Icons.cable,
    },
    {
      'code': 'grounding',
      'name': 'Hệ Thống Nối Đất',
      'svg': 'assets/icons/high_voltage/tiep_dia.svg',
      'icon': Icons.format_line_spacing,
    },
    {
      'code': 'rotating_machine',
      'name': 'Máy Điện Quay',
      'svg': 'assets/icons/high_voltage/may_dien_quay.svg',
      'icon': Icons.rotate_right,
    },
    {
      'code': 'power_quality',
      'name': 'Chất Lượng Điện Năng',
      'svg': 'assets/icons/high_voltage/chat_luong_dien_nang.svg',
      'icon': Icons.waves,
    },
    {
      'code': 'capacitor',
      'name': 'Tụ Điện / Tụ Bù',
      'svg': 'assets/icons/high_voltage/tu_bu_xoay_chieu.svg',
      'icon': Icons.pause,
    },
    {
      'code': 'relay_protection',
      'name': 'Rơ Le Bảo Vệ',
      'svg': 'assets/icons/high_voltage/relay_bao_ve.svg',
      'icon': Icons.shield,
    },
    {
      'code': 'safety_equipment',
      'name': 'Dụng Cụ An Toàn Cao Áp',
      'svg': 'assets/icons/high_voltage/gang_tay.svg',
      'icon': Icons.pan_tool,
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

  static bool matchCategory(dynamic e, String catCode) {
    final code = e.categoryCode?.toString() ?? '';
    final cat = e.category?.toString().toLowerCase() ?? '';
    final sub = (e is ReferenceItemModel
            ? e.subCategory
            : (e is TT02ItemModel
                ? e.subCategory
                : (e is CbmItemModel ? e.subCategory : '')))
        .toLowerCase();
    final item = (e is ReferenceItemModel
            ? e.item
            : (e is TT02ItemModel
                ? e.item
                : (e is CbmItemModel ? e.item : '')))
        .toLowerCase();

    if (catCode == 'recloser_lbs') {
      return code == 'recloser_lbs' ||
          cat.contains('recloser') ||
          sub.contains('recloser') ||
          item.contains('recloser') ||
          sub.contains('lbs') ||
          sub.contains('rmu');
    }
    if (catCode == 'circuit_breaker') {
      return code == 'circuit_breaker' &&
          !cat.contains('recloser') &&
          !sub.contains('recloser') &&
          !item.contains('recloser') &&
          !sub.contains('lbs') &&
          !sub.contains('rmu');
    }
    if (catCode == 'safety_equipment') {
      if (code == 'safety_equipment') return true;
      final isSafetyKw = sub.contains('an toàn') ||
          sub.contains('găng') ||
          sub.contains('ủng') ||
          sub.contains('sào') ||
          sub.contains('bút thử') ||
          sub.contains('thảm') ||
          item.contains('an toàn') ||
          item.contains('găng') ||
          item.contains('ủng') ||
          item.contains('sào') ||
          item.contains('bút thử');
      if (code == 'relay_safety' || cat.contains('dụng cụ an toàn')) {
        return isSafetyKw || (cat == 'dụng cụ an toàn');
      }
      return false;
    }
    if (catCode == 'relay_protection') {
      if (code == 'relay_protection') return true;
      final isSafetyKw = sub.contains('an toàn') ||
          sub.contains('găng') ||
          sub.contains('ủng') ||
          sub.contains('sào') ||
          sub.contains('bút thử') ||
          sub.contains('thảm') ||
          item.contains('an toàn') ||
          item.contains('găng') ||
          item.contains('ủng') ||
          item.contains('sào') ||
          item.contains('bút thử');
      if (code == 'relay_safety') {
        return !isSafetyKw;
      }
      return cat.contains('rơ le') && !cat.contains('an toàn');
    }
    return code == catCode;
  }

  int _getItemCountForCategory(String catCode, int tabIndex) {
    if (tabIndex == 0) {
      return _standardsList
          .where((e) =>
              matchCategory(e, catCode) &&
              ReferenceStandardService.matchVoltage(e.voltageLevel, _selectedVoltage))
          .length;
    } else if (tabIndex == 1) {
      return _tt02List
          .where((e) =>
              matchCategory(e, catCode) &&
              ReferenceStandardService.matchVoltage(e.voltageLevel, _selectedVoltage))
          .length;
    } else {
      return _cbmList
          .where((e) =>
              matchCategory(e, catCode) &&
              ReferenceStandardService.matchVoltage(e.voltageLevel, _selectedVoltage))
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
                  style: const TextStyle(color: Colors.white),
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
                    _buildVoltageChip("> 35kV (Cao thế)", ">35kV"),
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
                            ? AppTheme.myOrangeAccent.withValues(alpha: 0.5)
                            : Colors.white10,
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          EquipmentIconWidget(
                            categoryCode: dev['code'],
                            customAsset: dev['svg'],
                            fallbackIcon: dev['icon'],
                            size: 42,
                            color: AppTheme.myOrangeAccent,
                          ),
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
      return ReferenceStandardService.matchVoltage(level, _selectedVoltage);
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
                const Chip(
                  label: Text("Thông tư 02/2025/TT-BCT",
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
            Text(item.displayItem,
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
        title: Row(
          children: [
            EquipmentIconWidget(
              categoryCode: widget.categoryCode,
              size: 26,
              color: AppTheme.myOrangeAccent,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.categoryName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
                _buildVoltageChip("> 35kV", ">35kV"),
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
    return ReferenceStandardService.matchVoltage(level, _currentVoltage);
  }

  Widget _buildStandardView() {
    final allItems = ReferenceStandardService.getAllStandards();
    final filtered = allItems
        .where((e) =>
            ReferenceStandardScreen.matchCategory(e, widget.categoryCode) &&
            _matchesVoltage(e.voltageLevel))
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
            ReferenceStandardScreen.matchCategory(e, widget.categoryCode) &&
            _matchesVoltage(e.voltageLevel))
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
            ReferenceStandardScreen.matchCategory(e, widget.categoryCode) &&
            _matchesVoltage(e.voltageLevel))
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
                Text(item.displayItem,
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
