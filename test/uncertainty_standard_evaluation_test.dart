import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:mte_calculator_pro/services/calibration_service.dart';

void main() {
  late List<CalibratedEquipmentModel> equipments;

  setUpAll(() {
    final calibFile = File('assets/calibrated_equipment.json');
    final list = jsonDecode(calibFile.readAsStringSync()) as List;
    equipments = list
        .map((e) => CalibratedEquipmentModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  });

  CalibratedEquipmentModel getEquipmentForTest(String testCode) {
    return equipments.firstWhere((eq) => eq.applicableTests.contains(testCode));
  }

  group('Uncertainty Final Result Evaluation Tests', () {
    test('DLRO-200 calibrates MC_R_tx and applies correction to effective value', () {
      final eq = getEquipmentForTest('MC_R_tx');

      // Giả sử đo 82.6 micro-ohm (điểm hiệu chuẩn: deviceValue=82.6, correction=+0.73)
      final res = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: 82.6,
        unit: 'microΩ',
      );

      expect(res.correctedValue, closeTo(83.33, 1e-2));
      expect(res.correction, closeTo(0.73, 1e-2));
    });

    test('Transformer Rdc calculates 75°C derived corrected value and deltaR', () {
      final eq = getEquipmentForTest('MBA_R_dc'); // TRM-20 S2

      // Đo ở 30°C: Ra = 4.0 mΩ, Rb = 4.0 mΩ, Rc = 4.0 mΩ
      final rawA = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: 4.0,
        unit: 'mΩ',
      );

      // Điểm hiệu chuẩn 4.0 mΩ của TRM-20 S2 có hiệu chính
      expect(rawA.correctedValue, isNotNull);

      // Quy đổi 75°C
      double factor = (235.0 + 75.0) / (235.0 + 30.0);
      double rQdA = rawA.correctedValue * factor;
      expect(rQdA, greaterThan(rawA.correctedValue));
    });

    test('TITU ratio error calculates derived f_hc after calibration', () {
      final eq = getEquipmentForTest('TITU_Ratio_Error'); // ATRT-03B

      double kdm = 100.0;
      double ktt = 100.2;

      final rawRes = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: ktt,
        unit: '',
      );

      double fHc = ((rawRes.correctedValue - kdm) / kdm) * 100.0;
      final derivedRes = rawRes.withDerived(
        derivedName: 'Sai số f_hc (Class 0.2)',
        derivedCorrected: fHc,
        derivedMinBound: fHc - 0.05,
        derivedMaxBound: fHc + 0.05,
        derivedUnit: '%',
        standardLimit: 0.2,
        isUpperBound: true,
      );

      expect(derivedRes.derivedCorrected, isNotNull);
      expect(derivedRes.derivedCorrected, equals(fHc));
    });

    test('Aptomat DLRO-200 evaluates APT_R_tx with calibrated contact resistance', () {
      final eq = getEquipmentForTest('APT_R_tx');

      final res = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: 100.0,
        unit: 'microΩ',
      );

      // Điểm hiệu chuẩn: 99.4 -> correction 0.6 -> base 100.0
      expect(res.correctedValue, closeTo(100.6, 1.0));
    });

    test('Cable Rdc TRM-20 S2 evaluates 20°C converted resistance with uncertainty', () {
      final eq = getEquipmentForTest('CABLE_Rdc_20_Cu');

      double rDo = 10.0; // mΩ ở 30°C
      final raw = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: rDo,
        unit: 'mΩ',
      );

      double factor = (235.0 + 20.0) / (235.0 + 30.0);
      double r20Hc = raw.correctedValue * factor;
      expect(r20Hc, lessThan(raw.correctedValue));
    });

    test('CT-6500/S2 (CAL_EQ_08_CT65000) calibrates MC_Time_Delta and points', () {
      final eq = getEquipmentForTest('MC_Time_Delta');
      expect(eq.id, equals('CAL_EQ_08_CT65000'));
      expect(eq.type, equals('CT-6500/S2'));

      // Kiểm tra điểm 100.0 ms -> correction = -0.10 ms -> correctedValue = 99.90 ms
      final res100 = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: 100.0,
        unit: 'ms',
      );
      expect(res100.correction, closeTo(-0.10, 1e-3));
      expect(res100.correctedValue, closeTo(99.90, 1e-3));

      // Kiểm tra điểm 4000.0 ms -> correction = -3.00 ms -> correctedValue = 3997.00 ms
      final res4000 = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: 4000.0,
        unit: 'ms',
      );
      expect(res4000.correction, closeTo(-3.00, 1e-3));
      expect(res4000.correctedValue, closeTo(3997.00, 1e-3));
    });

    test('DILO 3-38R (CAL_EQ_09_DILOSF6) calibrates MC_SF6_Purity with uncertainty', () {
      final eq = getEquipmentForTest('MC_SF6_Purity');
      expect(eq.id, equals('CAL_EQ_09_DILOSF6'));
      expect(eq.type, equals('DILO 3-38R'));

      // Kiểm tra điểm 99.96 % -> correction = +0.04 % -> correctedValue = 100.00 %
      final resPurity = CalibrationService.calculateUncertainty(
        equipment: eq,
        measuredValue: 99.96,
        unit: '%',
      );
      expect(resPurity.correction, closeTo(0.04, 1e-3));
      expect(resPurity.correctedValue, closeTo(100.00, 1e-3));
      expect(resPurity.expandedUncertainty, greaterThan(0.0));

      // Đánh giá tiêu chuẩn >= 97% (Purity)
      final verdict = resPurity.evaluate(97.0, isUpperBound: false);
      expect(verdict, equals(UncertaintyVerdict.pass));
    });
  });
}
