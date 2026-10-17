import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/reference_standard_service.dart';

/// Widget Hiển thị khối Đối Chiếu 3 Tầng Tiêu Chuẩn:
/// 1. Tiêu chuẩn Quốc tế / TCVN (Thử nghiệm)
/// 2. Tiêu chuẩn Đánh giá CBM (4 mức)
/// 3. Tiêu chuẩn Kiểm định Thông tư 02/2025/TT-BCT
class StandardEvaluationWidget extends StatefulWidget {
  final String testCode;
  final String voltageLevel; // ">35kV", "<=35kV", "ALL"
  final double? primaryValue;
  final Map<String, double>? phaseValues; // Ví dụ: {"Pha A": 0.12, "Pha B": 0.15, "Pha C": 0.55}
  final String unit;
  final String? customTitle;

  const StandardEvaluationWidget({
    super.key,
    required this.testCode,
    this.voltageLevel = 'ALL',
    this.primaryValue,
    this.phaseValues,
    this.unit = '',
    this.customTitle,
  });

  @override
  State<StandardEvaluationWidget> createState() =>
      _StandardEvaluationWidgetState();
}

class _StandardEvaluationWidgetState extends State<StandardEvaluationWidget> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final effectiveValue = widget.primaryValue ??
        (widget.phaseValues != null && widget.phaseValues!.isNotEmpty
            ? widget.phaseValues!.values.reduce((a, b) => a > b ? a : b)
            : 0.0);

    // Tính toán đối chiếu 3 tiêu chuẩn
    final stdResult = ReferenceStandardService.evaluateStandard(
      widget.testCode,
      effectiveValue,
      voltageLevel: widget.voltageLevel,
    );

    final cbmResult = ReferenceStandardService.evaluateCbm(
      widget.testCode,
      effectiveValue,
      voltageLevel: widget.voltageLevel,
    );

    final tt02Result = ReferenceStandardService.evaluateTT02(
      widget.testCode,
      effectiveValue,
      voltageLevel: widget.voltageLevel,
    );

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: AppTheme.myMedNavy,
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: (stdResult.isPass && tt02Result.isPass && cbmResult.level <= 2)
              ? Colors.tealAccent.withValues(alpha: 0.5)
              : Colors.orangeAccent.withValues(alpha: 0.7),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER BAR
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Row(
                children: [
                  const Icon(Icons.fact_check,
                      color: AppTheme.myOrangeAccent, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.customTitle ?? "ĐỐI CHIẾU TIÊU CHUẨN ĐÁNH GIÁ",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          "Cấp điện áp: ${widget.voltageLevel == 'ALL' ? 'Tất cả' : widget.voltageLevel}",
                          style: const TextStyle(
                              color: Colors.white60, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.white70,
                  ),
                ],
              ),
            ),

            if (_isExpanded) ...[
              const Divider(color: Colors.white24, height: 16),

              // 1️⃣ TIÊU CHUẨN QUỐC TẾ / TCVN (THỬ NGHIỆM)
              _buildStandardCard(stdResult, effectiveValue),

              const SizedBox(height: 10),

              // 2️⃣ TIÊU CHUẨN ĐÁNH GIÁ CBM (4 MỨC)
              _buildCbmCard(cbmResult, effectiveValue),

              const SizedBox(height: 10),

              // 3️⃣ TIÊU CHUẨN KIỂM ĐỊNH THÔNG TƯ 02/2025/TT-BCT
              _buildTT02Card(tt02Result, effectiveValue),
            ],
          ],
        ),
      ),
    );
  }

  // 1️⃣ Thẻ Tiêu chuẩn Thử nghiệm (TCVN/IEC)
  Widget _buildStandardCard(StandardEvalResult res, double effectiveVal) {
    final bool isFailed = !res.isPass;
    final Color statusColor = res.statusText == "THAM CHIẾU"
        ? Colors.cyanAccent
        : (res.isPass ? Colors.greenAccent : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFailed ? Colors.redAccent.withValues(alpha: 0.6) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.science, color: AppTheme.myOrangeAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "1. TIÊU CHUẨN QUỐC TẾ / TCVN",
                    style: TextStyle(
                      color: AppTheme.myOrangeAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  res.statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text("• Ngưỡng quy định: ",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Text(
                  res.limitText,
                  style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          if (res.standardText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "• Căn cứ: ${res.standardText}",
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),

          // Hiển thị từng pha nếu có
          if (widget.phaseValues != null && widget.phaseValues!.isNotEmpty)
            _buildPhaseBreakdown(res.item?.compare, res.item?.value, res.item?.min, res.item?.max),

          // KHUYẾN NGHỊ XỬ LÝ (Hiện khi Không Đạt hoặc hiển thị rõ ràng)
          if (res.recommendation.isNotEmpty && (isFailed || res.statusText == "KHÔNG ĐẠT"))
            _buildRecommendationBox(
              title: "Khuyến nghị xử lý (TCVN/IEC):",
              content: res.recommendation,
              color: Colors.redAccent,
            ),
        ],
      ),
    );
  }

  // 2️⃣ Thẻ Tiêu chuẩn Đánh giá CBM (4 mức)
  Widget _buildCbmCard(CbmEvalResult res, double effectiveVal) {
    Color levelColor;
    switch (res.level) {
      case 1:
        levelColor = Colors.greenAccent;
        break;
      case 2:
        levelColor = Colors.yellowAccent;
        break;
      case 3:
        levelColor = Colors.orangeAccent;
        break;
      case 4:
      default:
        levelColor = Colors.redAccent;
        break;
    }

    final bool isBad = res.level >= 3;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isBad ? Colors.orangeAccent.withValues(alpha: 0.6) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.analytics, color: Colors.purpleAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "2. TIÊU CHUẨN ĐÁNH GIÁ CBM",
                    style: TextStyle(
                      color: Colors.purpleAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: levelColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: levelColor),
                ),
                child: Text(
                  res.levelName,
                  style: TextStyle(
                    color: levelColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (res.rangeText.isNotEmpty)
            Row(
              children: [
                const Text("• Dải phân loại CBM: ",
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Expanded(
                  child: Text(
                    res.rangeText,
                    style: TextStyle(
                        color: levelColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          if (res.item?.standard != null && res.item!.standard.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "• Quy trình: ${res.item!.standard}",
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),

          // KHUYẾN NGHỊ XỬ LÝ CBM KHI TRUNG BÌNH HOẶC XẤU
          if (res.recommendation.isNotEmpty && isBad)
            _buildRecommendationBox(
              title: "Khuyến nghị hành động CBM (${res.conclusion}):",
              content: res.recommendation,
              color: levelColor,
            ),
        ],
      ),
    );
  }

  // 3️⃣ Thẻ Tiêu chuẩn Kiểm định TT02
  Widget _buildTT02Card(TT02EvalResult res, double effectiveVal) {
    final bool isFailed = !res.isPass;
    final Color statusColor = res.statusText == "THAM CHIẾU KIỂM ĐỊNH"
        ? Colors.cyanAccent
        : (res.isPass ? Colors.lightBlueAccent : Colors.redAccent);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isFailed ? Colors.redAccent.withValues(alpha: 0.6) : Colors.white12,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_user, color: Colors.blueAccent, size: 16),
                  SizedBox(width: 6),
                  Text(
                    "3. TIÊU CHUẨN KIỂM ĐỊNH TT02",
                    style: TextStyle(
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  res.statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Text("• Ngưỡng ĐẠT kiểm định: ",
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              Expanded(
                child: Text(
                  res.limitText,
                  style: const TextStyle(
                      color: Colors.lightBlueAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
              ),
            ],
          ),
          if (res.periodText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "• Chu kỳ: ${res.periodText}",
                style: const TextStyle(color: Colors.yellowAccent, fontSize: 11),
              ),
            ),
          if (res.standardText.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                "• Căn cứ: ${res.standardText}",
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ),

          // KHUYẾN NGHỊ XỬ LÝ KIỂM ĐỊNH KHI KHÔNG ĐẠT
          if (res.recommendation.isNotEmpty && isFailed)
            _buildRecommendationBox(
              title: "Khuyến nghị kiểm định TT02:",
              content: res.recommendation,
              color: Colors.redAccent,
            ),
        ],
      ),
    );
  }

  // Khối Khuyến Nghị Xử Lý Nổi Bật
  Widget _buildRecommendationBox({
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  content,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Chi tiết từng pha A, B, C
  Widget _buildPhaseBreakdown(String? comp, dynamic threshold, dynamic mn, dynamic mx) {
    if (widget.phaseValues == null || widget.phaseValues!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 2),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: widget.phaseValues!.entries.map((entry) {
          final val = entry.value;
          final pass = ReferenceStandardService.compareValue(val, comp, threshold, mn, mx);
          final pColor = pass == null
              ? Colors.white70
              : (pass ? Colors.greenAccent : Colors.redAccent);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: pColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: pColor.withValues(alpha: 0.4)),
            ),
            child: Text(
              "${entry.key}: ${val.toStringAsFixed(2)}${widget.unit} (${pass == null ? 'N/A' : (pass ? 'Đạt' : 'Lỗi')})",
              style: TextStyle(color: pColor, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
      ),
    );
  }
}
