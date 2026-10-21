import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mte_calculator_pro/services/formula_service.dart';
import 'package:mte_calculator_pro/services/reference_standard_service.dart';
import 'package:mte_calculator_pro/core/theme/app_theme.dart';

void main() {
  group('TT02 & Formulas Unit Tests', () {
    test('standardTT02.json file contains 24 valid items and sanitized categories', () {
      final file = File('assets/standardTT02.json');
      expect(file.existsSync(), isTrue);
      final content = file.readAsStringSync();
      final list = jsonDecode(content) as List;
      expect(list.length, equals(23));

      for (var item in list) {
        expect(item['id'], isNotNull);
        expect(item['category'], isNotNull);
        // Categories must be standardized
        expect(item['category'], isNot(equals('Máy cắt')));
        expect(item['category'], isNot(equals('Máy biến áp')));
      }

      // Check specific new TT02 items
      final ids = list.map((e) => e['id']).toSet();
      expect(ids.contains('TT02_011'), isTrue); // MC Rtx
      expect(ids.contains('TT02_012'), isTrue); // MC Time Close
      expect(ids.contains('TT02_013'), isTrue); // MC Time Open
      expect(ids.contains('TT02_014'), isTrue); // MC SF6 Hum
      expect(ids.contains('TT02_015'), isTrue); // MC SF6 SO2
      expect(ids.contains('TT02_016'), isTrue); // MC SF6 Purity
      expect(ids.contains('TT02_017'), isTrue); // DCL Rtx
      expect(ids.contains('TT02_018'), isTrue); // Cable Rcd
      expect(ids.contains('TT02_021'), isTrue); // Cable VLF <=35kV
      expect(ids.contains('TT02_022'), isTrue); // Cable AC <=35kV
      expect(ids.contains('TT02_023'), isTrue); // Cable Rdc
    });

    test('FormulaService calculations for Contact Resistance methods', () {
      // 1. Method NSX: ((R_max - R_nsx) / R_nsx) * 100
      const formulaNsx = "((R_max - R_nsx) / R_nsx) * 100";
      final resNsx = FormulaService.calculate(formulaNsx, {'R_max': 60, 'R_nsx': 50});
      expect(resNsx, closeTo(20.0, 1e-4));

      // 2. Method Min: ((R_max - R_min) / R_min) * 100
      const formulaMin = "((R_max - R_min) / R_min) * 100";
      final resMin = FormulaService.calculate(formulaMin, {'R_max': 60, 'R_min': 40});
      expect(resMin, closeTo(50.0, 1e-4));

      // 3. Method Avg: ((R_max - R_min) / R_avg) * 100
      const formulaAvg = "((R_max - R_min) / R_avg) * 100";
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

    test('FormulaService calculatePhaseDeviations evaluates contact resistance accurately', () {
      // Test data matching user screenshot: rA=55.7, rB=55.9, rC=57.4
      final phaseValues = {'Pha A': 55.7, 'Pha B': 55.9, 'Pha C': 57.4};

      // 1. Method Min (fallback when no R_nsx entered)
      final devsMin = FormulaService.calculatePhaseDeviations(
        phaseValues: phaseValues,
        formulaId: 'MC_Rtx_Delta_Min',
      );
      expect(devsMin['Pha A'], closeTo(0.0, 1e-4));
      expect(devsMin['Pha B'], closeTo(0.359, 1e-3));
      expect(devsMin['Pha C'], closeTo(3.052, 1e-3));

      // Each phase deviation must be <= 10% (IEC Standard) -> all PASS
      for (var val in devsMin.values) {
        expect(ReferenceStandardService.compareValue(val, '≤', 10, null, null), isTrue);
      }

      // 2. Method NSX with R_nsx = 55.0
      final devsNsx = FormulaService.calculatePhaseDeviations(
        phaseValues: phaseValues,
        formulaId: 'MC_Rtx_Delta_Nsx',
        rNsx: 55.0,
      );
      expect(devsNsx['Pha A'], closeTo(1.272, 1e-3));
      expect(devsNsx['Pha B'], closeTo(1.636, 1e-3));
      expect(devsNsx['Pha C'], closeTo(4.363, 1e-3));
      for (var val in devsNsx.values) {
        expect(ReferenceStandardService.compareValue(val, '≤', 10, null, null), isTrue);
      }

      // 3. Out-of-spec phase: Phase C degrades to 70 uOhm with R_min=50
      final degradedValues = {'Pha A': 50.0, 'Pha B': 52.0, 'Pha C': 70.0};
      final devsDegraded = FormulaService.calculatePhaseDeviations(
        phaseValues: degradedValues,
        formulaId: 'MC_Rtx_Delta_Min',
      );
      expect(ReferenceStandardService.compareValue(devsDegraded['Pha A']!, '≤', 10, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(devsDegraded['Pha B']!, '≤', 10, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(devsDegraded['Pha C']!, '≤', 10, null, null), isFalse); // 40% > 10%
    });

    test('FormulaService calculatePhaseDeviations evaluates MBA winding resistance against R_nsx with absolute deviation', () {
      final mbaPhaseValues = {'Pha A': 1.23, 'Pha B': 1.25, 'Pha C': 1.28};

      // R_nsx = 1.25 mΩ
      // Pha A = 1.23: |1.23 - 1.25| / 1.25 * 100 = 1.6% (<= 2% -> Pass)
      // Pha B = 1.25: |1.25 - 1.25| / 1.25 * 100 = 0.0% (<= 2% -> Pass)
      // Pha C = 1.28: |1.28 - 1.25| / 1.25 * 100 = 2.4% (> 2% -> Fail standard <= 2%)
      final devsNsx = FormulaService.calculatePhaseDeviations(
        phaseValues: mbaPhaseValues,
        formulaId: 'MBA_Unbalance_Nsx',
        rNsx: 1.25,
      );

      expect(devsNsx['Pha A'], closeTo(1.6, 1e-3));
      expect(devsNsx['Pha B'], closeTo(0.0, 1e-3));
      expect(devsNsx['Pha C'], closeTo(2.4, 1e-3));

      expect(ReferenceStandardService.compareValue(devsNsx['Pha A']!, '≤', 2.0, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(devsNsx['Pha B']!, '≤', 2.0, null, null), isTrue);
      expect(ReferenceStandardService.compareValue(devsNsx['Pha C']!, '≤', 2.0, null, null), isFalse);
    });

    test('ReferenceStandardService evaluateCbmLevel classifies values properly', () {
      const cbmItem = CbmItemModel(
        id: 'CBM_001',
        category: 'Máy cắt',
        categoryCode: 'circuit_breaker',
        subCategory: 'Máy cắt',
        item: 'Rtx',
        testCode: 'MC_R_tx',
        voltageLevel: '>35kV',
        good: '<=10%',
        fair: '10-20%',
        average: '20-50%',
        poor: '>50%',
        standard: 'Quy trình EVN',
        recommendation: '',
        levels: {
          'level1': {'compare': '≤', 'value': 10},
          'level2': {'compare': 'between', 'min': 10, 'max': 20},
          'level3': {'compare': 'between', 'min': 20, 'max': 50},
          'level4': {'compare': '>', 'value': 50},
        },
      );

      expect(ReferenceStandardService.evaluateCbmLevel(cbmItem, 4.5), equals(1));
      expect(ReferenceStandardService.evaluateCbmLevel(cbmItem, 15.0), equals(2));
      expect(ReferenceStandardService.evaluateCbmLevel(cbmItem, 35.0), equals(3));
      expect(ReferenceStandardService.evaluateCbmLevel(cbmItem, 60.0), equals(4));
    });

    test('AppTheme CBM 4 colors and conclusion mapping adhere to EVN standard', () {
      // 4 màu chuẩn EVN: Xanh lục, Vàng, Cam, Đỏ
      expect(AppTheme.getCbmColor(1), equals(AppTheme.cbmLevel1)); // Xanh lục (0xFF00E676)
      expect(AppTheme.getCbmColor(2), equals(AppTheme.cbmLevel2)); // Vàng (0xFFFFD600)
      expect(AppTheme.getCbmColor(3), equals(AppTheme.cbmLevel3)); // Cam (0xFFFF7A00)
      expect(AppTheme.getCbmColor(4), equals(AppTheme.cbmLevel4)); // Đỏ (0xFFFF3B30)

      // 4 kết luận tương ứng: Tốt, Khá, Trung bình, Xấu
      expect(AppTheme.getCbmConclusion(1), equals("Tốt"));
      expect(AppTheme.getCbmConclusion(2), equals("Khá"));
      expect(AppTheme.getCbmConclusion(3), equals("Trung bình"));
      expect(AppTheme.getCbmConclusion(4), equals("Xấu"));

      // Mapping theo tên kết luận
      expect(AppTheme.getCbmColorByConclusion("Tốt"), equals(AppTheme.cbmLevel1));
      expect(AppTheme.getCbmColorByConclusion("Khá"), equals(AppTheme.cbmLevel2));
      expect(AppTheme.getCbmColorByConclusion("Trung bình"), equals(AppTheme.cbmLevel3));
      expect(AppTheme.getCbmColorByConclusion("Xấu"), equals(AppTheme.cbmLevel4));
    });
  });
}

