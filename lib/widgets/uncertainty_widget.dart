import 'package:flutter/material.dart';
import '../services/calibration_service.dart';
import '../core/theme/app_theme.dart';
import '../core/utils/app_formatters.dart';

/// Widget chọn phương tiện đo hiệu chuẩn và hiển thị kết quả ĐKĐBĐ (ISO 17025)
/// Hỗ trợ cả tính toán 2 bước (Đo lường sơ cấp & Chỉ số quy chuẩn đối chiếu)
/// Hỗ trợ phép đo 1 giá trị lẫn phép đo 3 pha (Pha A, B, C)
class UncertaintyEquipmentSection extends StatelessWidget {
  final String testId;
  final CalibratedEquipmentModel? selectedEquipment;
  final ValueChanged<CalibratedEquipmentModel?> onEquipmentChanged;

  /// Kết quả cho phép đo 1 giá trị (VD: TI/TU, Aptomat, v.v.)
  final UncertaintyResult? uncertaintyResult;

  /// Kết quả cho phép đo 3 pha / nhiều pha (VD: {'Pha A': resA, 'Pha B': resB, 'Pha C': resC})
  final Map<String, UncertaintyResult?>? phaseResults;

  final double? standardLimit;
  final bool isUpperBound; // true nếu chuẩn là <= limit
  final String? summaryTitle;
  final String? summaryValueText;
  final bool? summaryPass;

