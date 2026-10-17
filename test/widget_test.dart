import 'package:flutter_test/flutter_test.dart';
import 'package:mte_calculator_pro/services/reference_standard_service.dart';

void main() {
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
  });
}
