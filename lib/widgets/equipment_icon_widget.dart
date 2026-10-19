import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/theme/app_theme.dart';

/// Widget hiển thị biểu tượng các đối tượng thí nghiệm điện cao thế bằng định dạng vector SVG
/// với màu cam đồng bộ, độ tương phản cao trên nền dark navy của ứng dụng.
class EquipmentIconWidget extends StatelessWidget {
  final String? categoryCode;
  final String? testCode;
  final String? customAsset;
  final double size;
  final Color? color;
  final bool isIR;
  final IconData? fallbackIcon;

  const EquipmentIconWidget({
    super.key,
    this.categoryCode,
    this.testCode,
    this.customAsset,
    this.size = 32.0,
    this.color,
    this.isIR = false,
    this.fallbackIcon,
  });

  /// Factory riêng để hiển thị ký hiệu cách điện "IR" (Insulation Resistance)
  const EquipmentIconWidget.ir({
    super.key,
    this.size = 32.0,
    this.color,
  })  : categoryCode = 'insulation_ir',
        testCode = null,
        customAsset = null,
        isIR = true,
        fallbackIcon = Icons.speed;

  /// Ánh xạ từ mã thiết bị hoặc mã phép đo sang đường dẫn file SVG
  static String? getAssetForCode(String? code) {
    if (code == null) return null;
    final c = code.toLowerCase().trim();

    // Aptomat (MCB / MCCB) - kiểm tra trước máy cắt để tránh nhầm MCB với MC
    if (c == 'aptomat' || c.contains('aptomat') || c.contains('mcb') || c.contains('mccb')) {
      return 'assets/icons/high_voltage/aptomat.svg';
    }

    // Dao cách ly
    if (c == 'disconnector' || c.contains('dao cách ly') || c.startsWith('dcl') || c.contains('dao_cach_ly')) {
      return 'assets/icons/high_voltage/dao_cach_ly.svg';
    }

    // Recloser / LBS / RMU
    if (c == 'recloser' || c == 'recloser_lbs' || c.contains('recloser') || c.contains('lbs') || c.contains('rmu')) {
      return 'assets/icons/high_voltage/recloser_lbs.svg';
    }

    // Máy cắt
    if (c == 'circuit_breaker' || c.contains('máy cắt') || c == 'mc' || c.startsWith('mc_') || c.startsWith('mc-')) {
      return 'assets/icons/high_voltage/may_cat.svg';
    }

    // MBA
    if (c == 'transformer' || c.contains('biến áp') || c.contains('mba')) {
      return 'assets/icons/high_voltage/may_bien_ap.svg';
    }

    // Tiếp địa (ưu tiên kiểm tra trước TI/TU)
    if (c == 'grounding' || c.startsWith('td') || c.contains('tiếp địa') || c.contains('nối đất') || c.contains('tiep_dia')) {
      return 'assets/icons/high_voltage/tiep_dia.svg';
    }

    // TI / TU
    if (c == 'instrument_transformer' ||
        c.contains('titu') ||
        c.contains('tu_ti') ||
        c.contains('ti_tu') ||
        c.contains('ct_vt') ||
        c.contains('biến dòng') ||
        c.contains('biến điện áp') ||
        c == 'ti' ||
        c == 'tu' ||
        c.startsWith('ti_') ||
        c.startsWith('tu_') ||
        c.contains('ti & tu') ||
        c.contains('tu & ti')) {
      return 'assets/icons/high_voltage/TU_TI.svg';
    }

    // Chống sét van
    if (c == 'surge_arrester' || c.startsWith('la') || c.contains('chống sét') || c.contains('chong_set')) {
      return 'assets/icons/high_voltage/chong_set_van.svg';
    }

    // Cáp lực
    if (c == 'cable' || c.startsWith('cable') || c.contains('cáp lực') || c.contains('cáp ngầm') || c.contains('cap_ngam')) {
      return 'assets/icons/high_voltage/cap_ngam.svg';
    }

    // Máy điện quay
    if (c == 'rotating_machine' || c.startsWith('rot') || c.contains('máy điện quay') || c.contains('động cơ') || c.contains('máy phát')) {
      return 'assets/icons/high_voltage/may_dien_quay.svg';
    }

    // Chất lượng điện năng
    if (c == 'power_quality' || c.startsWith('pq') || c.contains('chất lượng điện') || c.contains('sóng hài')) {
      return 'assets/icons/high_voltage/chat_luong_dien_nang.svg';
    }

    // Tụ điện / Tụ bù
    if (c == 'capacitor' || c.startsWith('cap') || c.contains('tụ điện') || c.contains('tụ bù') || c.contains('tu_bu')) {
      return 'assets/icons/high_voltage/tu_bu_xoay_chieu.svg';
    }

    // Rơ le bảo vệ
    if (c == 'relay_protection' || c == 'digital_relay' || c.startsWith('relay') || c.contains('rơ le')) {
      return 'assets/icons/high_voltage/relay_bao_ve.svg';
    }

    // Dụng cụ an toàn
    if (c == 'safety_equipment' || c.contains('an toàn') || c.contains('găng tay') || c.contains('gang_tay')) {
      return 'assets/icons/high_voltage/gang_tay.svg';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? AppTheme.myOrangeAccent;

    // Kiểm tra xem có phải là cách điện IR không
    final c = categoryCode?.toLowerCase() ?? '';
    final isInsulation = isIR || c == 'insulation_ir' || c.contains('cách điện') || c.contains('dar') || c.contains('pi');

    // Trường hợp hiển thị ký hiệu cách điện "IR"
    if (isInsulation) {
      return Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: effectiveColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(size * 0.25),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.7),
            width: size > 32 ? 2.0 : 1.5,
          ),
        ),
        child: Text(
          'IR',
          style: TextStyle(
            color: effectiveColor,
            fontWeight: FontWeight.w900,
            fontSize: size * 0.46,
            letterSpacing: 0.5,
          ),
        ),
      );
    }

    // Xác định asset path
    final path = customAsset ?? getAssetForCode(categoryCode) ?? getAssetForCode(testCode);

    if (path != null) {
      return SvgPicture.asset(
        path,
        width: size,
        height: size,
        colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
      );
    }

    // Fallback nếu không có asset
    return Icon(
      fallbackIcon ?? Icons.electrical_services,
      size: size,
      color: effectiveColor,
    );
  }
}
