import '../core/widgets/calculation_breakdown.dart';
import '../core/utils/formatters.dart';
import '../models/product_model.dart';

class StandardizationResult {
  final double initialQuantity;
  final double initialFat;
  final double initialSnf;
  final double targetFat;
  final double targetSnf;
  final double waterRequired;
  final double smpRequired;
  final double sugarRequired;
  final double finalQuantity;
  final double finalFat;
  final double finalSnf;
  final String formulaVersion;
  final List<BreakdownStep> breakdownSteps;

  const StandardizationResult({
    required this.initialQuantity,
    required this.initialFat,
    required this.initialSnf,
    required this.targetFat,
    required this.targetSnf,
    required this.waterRequired,
    required this.smpRequired,
    required this.sugarRequired,
    required this.finalQuantity,
    required this.finalFat,
    required this.finalSnf,
    required this.formulaVersion,
    required this.breakdownSteps,
  });
}

/// ============================================================================
/// CASEYA MILK STANDARDIZATION CALCULATION ENGINE
/// ============================================================================
class MilkStandardizationCalculator {
  static const String formulaVersion = 'v1.2-Standard-Dairy-MassBalance';

  /// Official Dairy Plant Standardization Target Products
  static const List<ProductModel> standardizationProducts = [
    ProductModel(
      productId: 'STD_MILK',
      productName: 'std milk',
      itemCode: 'NA',
      shortCode: 'STD',
      category: 'Milk',
      unit: 'Litres',
      packSize: 1000,
      packSizeDisplay: 'Bulk Standardized Milk',
      piecesPerCrate: 24,
      shelfLife: '2 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 4.5,
      targetSnf: 8.5,
      targetSugar: null,
    ),
    ProductModel(
      productId: 'ARMY_MILK',
      productName: 'army milk',
      itemCode: 'NA',
      shortCode: 'ARMY',
      category: 'Milk',
      unit: 'Litres',
      packSize: 1000,
      packSizeDisplay: 'Defence Supply Bulk',
      piecesPerCrate: 24,
      priceCustomLabel: 'Defence Supply',
      shelfLife: '2 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 3.5,
      targetSnf: 8.5,
      targetSugar: null,
    ),
    ProductModel(
      productId: 'PLAIN_CURD_CUP',
      productName: 'plain curd cup',
      itemCode: 'NA',
      shortCode: 'P-CUP',
      category: 'Curd',
      unit: 'Kg',
      packSize: 1000,
      packSizeDisplay: 'Cup Curd Incubation Vat',
      piecesPerCrate: 60,
      shelfLife: '12 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 3.0,
      targetSnf: 14.0,
      targetSugar: null,
    ),
    ProductModel(
      productId: 'PLAIN_CURD_POUCH',
      productName: 'plain curd pouch',
      itemCode: 'NA',
      shortCode: 'P-POUCH',
      category: 'Curd',
      unit: 'Kg',
      packSize: 1000,
      packSizeDisplay: 'Pouch Curd Vat',
      piecesPerCrate: 30,
      shelfLife: '12 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 3.0,
      targetSnf: 11.0,
      targetSugar: null,
    ),
    ProductModel(
      productId: 'SWEETENED_CURD',
      productName: 'sweetened curd',
      itemCode: 'NA',
      shortCode: 'S-CURD',
      category: 'Curd',
      unit: 'Kg',
      packSize: 1000,
      packSizeDisplay: 'Sweet Curd Incubation Vat',
      piecesPerCrate: 60,
      shelfLife: '12 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 3.0,
      targetSnf: 14.0,
      targetSugar: 12.0,
    ),
    ProductModel(
      productId: 'LASSI',
      productName: 'lassi',
      itemCode: 'NA',
      shortCode: 'LASSI',
      category: 'Fermented',
      unit: 'Litres',
      packSize: 1000,
      packSizeDisplay: 'Bulk Lassi Tank',
      piecesPerCrate: 30,
      shelfLife: '7 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 1.5,
      targetSnf: 7.0,
      targetSugar: 15.0,
    ),
  ];

  /// Standard Milk Powder (SMP) constants (configurable per plant specifications)
  static const double standardSmpSnfPercent = 96.0; // 96% SNF in SMP
  static const double standardSmpFatPercent = 0.5;  // 0.5% Fat in SMP

