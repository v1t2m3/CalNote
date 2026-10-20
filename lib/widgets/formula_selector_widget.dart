import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import '../services/formula_service.dart';

/// Widget cho phép người dùng lựa chọn công thức / phương pháp tính toán linh hoạt
/// Áp dụng cho các phép đo có nhiều công thức (VD: Rtx máy cắt, DCL, DTD, Recloser, MBA)
class FormulaSelectorWidget extends StatelessWidget {
  final String groupCode;
  final FormulaModel? selectedFormula;
  final ValueChanged<FormulaModel> onFormulaChanged;
  final String customLabel;

  const FormulaSelectorWidget({
    super.key,
    required this.groupCode,
    required this.selectedFormula,
    required this.onFormulaChanged,
    this.customLabel = 'Phương pháp tính độ lệch (ΔR):',
  });

  @override
  Widget build(BuildContext context) {
    final formulas = FormulaService.getFormulasByGroup(groupCode);
    if (formulas.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentFormula = selectedFormula ?? formulas.first;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_outlined,
                  size: 18, color: AppTheme.accentOrange),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  customLabel,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: AppTheme.fontSizeCaption,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              // Dropdown chọn phương pháp
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                decoration: BoxDecoration(
                  color: AppTheme.bgDark,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: AppTheme.accentOrange.withValues(alpha: 0.6)),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: currentFormula.testId,
                    isDense: true,
                    dropdownColor: AppTheme.cardDark,
                    icon: const Icon(Icons.arrow_drop_down, color: AppTheme.accentOrange, size: 20),
                    style: const TextStyle(
                      color: AppTheme.textWhite,
                      fontSize: AppTheme.fontSizeCaption,
                      fontWeight: FontWeight.bold,
                    ),
                    items: formulas.map((f) {
                      final label = f.method ?? f.name;
                      return DropdownMenuItem<String>(
                        value: f.testId,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        final found = formulas.firstWhere((f) => f.testId == val);
                        onFormulaChanged(found);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          // Dòng hiển thị công thức toán học minh họa
          Text(
            "* Công thức: ${currentFormula.name} = ${_formatFormula(currentFormula.formula)}",
            style: AppTheme.captionItalic,
          ),
        ],
      ),
    );
  }

  String _formatFormula(String raw) {
    return raw
        .replaceAll('*', '×')
        .replaceAll('/', '÷')
        .replaceAll('R_max', 'Rmax')
        .replaceAll('R_min', 'Rmin')
        .replaceAll('R_avg', 'Rtb')
        .replaceAll('R_nsx', 'Rnsx');
  }
}
