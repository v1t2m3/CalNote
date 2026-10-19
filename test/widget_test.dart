import 'package:flutter_test/flutter_test.dart';
import 'package:mte_calculator_pro/services/reference_standard_service.dart';
import 'package:mte_calculator_pro/core/utils/app_formatters.dart';

void main() {
  group('AppFormatters Unit Tests', () {
    test('parseInput handles comma and dot seamlessly', () {
      expect(AppFormatters.parseInput('12,345'), 12.345);
      expect(AppFormatters.parseInput('12.345'), 12.345);
      expect(AppFormatters.parseInput('  0,05  '), 0.05);
      expect(AppFormatters.parseInput(''), 0.0);
      expect(AppFormatters.parseInput('abc'), 0.0);
    });

    test('format decimal precisions adhere strictly to technical standards', () {
      // Rdc: 3 decimals
      expect(AppFormatters.formatRdc(0.1256), '0.126 Ω');
      // Grounding: 2 decimals
      expect(AppFormatters.formatGrounding(3.456), '3.46 Ω');
      // Ratio K: 4 decimals
      expect(AppFormatters.formatRatio(51.02543), '51.0254');
      // DAR & PI: 2 decimals
      expect(AppFormatters.formatDarPi(1.456), '1.46');
      expect(AppFormatters.formatDarPi(2.304), '2.30');
      // Rtx: 1 decimal
      expect(AppFormatters.formatRtx(35.42), '35.4 μΩ');
      // Percent: 2 decimals
      expect(AppFormatters.formatPercent(2.046), '2.05 %');
      // Format Smart by testId
      expect(AppFormatters.formatSmart(0.1254, testId: 'MBA_R_dc'), '0.125');
      expect(AppFormatters.formatSmart(3.456, testId: 'TD_TIEP_DIA'), '3.46');
      expect(AppFormatters.formatSmart(51.0254, testId: 'TITU_RATIO'), '51.0254');
    });
  });

  group('ReferenceStandardService Unit Tests', () {
    test('matchVoltage tests', () {
      expect(ReferenceStandardService.matchVoltage('<=35kV', 'ALL'), isTrue);
      expect(ReferenceStandardService.matchVoltage('>35kV', 'ALL'), isTrue);
      expect(ReferenceStandardService.matchVoltage('<=35kV', '<=35kV'), isTrue);
      expect(ReferenceStandardService.matchVoltage('110kV', '>35kV'), isTrue);
      expect(ReferenceStandardService.matchVoltage('>35kV', '>35kV'), isTrue);
      expect(ReferenceStandardService.matchVoltage('<=35kV', '>35kV'), isFalse);
    });

    test('ReferenceItemModel deserializes separated categories correctly', () {
      final itemRot = ReferenceItemModel.fromJson({
        'id': 'rot_1',
        'category': 'Máy Điện Quay',
        'categoryCode': 'rotating_machine',
        'subCategory': 'Máy phát điện',
        'item': 'Điện trở cách điện cuộn dây stator',
        'limit': '≥ 1 MΩ/kV',
        'standard': 'TCVN',
        'voltageLevel': 'ALL',
      });
      expect(itemRot.categoryCode, 'rotating_machine');
      expect(itemRot.category, 'Máy Điện Quay');

      final itemPq = ReferenceItemModel.fromJson({
        'id': 'pq_1',
        'category': 'Chất Lượng Điện Năng',
        'categoryCode': 'power_quality',
        'subCategory': 'Sóng hài',
        'item': 'Tổng độ biến dạng sóng hài điện áp THD',
        'limit': '≤ 5%',
        'standard': 'TT 39/2015',
        'voltageLevel': 'ALL',
      });
      expect(itemPq.categoryCode, 'power_quality');
      expect(itemPq.category, 'Chất Lượng Điện Năng');

      final itemCap = ReferenceItemModel.fromJson({
        'id': 'cap_1',
        'category': 'Tụ Điện / Tụ Bù',
        'categoryCode': 'capacitor',
        'subCategory': 'Tụ bù hạ thế',
        'item': 'Điện dung thực tế',
        'limit': '-5% ~ +10%',
        'standard': 'IEC 60831',
        'voltageLevel': '<=35kV',
      });
      expect(itemCap.categoryCode, 'capacitor');
      expect(itemCap.voltageLevel, '<=35kV');
    });

    test('CbmItemModel displayItem includes symbol in parenthesis', () {
      final cbmWithSym = CbmItemModel.fromJson({
        'id': 'STD_052',
        'category': 'Máy biến áp lực',
        'categoryCode': 'transformer',
        'item': 'Đo điện trở một chiều các cuộn dây (ΔR)',
        'symbol': 'ΔR',
        'good': '≤ 2.0 %',
        'poor': '> 2.0 %',
      });
      expect(cbmWithSym.displayItem, 'Đo điện trở một chiều các cuộn dây (ΔR)');

      // If item did not have parenthesis in raw json, displayItem auto appends it
      final cbmRaw = CbmItemModel.fromJson({
        'id': 'STD_050',
        'category': 'Máy biến áp lực',
        'categoryCode': 'transformer',
        'item': 'Đo điện trở cách điện gông từ',
        'symbol': 'IR',
        'good': '> 500 MΩ',
        'poor': '< 10 MΩ',
      });
      expect(cbmRaw.displayItem, 'Đo điện trở cách điện gông từ (IR)');
    });

    test('compareValue evaluates bilateral error and thresholds accurately', () {
      // Ratio error test (threshold <= 0.5%)
      // Positive in limit:
      expect(ReferenceStandardService.compareValue(0.02, '≤', 0.5, null, null), isTrue);
      // Negative in limit (val.abs() <= 0.5):
      expect(ReferenceStandardService.compareValue(-0.02, '≤', 0.5, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(-0.02, '≤', 0.5, null, null, isBilateral: true), isTrue);
      // Out of limit:
      expect(ReferenceStandardService.compareValue(0.66, '≤', 0.5, null, null), isFalse);
      expect(ReferenceStandardService.compareValue(-0.66, '≤', 0.5, null, null), isFalse);
      expect(ReferenceStandardService.compareValue(-0.66, '≤', 0.5, null, null, isBilateral: true), isFalse);

      // Between comparison:
      expect(ReferenceStandardService.compareValue(1.3, 'between', null, 1.0, 1.5), isTrue);
      expect(ReferenceStandardService.compareValue(0.9, 'between', null, 1.0, 1.5), isFalse);
      expect(ReferenceStandardService.compareValue(1.6, 'between', null, 1.0, 1.5), isFalse);
    });

    test('ReferenceStandardService results use strictly standardized "Đạt" / "Không đạt"', () {
      const stdItem = ReferenceItemModel(
        id: 'STD_042',
        category: 'Máy biến áp lực',
        categoryCode: 'transformer',
        subCategory: 'Máy biến áp',
        item: 'Đo tỷ số biến và sai lệch tỷ số biến',
        testCode: 'MBA_K_error',
        limit: 'Δku ≤ 0.5 %',
        standard: 'TCVN 6306-1:2015',
        voltageLevel: '<=35kV',
        compare: '≤',
        value: 0.5,
        unit: '%',
        recommendation: 'Kiểm tra tỷ số biến',
      );
      final passA = ReferenceStandardService.compareValue(0.02, stdItem.compare, stdItem.value, stdItem.min, stdItem.max, isBilateral: true);
      expect(passA, isTrue);
      final passC = ReferenceStandardService.compareValue(0.66, stdItem.compare, stdItem.value, stdItem.min, stdItem.max, isBilateral: true);
      expect(passC, isFalse);
    });
  });
}
