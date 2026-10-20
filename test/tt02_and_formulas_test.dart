import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mte_calculator_pro/services/formula_service.dart';
import 'package:mte_calculator_pro/services/reference_standard_service.dart';

void main() {
  group('TT02 & Formulas Unit Tests', () {
    test('standardTT02.json file contains 24 valid items and sanitized categories', () {
      final file = File('assets/standardTT02.json');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      final list = jsonDecode(content) as List;
      expect(list.length, equals(24));

      for (var item in list) {
        expect(item['id'], isNotNull);
        expect(item['category'], isNotNull);
        // Categories must be standardized
        expect(item['category'], isNot(equals('Máy cắt')));
        expect(item['category'], isNot(equals('Máy biến áp')));
      }

      // Check specific new TT02 items
      final ids = list.map((e) => e['id']).toSet();
      expect(ids.contains('TT02_015'), isTrue); // MC Rtx
      expect(ids.contains('TT02_016'), isTrue); // Cable VLF
      expect(ids.contains('TT02_017'), isTrue); // Cable AC
      expect(ids.contains('TT02_018'), isTrue); // MBA Rdc >35kV
      expect(ids.contains('TT02_019'), isTrue); // MBA Rdc <=35kV
      expect(ids.contains('TT02_020'), isTrue); // MC Time Close
      expect(ids.contains('TT02_021'), isTrue); // MC Time Open
      expect(ids.contains('TT02_022'), isTrue); // MC SF6 Hum
      expect(ids.contains('TT02_023'), isTrue); // MC SF6 SO2
      expect(ids.contains('TT02_024'), isTrue); // MC SF6 Purity
    });

    test('FormulaService calculations for Contact Resistance methods', () {
      // 1. Method NSX: ((R_max - R_nsx) / R_nsx) * 100
      final formulaNsx = "((R_max - R_nsx) / R_nsx) * 100";
      final resNsx = FormulaService.calculate(formulaNsx, {'R_max': 60, 'R_nsx': 50});
      expect(resNsx, closeTo(20.0, 1e-4));

      // 2. Method Min: ((R_max - R_min) / R_min) * 100
      final formulaMin = "((R_max - R_min) / R_min) * 100";
      final resMin = FormulaService.calculate(formulaMin, {'R_max': 60, 'R_min': 40});
      expect(resMin, closeTo(50.0, 1e-4));

      // 3. Method Avg: ((R_max - R_min) / R_avg) * 100
      final formulaAvg = "((R_max - R_min) / R_avg) * 100";
      final resAvg = FormulaService.calculate(formulaAvg, {'R_max': 60, 'R_min': 40, 'R_avg': 50});
      expect(resAvg, closeTo(40.0, 1e-4));
    });

    test('ReferenceStandardService compareValue evaluates TT02 limits accurately', () {
      // MC_R_tx: <= 50%
      expect(ReferenceStandardService.compareValue(20.0, '≤', 50, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(50.0, '≤', 50, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(55.0, '≤', 50, null, null), isFalse);

      // MBA_R_dc: <= 2%
      expect(ReferenceStandardService.compareValue(1.8, '≤', 2, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(2.2, '≤', 2, null, null), isFalse);

      // MC_Time_Close: <= 5 ms
      expect(ReferenceStandardService.compareValue(4.2, '≤', 5, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(5.5, '≤', 5, null, null), isFalse);

      // MC_Time_Open: <= 3.3 ms
      expect(ReferenceStandardService.compareValue(3.0, '≤', 3.3, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(3.5, '≤', 3.3, null, null), isFalse);

      // MC_SF6_Hum: <= 100 ppm
      expect(ReferenceStandardService.compareValue(85.0, '≤', 100, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(105.0, '≤', 100, null, null), isFalse);

      // MC_SF6_SO2: <= 12 ppm
      expect(ReferenceStandardService.compareValue(10.0, '≤', 12, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(15.0, '≤', 12, null, null), isFalse);

      // MC_SF6_Purity: >= 97%
      expect(ReferenceStandardService.compareValue(98.2, '≥', 97.0, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(96.5, '≥', 97.0, null, null), isFalse);

      // Cable High Voltage: >= 181 kV
      expect(ReferenceStandardService.compareValue(190.0, '≥', 181, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(175.0, '≥', 181, null, null), isFalse);
    });

    test('FormulaModel serialization handles groupCode and method properly', () {
      final json = {
        'test_id': 'MC_Rtx_Delta_Nsx',
        'group_code': 'MC_R_tx',
        'method': 'So với R_nsx',
        'name': 'Độ lệch Rtx Máy cắt (So với NSX)',
        'inputs': ['R_max', 'R_nsx'],
        'formula': '((R_max - R_nsx) / R_nsx) * 100',
        'unit': '%'
      };
      final model = FormulaModel.fromJson(json);
      expect(model.testId, equals('MC_Rtx_Delta_Nsx'));
      expect(model.groupCode, equals('MC_R_tx'));
      expect(model.method, equals('So với R_nsx'));
      expect(model.inputs.length, equals(2));

      final backJson = model.toJson();
      expect(backJson['group_code'], equals('MC_R_tx'));
      expect(backJson['method'], equals('So với R_nsx'));
    });
  });
}