  static StandardizationResult calculate({
    required double milkQuantity,
    required double milkFat,
    required double milkSnf,
    required String targetProduct,
    required double targetFat,
    required double targetSnf,
    double smpSnfRatio = standardSmpSnfPercent,
    double sugarPercent = 0.0,
  }) {
    // =========================================================================
    // [PLANT_STANDARDIZATION_FORMULA_START]
    // =========================================================================

    // 1. Initial Solid Masses in Raw Milk
    // Mass of Fat = (Milk Quantity * Fat%) / 100
    final double initialFatKg = (milkQuantity * milkFat) / 100.0;
    // Mass of SNF = (Milk Quantity * SNF%) / 100
    final double initialSnfKg = (milkQuantity * milkSnf) / 100.0;

    double waterRequired = 0.0;
    double smpRequired = 0.0;
    double sugarRequired = 0.0;
    double finalQuantity = milkQuantity;

    // 2. Fat Standardization:
    // If incoming milk FAT > target FAT: Water or skim milk must be added to dilute fat down to target FAT.
    // In water dilution mode:
    // Final Vol based on Fat = (Initial Fat Kg) / (Target Fat / 100)
    if (targetFat > 0.0 && milkFat > targetFat) {
      final double targetVolumeForFat = initialFatKg / (targetFat / 100.0);
      waterRequired = (targetVolumeForFat - milkQuantity).clamp(0.0, double.infinity);
      finalQuantity = milkQuantity + waterRequired;
    }

    // 3. SNF Standardization:
    // Required SNF mass in final volume = (Final Quantity * Target SNF%) / 100
    // If initial SNF is less than required SNF, Skimmed Milk Powder (SMP) is added.
    final double targetSnfKg = (finalQuantity * targetSnf) / 100.0;
    final double snfDeficitKg = targetSnfKg - initialSnfKg;

    if (snfDeficitKg > 0.0) {
      // Required SMP (Kg) = SNF Deficit (Kg) / (SMP SNF% / 100)
      smpRequired = snfDeficitKg / (smpSnfRatio / 100.0);
    }

    // 4. Sugar Addition (if target product is sweetened, e.g. Sweetened Curd: 12%, Lassi: 15%)
    final double effectiveSugarPercent = sugarPercent > 0.0
        ? sugarPercent
        : (targetProduct.toLowerCase().contains('lassi')
            ? 15.0
            : (targetProduct.toLowerCase().contains('sweet') ? 12.0 : 0.0));

    if (effectiveSugarPercent > 0.0) {
      sugarRequired = (finalQuantity * effectiveSugarPercent) / 100.0;
      finalQuantity += (sugarRequired * 0.63); // 1kg sugar adds ~0.63L displacement volume
    }

    // 5. Final Fat and SNF Verification
    final double finalCalculatedFat = finalQuantity > 0
        ? ((initialFatKg + (smpRequired * (standardSmpFatPercent / 100.0))) / finalQuantity) * 100.0
        : 0.0;

    final double finalCalculatedSnf = finalQuantity > 0
        ? ((initialSnfKg + (smpRequired * (smpSnfRatio / 100.0))) / finalQuantity) * 100.0
        : 0.0;

    // =========================================================================
    // [PLANT_STANDARDIZATION_FORMULA_END]
    // =========================================================================

    // Construct step-by-step breakdown
    final List<BreakdownStep> steps = [
      BreakdownStep(
        stepTitle: 'STEP 1',
        formula: 'Initial Milk Quantity = Entered Volume',
        calculation: '${Formatters.formatSmart(milkQuantity)} Litres',
      ),
      BreakdownStep(
        stepTitle: 'STEP 2',
        formula: 'Initial Milk FAT = Tested / Lab Value',
        calculation: '${Formatters.formatPercent(milkFat)} (${Formatters.formatDecimal(initialFatKg)} Kg Fat Mass)',
      ),
      BreakdownStep(
        stepTitle: 'STEP 3',
        formula: 'Initial Milk SNF = Tested / Lab Value',
        calculation: '${Formatters.formatPercent(milkSnf)} (${Formatters.formatDecimal(initialSnfKg)} Kg SNF Mass)',
      ),
      BreakdownStep(
        stepTitle: 'STEP 4',
        formula: 'Target FAT = Defined Standard for $targetProduct',
        calculation: Formatters.formatPercent(targetFat),
      ),
      BreakdownStep(
        stepTitle: 'STEP 5',
        formula: 'Target SNF = Defined Standard for $targetProduct',
        calculation: Formatters.formatPercent(targetSnf),
      ),
      BreakdownStep(
        stepTitle: 'STEP 6',
        formula: 'Required SMP (Kg) = (Target SNF Mass - Initial SNF Mass) ÷ SMP SNF Ratio ($smpSnfRatio%)',
        calculation: smpRequired > 0
            ? '${Formatters.formatDecimal(smpRequired)} Kg SMP'
            : '0.00 Kg (Initial SNF meets or exceeds target)',
        note: 'SMP provides $smpSnfRatio% SNF to raise solid levels',
      ),
      BreakdownStep(
        stepTitle: 'STEP 7',
        formula: 'Required Water (L) = (Initial Fat Mass ÷ Target Fat%) - Initial Milk Quantity',
        calculation: waterRequired > 0
            ? '${Formatters.formatDecimal(waterRequired)} Litres Water'
            : '0.00 Litres (No dilution required)',
        note: 'Dilutes excess milk fat to match precise target fat',
      ),
    ];

    if (sugarRequired > 0.0) {
      steps.add(BreakdownStep(
        stepTitle: 'STEP 8',
        formula: 'Required Sugar = Final Batch Volume × Sugar Ratio ($effectiveSugarPercent%)',
        calculation: '${Formatters.formatDecimal(sugarRequired)} Kg Sugar',
      ));
    }

    steps.add(BreakdownStep(
      stepTitle: 'STEP ${sugarRequired > 0.0 ? 9 : 8}',
      formula: 'Final Standardized Milk Quantity',
      calculation: '${Formatters.formatSmart(finalQuantity)} Litres '
          '(Final FAT: ${Formatters.formatDecimal(finalCalculatedFat)}%, '
          'Final SNF: ${Formatters.formatDecimal(finalCalculatedSnf)}%)',
    ));

    return StandardizationResult(
      initialQuantity: milkQuantity,
      initialFat: milkFat,
      initialSnf: milkSnf,
      targetFat: targetFat,
      targetSnf: targetSnf,
      waterRequired: waterRequired,
      smpRequired: smpRequired,
      sugarRequired: sugarRequired,
      finalQuantity: finalQuantity,
      finalFat: finalCalculatedFat,
      finalSnf: finalCalculatedSnf,
      formulaVersion: formulaVersion,
      breakdownSteps: steps,
    );
  }
}