  const UncertaintyEquipmentSection({
    super.key,
    required this.testId,
    required this.selectedEquipment,
    required this.onEquipmentChanged,
    this.uncertaintyResult,
    this.phaseResults,
    this.standardLimit,
    this.isUpperBound = true,
    this.summaryTitle,
    this.summaryValueText,
    this.summaryPass,
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

    // Luôn tìm chính xác thiết bị đang chọn theo ID để tránh lỗi so sánh tham chiếu
    final currentEq = availableEquipments.firstWhere(
      (e) => e.id == selectedEquipment?.id,
      orElse: () => availableEquipments.first,
    );

    final bool hasMultiPhase = phaseResults != null &&
        phaseResults!.values.any((res) => res != null);
    final bool hasSingleResult = uncertaintyResult != null;

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
          // HEADER: TIÊU ĐỀ & THÔNG SỐ HIỆU CHUẨN
          Row(
            children: [
              const Icon(Icons.verified, color: Colors.tealAccent, size: 22),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  "HIỆU CHUẨN & ĐKĐBĐ (ISO 17025)",
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                      color: Colors.tealAccent.withValues(alpha: 0.5)),
                ),
                child: const Text(
                  "P = 95% (k=2)",
                  style: TextStyle(
                    color: Colors.tealAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 10),

          // DROPDOWN CHỌN THIẾT BỊ HIỆU CHUẨN
          const Text(
            "Phương tiện đo sử dụng:",
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
            decoration: BoxDecoration(
              color: AppTheme.myDarkNavy,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.tealAccent.withValues(alpha: 0.4),
                width: 1.2,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<CalibratedEquipmentModel>(
                value: currentEq,
                isExpanded: true,
                dropdownColor: AppTheme.myDarkNavy,
                icon: const Icon(Icons.arrow_drop_down,
                    color: Colors.amberAccent, size: 28),
                selectedItemBuilder: (BuildContext context) {
                  return availableEquipments.map((eq) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${eq.type} (SN: ${eq.serial}) - ${eq.name}",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.amberAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: availableEquipments.map((eq) {
                  bool isSelected = eq.id == currentEq.id;
                  return DropdownMenuItem<CalibratedEquipmentModel>(
                    value: eq,
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? Colors.tealAccent
                              : Colors.white30,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "${eq.type} (SN: ${eq.serial}) - ${eq.name}",
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color:
                                  isSelected ? Colors.amberAccent : Colors.white,
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
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
          if (hasMultiPhase || hasSingleResult) ...[
            const SizedBox(height: 12),
            const Divider(color: Colors.white12, height: 1),
            const SizedBox(height: 10),
            if (hasMultiPhase)
              _buildMultiPhaseDetails(phaseResults!)
            else if (hasSingleResult)
              _buildSingleResultDetails(uncertaintyResult!),
          ]
        ],
      ),
    );
  }

  /// Hiển thị kết quả ĐKĐBĐ cho phép thử 3 pha (A, B, C)
  Widget _buildMultiPhaseDetails(Map<String, UncertaintyResult?> phases) {
    double? uPct;
    for (var res in phases.values) {
      if (res != null) {
        uPct = res.uPercent;
        break;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "KẾT QUẢ HIỆU CHUẨN 3 PHA:",
              style: TextStyle(
                color: Colors.tealAccent,
                fontSize: 13,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            if (uPct != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.cyan.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(
                      color: Colors.cyanAccent.withValues(alpha: 0.5)),
                ),
                child: Text(
                  "u% = ${uPct.toStringAsFixed(2)}%",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        ...phases.entries
            .where((entry) => entry.value != null)
            .map((entry) => _buildPhaseCard(entry.key, entry.value!)),

        // TỔNG HỢP NẾU CÓ (VD: Độ lệch pha sau hiệu chính)
        if (summaryTitle != null && summaryValueText != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: (summaryPass == true)
                  ? Colors.green.withValues(alpha: 0.15)
                  : (summaryPass == false)
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.black26,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (summaryPass == true)
                    ? Colors.greenAccent.withValues(alpha: 0.6)
                    : (summaryPass == false)
                        ? Colors.redAccent.withValues(alpha: 0.6)
                        : Colors.white24,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  summaryTitle!,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  summaryValueText!,
                  style: TextStyle(
                    color: (summaryPass == true)
                        ? Colors.greenAccent
                        : (summaryPass == false)
                            ? Colors.redAccent
                            : Colors.amberAccent,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          )
        ]
      ],
    );
  }

  /// Card kết quả cho từng pha (Pha A, B, C)
  Widget _buildPhaseCard(String phaseName, UncertaintyResult res) {
    Color phaseColor;
    if (phaseName.toUpperCase().contains('A')) {
      phaseColor = Colors.orangeAccent;
    } else if (phaseName.toUpperCase().contains('B')) {
      phaseColor = Colors.cyanAccent;
    } else if (phaseName.toUpperCase().contains('C')) {
      phaseColor = Colors.purpleAccent.shade100;
    } else {
      phaseColor = Colors.tealAccent;
    }

    String corrSign = res.correction >= 0 ? "+" : "";
    String corrValStr = AppFormatters.formatSmart(res.correction, testId: testId, unit: res.unit);
    String corrStr = "C: $corrSign$corrValStr ${res.unit}";

    final effectiveLimit = res.standardLimit ?? standardLimit;
    final effectiveIsUpper =
        res.standardLimit != null ? res.isUpperBound : isUpperBound;
    UncertaintyVerdict? verdict;
    if (effectiveLimit != null) {
      verdict = res.evaluateStandard(effectiveLimit);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.myDarkNavy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: phaseColor.withValues(alpha: 0.4), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Dòng tiêu đề pha + số hiệu chính C
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: phaseColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  phaseName.toUpperCase(),
                  style: TextStyle(
                    color: phaseColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    corrStr,
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // TẦNG 1: GIÁ TRỊ ĐO HIỆU CHUẨN
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "X_hc: ",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    Flexible(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          "${AppFormatters.formatSmart(res.correctedValue, testId: testId, unit: res.unit)} ${res.unit}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    "±U: ±${AppFormatters.formatSmart(res.expandedUncertainty, testId: testId, unit: res.unit)} ${res.unit}",
                    style: const TextStyle(
                      color: Colors.cyanAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Dòng Dải thực đo [X-U ÷ X+U]
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.black26,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Dải thực [X±U]:",
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      "[ ${AppFormatters.formatSmart(res.minBound, testId: testId, unit: res.unit)} ÷ ${AppFormatters.formatSmart(res.maxBound, testId: testId, unit: res.unit)} ] ${res.unit}",
                      style: const TextStyle(
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TẦNG 2: CHỈ SỐ QUY CHUẨN DẪN XUẤT (NẾU CÓ)
          if (res.derivedName != null && res.derivedCorrected != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.myMedNavy,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: (verdict == UncertaintyVerdict.fail)
                      ? Colors.redAccent.withValues(alpha: 0.6)
                      : (verdict == UncertaintyVerdict.warningRisk)
                          ? Colors.amberAccent.withValues(alpha: 0.6)
                          : Colors.tealAccent.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Text(
                          "${res.derivedName}:",
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        "${(res.derivedUnit == '%' && res.derivedCorrected! > 0) ? '+' : ''}${AppFormatters.formatSmart(res.derivedCorrected, unit: res.derivedUnit, defaultDecimals: 2)} ${res.derivedUnit ?? ''}",
                        style: TextStyle(
                          color: (verdict == UncertaintyVerdict.fail)
                              ? Colors.redAccent
                              : (verdict == UncertaintyVerdict.warningRisk)
                                  ? Colors.amberAccent
                                  : Colors.yellowAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  if (res.derivedMinBound != null &&
                      res.derivedMaxBound != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Dải chuẩn [X±U]:",
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              "[ ${(res.derivedUnit == '%' && res.derivedMinBound! > 0) ? '+' : ''}${AppFormatters.formatSmart(res.derivedMinBound, unit: res.derivedUnit, defaultDecimals: 2)} ÷ ${(res.derivedUnit == '%' && res.derivedMaxBound! > 0) ? '+' : ''}${AppFormatters.formatSmart(res.derivedMaxBound, unit: res.derivedUnit, defaultDecimals: 2)} ] ${res.derivedUnit ?? ''}",
                              style: const TextStyle(
                                color: Colors.lightGreenAccent,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],

          // ĐÁNH GIÁ TIÊU CHUẨN NẾU CÓ LIMIT
          if (verdict != null && effectiveLimit != null) ...[
            const SizedBox(height: 6),
            _buildMiniVerdict(verdict, res, effectiveLimit, effectiveIsUpper),
          ]
        ],
      ),
    );
  }

  /// Đánh giá kết quả dạng mini cho từng pha
  Widget _buildMiniVerdict(
    UncertaintyVerdict verdict,
    UncertaintyResult res,
    double limit,
    bool isUpper,
  ) {
    Color color;
    IconData icon;
    String text;
    String targetUnit = res.derivedUnit ?? res.unit;
    String targetName = res.derivedName ?? '';
    bool isBilateral = targetUnit == '%' &&
        (targetName.toLowerCase().contains('sai số') ||
            targetName.toLowerCase().contains('f'));

    String limitText = isBilateral
        ? "±$limit%"
        : "${isUpper ? '≤' : '≥'} $limit $targetUnit";

    switch (verdict) {
      case UncertaintyVerdict.pass:
        color = Colors.greenAccent;
        icon = Icons.check_circle;
        text = "ĐẠT (Toàn dải nằm trong $limitText)";
        break;
      case UncertaintyVerdict.warningRisk:
        color = Colors.amberAccent;
        icon = Icons.warning_amber;
        text = "CẢNH BÁO: Rủi ro biên (Dải chạm/vượt ngưỡng $limitText)";
        break;
      case UncertaintyVerdict.fail:
        color = Colors.redAccent;
        icon = Icons.cancel;
        text = "KHÔNG ĐẠT (Vượt giới hạn $limitText)";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Hiển thị kết quả ĐKĐBĐ cho phép thử 1 giá trị đơn lẻ
  Widget _buildSingleResultDetails(UncertaintyResult res) {
    String corrSign = res.correction >= 0 ? "+" : "";
    String corrValStr = AppFormatters.formatSmart(res.correction, testId: testId, unit: res.unit);
    String corrStr = "$corrSign$corrValStr ${res.unit}";

    final effectiveLimit = res.standardLimit ?? standardLimit;
    final effectiveIsUpper =
        res.standardLimit != null ? res.isUpperBound : isUpperBound;
    UncertaintyVerdict? verdict;
    if (effectiveLimit != null) {
      verdict = res.evaluateStandard(effectiveLimit);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Hiệu chính C:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  corrStr,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Giá trị X_hc:",
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  "${AppFormatters.formatSmart(res.correctedValue, testId: testId, unit: res.unit)} ${res.unit}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                "ĐKĐBĐ ±U (u%=${res.uPercent.toStringAsFixed(2)}%):",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  "±${AppFormatters.formatSmart(res.expandedUncertainty, testId: testId, unit: res.unit)} ${res.unit}",
                  style: const TextStyle(
                    color: Colors.cyanAccent,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black38,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Dải thực [X±U]:",
                style: TextStyle(color: Colors.white60, fontSize: 13),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(
                    "[ ${AppFormatters.formatSmart(res.minBound, testId: testId, unit: res.unit)} ÷ ${AppFormatters.formatSmart(res.maxBound, testId: testId, unit: res.unit)} ] ${res.unit}",
                    style: const TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // TẦNG 2: KẾT QUẢ DẪN XUẤT QUY CHUẨN (NẾU CÓ)
        if (res.derivedName != null && res.derivedCorrected != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.myDarkNavy,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: (verdict == UncertaintyVerdict.fail)
                    ? Colors.redAccent.withValues(alpha: 0.6)
                    : (verdict == UncertaintyVerdict.warningRisk)
                        ? Colors.amberAccent.withValues(alpha: 0.6)
                        : Colors.tealAccent.withValues(alpha: 0.5),
                width: 1.2,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        "${res.derivedName}:",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      "${(res.derivedUnit == '%' && res.derivedCorrected! > 0) ? '+' : ''}${AppFormatters.formatSmart(res.derivedCorrected, unit: res.derivedUnit, defaultDecimals: 2)} ${res.derivedUnit ?? ''}",
                      style: TextStyle(
                        color: (verdict == UncertaintyVerdict.fail)
                            ? Colors.redAccent
                            : (verdict == UncertaintyVerdict.warningRisk)
                                ? Colors.amberAccent
                                : Colors.yellowAccent,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                if (res.derivedMinBound != null &&
                    res.derivedMaxBound != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Dải chuẩn [X±U]:",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            "[ ${(res.derivedUnit == '%' && res.derivedMinBound! > 0) ? '+' : ''}${AppFormatters.formatSmart(res.derivedMinBound, unit: res.derivedUnit, defaultDecimals: 2)} ÷ ${(res.derivedUnit == '%' && res.derivedMaxBound! > 0) ? '+' : ''}${AppFormatters.formatSmart(res.derivedMaxBound, unit: res.derivedUnit, defaultDecimals: 2)} ] ${res.derivedUnit ?? ''}",
                            style: const TextStyle(
                              color: Colors.lightGreenAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],

        // ĐÁNH GIÁ SỰ PHÙ HỢP ILAC-G8
        if (verdict != null && effectiveLimit != null) ...[
          const SizedBox(height: 10),
          _buildVerdictBadge(verdict, res, effectiveLimit, effectiveIsUpper),
        ]
      ],
    );
  }

  /// Badge đánh giá kết luận ILAC-G8 đầy đủ cho phép đo đơn lẻ
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
    String targetUnit = res.derivedUnit ?? res.unit;
    String targetName = res.derivedName ?? '';
    bool isBilateral = targetUnit == '%' &&
        (targetName.toLowerCase().contains('sai số') ||
            targetName.toLowerCase().contains('f'));

    String limitText = isBilateral
        ? "±$limit%"
        : "$boundSymbol $limit $targetUnit";

    String valRangeText = (res.derivedMinBound != null &&
            res.derivedMaxBound != null)
        ? "[${(res.derivedMinBound! > 0 && targetUnit == '%') ? '+' : ''}${res.derivedMinBound!.toStringAsFixed(3)} ÷ ${(res.derivedMaxBound! > 0 && targetUnit == '%') ? '+' : ''}${res.derivedMaxBound!.toStringAsFixed(3)}] $targetUnit"
        : "[${res.minBound.toStringAsFixed(3)} ÷ ${res.maxBound.toStringAsFixed(3)}] $targetUnit";

    switch (verdict) {
      case UncertaintyVerdict.pass:
        badgeColor = Colors.greenAccent;
        icon = Icons.check_circle;
        title = "ĐẠT (Độ tin cậy cao ≥ 95%)";
        desc = "Toàn bộ khoảng $valRangeText nằm trong giới hạn $limitText.";
        break;
      case UncertaintyVerdict.warningRisk:
        badgeColor = Colors.amberAccent;
        icon = Icons.warning_amber;
        title = "CẢNH BÁO: RỦI RO BIÊN (Vùng nghi ngờ)";
        desc =
            "Giá trị đo đạt nhưng khoảng ĐKĐBĐ $valRangeText chạm/vượt ngưỡng tiêu chuẩn $limitText. Khuyến cáo kiểm tra lại.";
        break;
      case UncertaintyVerdict.fail:
        badgeColor = Colors.redAccent;
        icon = Icons.cancel;
        title = "KHÔNG ĐẠT (Vượt ngưỡng quy định)";
        desc =
            "Kết quả $valRangeText vượt quá giới hạn tiêu chuẩn cho phép ($limitText).";
        break;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: badgeColor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: badgeColor.withValues(alpha: 0.8), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: badgeColor, size: 24),
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
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  desc,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}
