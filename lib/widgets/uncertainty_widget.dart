import 'package:flutter/material.dart';
import '../services/calibration_service.dart';
import '../core/theme/app_theme.dart';

/// Widget chọn phương tiện đo hiệu chuẩn và hiển thị kết quả ĐKĐBĐ
class UncertaintyEquipmentSection extends StatelessWidget {
  final String testId;
  final CalibratedEquipmentModel? selectedEquipment;
  final ValueChanged<CalibratedEquipmentModel?> onEquipmentChanged;
  final UncertaintyResult? uncertaintyResult;
  final double? standardLimit;
  final bool isUpperBound; // true nếu chuẩn là <= limit

  const UncertaintyEquipmentSection({
    super.key,
    required this.testId,
    required this.selectedEquipment,
    required this.onEquipmentChanged,
    this.uncertaintyResult,
    this.standardLimit,
    this.isUpperBound = true,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Chỉ hiển thị khi tính năng ĐKĐBĐ được BẬT
    if (!CalibrationService.isUncertaintyEnabled) {
      return const SizedBox.shrink();
    }

    // 2. Chỉ hiển thị khi có thiết bị hiệu chuẩn trong danh mục cho phép đo này
    final availableEquipments = CalibrationService.getEquipmentsForTest(testId);
    if (availableEquipments.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentEq = selectedEquipment ?? availableEquipments.first;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.myMedNavy,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.tealAccent.withValues(alpha: 0.6),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.tealAccent, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "HIỆU CHUẨN & ĐỘ KHÔNG ĐẢM BẢO ĐO (ISO 17025)",
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  "P = 95% (k=2)",
                  style: TextStyle(color: Colors.tealAccent, fontSize: 10),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),

          // DROPDOWN CHỌN THIẾT BỊ HIỆU CHUẨN
          const Text(
            "Phương tiện đo sử dụng:",
            style: TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppTheme.myDarkNavy,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white24),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CalibratedEquipmentModel>(
                value: currentEq,
                isExpanded: true,
                dropdownColor: AppTheme.myDarkNavy,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                items: availableEquipments.map((eq) {
                  return DropdownMenuItem<CalibratedEquipmentModel>(
                    value: eq,
                    child: Text(
                      "${eq.name} - ${eq.type} (SN: ${eq.serial})",
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }).toList(),
                onChanged: (newEq) {
                  if (newEq != null) {
                    onEquipmentChanged(newEq);
                  }
                },
              ),
            ),
          ),

          // HIỂN THỊ KẾT QUẢ ĐKĐBĐ SAU KHI TÍNH TOÁN
          if (uncertaintyResult != null) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            _buildResultDetails(uncertaintyResult!),
          ]
        ],
      ),
    );
  }

  Widget _buildResultDetails(UncertaintyResult res) {
    String corrSign = res.correction >= 0 ? "+" : "";
    String corrStr = "$corrSign${res.correction.toStringAsFixed(4)} ${res.unit}";

    UncertaintyVerdict? verdict;
    if (standardLimit != null) {
      verdict = res.evaluate(standardLimit!, isUpperBound: isUpperBound);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Số hiệu chính (C):",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              corrStr,
              style: const TextStyle(
                  color: Colors.amberAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Giá trị sau hiệu chính (X_hc):",
              style: TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              "${res.correctedValue.toStringAsFixed(4)} ${res.unit}",
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "ĐKĐBĐ mở rộng (±U, u%=${res.uPercent}%):",
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              "±${res.expandedUncertainty.toStringAsFixed(4)} ${res.unit}",
              style: const TextStyle(
                  color: Colors.cyanAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Khoảng giá trị thực [X-U; X+U]:",
                style: TextStyle(color: Colors.white60, fontSize: 11),
              ),
              Text(
                "[ ${res.minBound.toStringAsFixed(4)}  ÷  ${res.maxBound.toStringAsFixed(4)} ] ${res.unit}",
                style: const TextStyle(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ],
          ),
        ),

        // ĐÁNH GIÁ SỰ PHÙ HỢP NẾU CÓ TIÊU CHUẨN
        if (verdict != null && standardLimit != null) ...[
          const SizedBox(height: 8),
          _buildVerdictBadge(verdict, res, standardLimit!, isUpperBound),
        ]
      ],
    );
  }

  Widget _buildVerdictBadge(
    UncertaintyVerdict verdict,
    UncertaintyResult res,
    double limit,
    bool isUpper,
  ) {
    Color badgeColor;
    IconData icon;
    String title;
    String desc;

    String boundSymbol = isUpper ? "≤" : "≥";

    switch (verdict) {
      case UncertaintyVerdict.pass:
        badgeColor = Colors.greenAccent;
        icon = Icons.check_circle;
        title = "ĐẠT (Độ tin cậy cao ≥ 95%)";
        desc =
            "Toàn bộ khoảng [${res.minBound.toStringAsFixed(3)} ÷ ${res.maxBound.toStringAsFixed(3)}] nằm trong giới hạn $boundSymbol $limit ${res.unit}.";
        break;
      case UncertaintyVerdict.warningRisk:
        badgeColor = Colors.amberAccent;
        icon = Icons.warning_amber;
        title = "CẢNH BÁO: RỦI RO BIÊN (Vùng nghi ngờ)";
        desc =
            "Giá trị đo đạt nhưng khoảng ĐKĐBĐ chạm/vượt ngưỡng tiêu chuẩn $limit ${res.unit}. Khuyến cáo kiểm tra lại.";
        break;
      case UncertaintyVerdict.fail:
        badgeColor = Colors.redAccent;
        icon = Icons.cancel;
        title = "KHÔNG ĐẠT (Vượt ngưỡng quy định)";
        desc =
            "Kết quả vượt quá giới hạn tiêu chuẩn cho phép ($boundSymbol $limit ${res.unit}).";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: badgeColor, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
