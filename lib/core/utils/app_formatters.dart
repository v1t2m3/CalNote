/// Tiện ích chuẩn hóa chuyển đổi dữ liệu nhập và định dạng số chữ số thập phân
/// theo tiêu chuẩn kỹ thuật điện Quốc tế (IEC, IEEE) & Việt Nam (TCVN, EVN).
class AppFormatters {
  /// Chuyển chuỗi nhập liệu thành số thực double, tự động hỗ trợ cả dấu chấm '.' và phẩy ','
  static double parseInput(String? text) {
    if (text == null || text.trim().isEmpty) return 0.0;
    final clean = text.replaceAll(',', '.').trim();
    return double.tryParse(clean) ?? 0.0;
  }

  /// Điện trở một chiều cuộn dây (MBA, Động cơ, TI/TU): Chuẩn 3 chữ số thập phân
  static String formatRdc(double? val, {String unit = 'Ω'}) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(3)} $unit';
  }

  /// Điện trở tiếp đất / nối đất: Chuẩn 2 chữ số thập phân (theo TCVN 9358 & IEEE 81)
  static String formatGrounding(double? val, {String unit = 'Ω'}) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(2)} $unit';
  }

  /// Tỷ số biến đổi điện áp / dòng điện thực đo (K): Chuẩn 4 chữ số thập phân
  static String formatRatio(double? val) {
    if (val == null) return '-';
    return val.toStringAsFixed(4);
  }

  /// Phần trăm sai lệch / Độ lệch pha giữa các cuộn dây (%): Chuẩn 2 chữ số thập phân
  static String formatPercent(double? val, {bool showSign = false, int decimals = 2}) {
    if (val == null) return '-';
    final sign = (showSign && val > 0) ? '+' : '';
    return '$sign${val.toStringAsFixed(decimals)} %';
  }

  /// Điện trở tiếp xúc máy cắt / dao cách ly (μΩ): Chuẩn 1 chữ số thập phân
  static String formatRtx(double? val) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(1)} μΩ';
  }

  /// Thời gian thao tác máy cắt / rơ le (ms): Chuẩn 1 chữ số thập phân
  static String formatTimeMs(double? val, {int decimals = 1}) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(decimals)} ms';
  }

  /// Thời gian thao tác rơ le / Aptomat (s): Chuẩn 3 chữ số thập phân (nếu < 10s) hoặc 1 số (nếu >= 10s)
  static String formatTimeSec(double? val) {
    if (val == null) return '-';
    if (val.abs() >= 10.0) {
      return '${val.toStringAsFixed(1)} s';
    }
    return '${val.toStringAsFixed(3)} s';
  }

  /// Hệ số hấp thụ DAR và hệ số phân cực PI: Chuẩn 2 chữ số thập phân (theo IEEE 43)
  static String formatDarPi(double? val) {
    if (val == null) return '-';
    return val.toStringAsFixed(2);
  }

  /// Điện trở cách điện Rcđ: 0 chữ số thập phân nếu >= 100 MΩ, 1 chữ số nếu < 100 MΩ
  static String formatInsulation(double? val, {String unit = 'MΩ'}) {
    if (val == null) return '-';
    if (val.abs() >= 100.0) {
      return '${val.toStringAsFixed(0)} $unit';
    }
    return '${val.toStringAsFixed(1)} $unit';
  }

  /// Dòng điện mA (Chống sét van): Chuẩn 3 chữ số thập phân
  static String formatCurrentMa(double? val) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(3)} mA';
  }

  /// Dòng điện μA (Dòng rò Ir, cáp lực): Chuẩn 1 chữ số thập phân
  static String formatCurrentUa(double? val) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(1)} μA';
  }

  /// Dòng điện Ampe A (Rơ le): Chuẩn 3 chữ số thập phân
  static String formatCurrentAmp(double? val) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(3)} A';
  }

  /// Điện áp kV (LA U1mA, Uref): Chuẩn 2 chữ số thập phân
  static String formatVoltageKv(double? val) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(2)} kV';
  }

  /// Công suất tổn thất P0, Pk (kW): Chuẩn 1 chữ số thập phân
  static String formatPowerKw(double? val) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(1)} kW';
  }

  /// Hệ số tổn hao điện môi tan(delta) (%): Chuẩn 3 chữ số thập phân
  static String formatTanDelta(double? val) {
    if (val == null) return '-';
    return '${val.toStringAsFixed(3)} %';
  }

  /// Định dạng số chữ số thập phân thông minh theo mã phép thử hoặc đơn vị đo
  static String formatSmart(double? val, {String? testId, String? unit, int defaultDecimals = 3}) {
    if (val == null) return '-';
    final u = (unit ?? '').trim().toLowerCase();
    final tid = (testId ?? '').toUpperCase();

    // Theo mã phép thử
    if (tid.contains('R_DC') || tid.contains('RDC')) {
      return val.toStringAsFixed(3);
    }
    if (tid.contains('RATIO') || tid.contains('TITU_RATIO') || tid.contains('MBA_K')) {
      if (u == '%') return val.toStringAsFixed(2);
      return val.toStringAsFixed(4);
    }
    if (tid.contains('R_TX') || tid.contains('RTX')) {
      return val.toStringAsFixed(1);
    }
    if (tid.contains('TD_') || tid.contains('GROUND')) {
      return val.toStringAsFixed(2);
    }

    // Theo đơn vị
    if (u == '%' || u == 'pct') {
      return val.toStringAsFixed(2);
    }
    if (u == 'µω' || u == 'μω') {
      return val.toStringAsFixed(1);
    }
    if (u == 'mω') {
      return val.toStringAsFixed(3);
    }
    if (u == 'ω' || u == 'ohm') {
      if (tid.contains('TD') || tid.contains('DAT') || tid.contains('GROUND')) {
        return val.toStringAsFixed(2);
      }
      return val.toStringAsFixed(3);
    }
    if (u == 'ma') {
      return val.toStringAsFixed(3);
    }
    if (u == 'µa' || u == 'μa') {
      return val.toStringAsFixed(1);
    }
    if (u == 'kv') {
      return val.toStringAsFixed(2);
    }
    if (u == 'ms') {
      return val.toStringAsFixed(1);
    }
    if (u == 's') {
      return val.abs() >= 10 ? val.toStringAsFixed(1) : val.toStringAsFixed(3);
    }
    if (u == 'mω' || u == 'gω') {
      return val.abs() >= 100 ? val.toStringAsFixed(0) : val.toStringAsFixed(1);
    }

    return val.toStringAsFixed(defaultDecimals);
  }
}
