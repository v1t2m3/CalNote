import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mte_calculator_pro/screens/transformer_calculator_screen.dart';
import 'package:mte_calculator_pro/services/formula_service.dart';
import 'package:mte_calculator_pro/services/calibration_service.dart';
import 'package:mte_calculator_pro/services/reference_standard_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_trans_test_');
    Hive.init(tempDir.path);

    // 1. Formulas
    final fBox = await Hive.openBox(FormulaService.boxName);
    final formulasJson = jsonDecode(File('assets/formulas.json').readAsStringSync()) as List;
    for (var f in formulasJson) {
      final model = FormulaModel.fromJson(Map<String, dynamic>.from(f));
      await fBox.put(model.testId, model.toJson());
    }

    // 2. Calibration
    final cBox = await Hive.openBox(CalibrationService.boxName);
    final calibJson = jsonDecode(File('assets/calibrated_equipment.json').readAsStringSync()) as List;
    for (var c in calibJson) {
      final model = CalibratedEquipmentModel.fromJson(Map<String, dynamic>.from(c));
      await cBox.put(model.id, model.toJson());
    }

    // 3. Standards
    final sBox = await Hive.openBox(ReferenceStandardService.boxStandards);
    final stdJson = jsonDecode(File('assets/standards.json').readAsStringSync()) as List;
    for (var s in stdJson) {
      final model = ReferenceItemModel.fromJson(Map<String, dynamic>.from(s));
      await sBox.put(model.id, model.toJson());
    }

    final ttBox = await Hive.openBox(ReferenceStandardService.boxTT02);
    final ttJson = jsonDecode(File('assets/standardTT02.json').readAsStringSync()) as List;
    for (var t in ttJson) {
      final model = ReferenceItemModel.fromJson(Map<String, dynamic>.from(t));
      await ttBox.put(model.id, model.toJson());
    }

    final cbmBox = await Hive.openBox(ReferenceStandardService.boxCBM);
    final cbmJson = jsonDecode(File('assets/standardCBM.json').readAsStringSync()) as List;
    for (var c in cbmJson) {
      final model = CbmItemModel.fromJson(Map<String, dynamic>.from(c));
      await cbmBox.put(model.id, model.toJson());
    }

    await Hive.openBox('appSettingsBox');
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  testWidgets('Selecting MBA_Unbalance_Nsx does not crash and renders Rnsx text field properly', (tester) async {
    // Set a large screen size to prevent scroll overflow issues during tests
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const MaterialApp(
        home: TransformerCalculatorScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Title and Module II are present
    expect(find.text('TÍNH TOÁN MBA 3 PHA'), findsOneWidget);
    expect(find.text('II. ĐIỆN TRỞ MỘT CHIỀU CUỘN DÂY (mΩ)'), findsOneWidget);

    // Initial state does not show Rnsx field (default formula is So với R_avg)
    expect(find.text('Rnsx cuộn dây (mΩ)'), findsNothing);

    // Tap formula selector dropdown to select "So với R_nsx"
    final dropdownFinder = find.byType(DropdownButton<String>);
    expect(dropdownFinder, findsWidgets);

    // Tap the first dropdown (which is the MBA_Unbalance dropdown)
    await tester.tap(dropdownFinder.first);
    await tester.pumpAndSettle();

    // Find and select "So với R_nsx"
    final nsxOptionFinder = find.text('So với R_nsx').last;
    expect(nsxOptionFinder, findsOneWidget);
    await tester.tap(nsxOptionFinder);
    await tester.pumpAndSettle();

    // CRUCIAL ASSERTION: Verify no exception / crash, and Rnsx TextField is now visible!
    expect(find.text('Rnsx cuộn dây (mΩ)'), findsOneWidget);
    expect(find.text('(*) Vui lòng nhập Rnsx cuộn dây để tính độ lệch và đối chiếu tiêu chuẩn.'), findsOneWidget);

    // Enter Rnsx value
    final rnsxFieldFinder = find.widgetWithText(TextField, 'Rnsx cuộn dây (mΩ)');
    expect(rnsxFieldFinder, findsOneWidget);
    await tester.enterText(rnsxFieldFinder, '1.25');
    await tester.pumpAndSettle();

    // Enter Ra, Rb, Rc, Tdo, Ttc
    final raFinder = find.widgetWithText(TextField, 'Ra');
    final rbFinder = find.widgetWithText(TextField, 'Rb');
    final rcFinder = find.widgetWithText(TextField, 'Rc');
    final tdoFinder = find.widgetWithText(TextField, 'T_đo (°C)');
    final ttcFinder = find.widgetWithText(TextField, 'T_tc (°C)');

    await tester.enterText(raFinder, '1.24');
    await tester.enterText(rbFinder, '1.25');
    await tester.enterText(rcFinder, '1.26');
    await tester.enterText(tdoFinder, '30');
    await tester.enterText(ttcFinder, '75');
    await tester.pumpAndSettle();

    // Tap "TÍNH Rđc - Rqd" button
    final calcBtn = find.text('TÍNH Rđc - Rqd');
    expect(calcBtn, findsOneWidget);
    await tester.tap(calcBtn);
    await tester.pumpAndSettle();

    // Verify results and Standard Evaluation are rendered without error
    expect(find.textContaining('Ra:'), findsOneWidget);
    expect(find.textContaining('Rb:'), findsOneWidget);
    expect(find.textContaining('Rc:'), findsOneWidget);
    expect(find.textContaining('ΔR:'), findsOneWidget);
    expect(find.text('ĐỐI CHIẾU TIÊU CHUẨN ĐIỆN TRỞ 1 CHIỀU'), findsOneWidget);

    // Verify no unhandled exception
    expect(tester.takeException(), isNull);
  });
}
