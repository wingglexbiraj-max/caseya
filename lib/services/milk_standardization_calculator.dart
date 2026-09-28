import '../core/widgets/calculation_breakdown.dart';
import '../core/utils/formatters.dart';
import '../models/product_model.dart';

class StandardizationResult {
  final double totalBatch; // Total Batch Required (L)
  final double milkTaken; // Milk Taken (L)
  final double presentFat; // Present Milk Fat (%)
  final double presentSnf; // Present Milk SNF (%)
  final double availableFatKg; // Fat kg = Milk Taken * Present Fat / 100
  final double finalFat; // Final Fat % = (Available Fat / Total Batch) * 100
  final double availableSnfKg; // Available SNF kg = Milk Taken * Present SNF / 100
  final double requiredSnfKg; // Required SNF kg = Total Batch * Target SNF / 100
  final double snfDeficitKg; // SNF Deficit = Required SNF - Available SNF
  final double smpRequired; // SMP Required = SNF Deficit * (smpFactor / 100)
  final double sugarRequired; // Sugar = Total Batch * (sugarPercent / 100)
  final double waterRequired; // Water = Total Batch - (Milk Taken + SNF Deficit)
  final double finalQuantity; // Total final volume
  final double finalSnf; // Final SNF %
  final double targetFat; // Configured / Desired Target Fat %
  final double targetSnf; // Configured Target SNF %
  final double sugarPercent; // Applied Sugar %
  final double smpFactor; // Configured SMP factor % (e.g. 95.0%)
  final bool isAutoCalculatedMilk; // True if Milk Taken was auto-derived from target fat
  final List<String> warnings; // Warnings if any
  final String formulaVersion;
  final List<BreakdownStep> breakdownSteps;

  // Backwards compatibility getters
  double get initialQuantity => milkTaken;
  double get initialFat => presentFat;
  double get initialSnf => presentSnf;

  const StandardizationResult({
    required this.totalBatch,
    required this.milkTaken,
    required this.presentFat,
    required this.presentSnf,
    required this.availableFatKg,
    required this.finalFat,
    required this.availableSnfKg,
    required this.requiredSnfKg,
    required this.snfDeficitKg,
    required this.smpRequired,
    required this.sugarRequired,
    required this.waterRequired,
    required this.finalQuantity,
    required this.finalSnf,
    required this.targetFat,
    required this.targetSnf,
    required this.sugarPercent,
    required this.smpFactor,
    this.isAutoCalculatedMilk = false,
    this.warnings = const [],
    required this.formulaVersion,
    required this.breakdownSteps,
  });
}

/// ============================================================================
/// CASEYA MILK STANDARDIZATION CALCULATION ENGINE
/// ============================================================================
class MilkStandardizationCalculator {
  static const String formulaVersion = 'v2.0-Plant-Standardization-Engine';

  /// Official Dairy Plant Standardization Target Products
  static const List<ProductModel> standardizationProducts = [
    // 4 Primary Products required by dairy plant specifications:
    ProductModel(
      productId: 'MILK_SM_PLUS',
      productName: 'Milk / Milk SM+',
      itemCode: 'NA',
      shortCode: 'SM+',
      category: 'Milk',
      unit: 'Litres',
      packSize: 1000,
      packSizeDisplay: 'Bulk Milk Vat',
      piecesPerCrate: 24,
      shelfLife: '2 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 4.5,
      targetSnf: 8.5,
      targetSugar: null,
    ),
    ProductModel(
      productId: 'PLAIN_CURD',
      productName: 'Plain Curd',
      itemCode: 'NA',
      shortCode: 'P-CURD',
      category: 'Curd',
      unit: 'Kg',
      packSize: 1000,
      packSizeDisplay: 'Plain Curd Vat',
      piecesPerCrate: 30,
      shelfLife: '12 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 3.0,
      targetSnf: 8.5,
      targetSugar: null,
    ),
    ProductModel(
      productId: 'SWEET_CURD',
      productName: 'Sweet Curd',
      itemCode: 'NA',
      shortCode: 'S-CURD',
      category: 'Curd',
      unit: 'Kg',
      packSize: 1000,
      packSizeDisplay: 'Sweet Curd Incubation Vat',
      piecesPerCrate: 30,
      shelfLife: '12 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 3.0,
      targetSnf: 8.5,
      targetSugar: 12.0,
    ),
    ProductModel(
      productId: 'LASSI_BATCH',
      productName: 'Lassi',
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
      targetSnf: 8.5,
      targetSugar: 15.0,
    ),

    // Standardized products catalog for backwards compatibility and specialized packaging:
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
      shortCode: 'S-CURD-14',
      category: 'Curd',
      unit: 'Kg',
      packSize: 1000,
      packSizeDisplay: 'Sweet Curd Incubation Vat (High Solids)',
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
      shortCode: 'LASSI-7',
      category: 'Fermented',
      unit: 'Litres',
      packSize: 1000,
      packSizeDisplay: 'Bulk Lassi Tank (7% SNF)',
      piecesPerCrate: 30,
      shelfLife: '7 Days',
      allowedInputModes: ['Litres', 'Kg'],
      targetFat: 1.5,
      targetSnf: 7.0,
      targetSugar: 15.0,
    ),
  ];

  /// Standard Milk Powder (SMP) default constants
  static const double standardSmpSnfPercent = 95.0; // 95% default SMP factor

  /// Main calculation engine implementing the Dairy Plant Formulation specifications
  static StandardizationResult calculate({
    double? totalBatch,
    double? milkTaken,
    double? presentFat,
    double? presentSnf,
    required String targetProduct,
    double targetFat = 3.5,
    double targetSnf = 8.5,
    double sugarPercent = 0.0,
    double smpFactor = 95.0,
    String waterCalculationMethod = 'standard',
    // Backward compatibility parameter aliases:
    double? milkQuantity,
    double? milkFat,
    double? milkSnf,
    double? smpSnfRatio,
  }) {
    final double rawFat = presentFat ?? milkFat ?? 4.3;
    final double rawSnf = presentSnf ?? milkSnf ?? 8.33;
    final double effectiveSmpFactor = (smpSnfRatio != null && smpSnfRatio != 96.0) ? smpSnfRatio : smpFactor;

    // Detect if this is legacy dilution mode (totalBatch not supplied, but milkQuantity was supplied):
    final bool isLegacyDilutionMode = (totalBatch == null || totalBatch <= 0) && (milkQuantity != null && milkQuantity > 0);

    if (isLegacyDilutionMode) {
      final double legacyMilk = milkQuantity;
      final double initialFatKg = (legacyMilk * rawFat) / 100.0;
      final double initialSnfKg = (legacyMilk * rawSnf) / 100.0;
      double waterReq = 0.0;
      if (targetFat > 0.0 && rawFat > targetFat) {
        final double targetVolume = initialFatKg / (targetFat / 100.0);
        waterReq = (targetVolume - legacyMilk).clamp(0.0, double.infinity);
      }
      final double legacyTotal = legacyMilk + waterReq;
      final double reqSnfKg = (legacyTotal * targetSnf) / 100.0;
      final double snfDef = (reqSnfKg - initialSnfKg).clamp(0.0, double.infinity);
      final double smpReq = snfDef > 0 ? snfDef / (effectiveSmpFactor / 100.0) : 0.0;
      final double effSugar = sugarPercent > 0.0
          ? sugarPercent
          : (targetProduct.toLowerCase().contains('lassi') ? 15.0 : (targetProduct.toLowerCase().contains('sweet') ? 12.0 : 0.0));
      final double sugarReq = effSugar > 0 ? (legacyTotal * effSugar) / 100.0 : 0.0;
      final double finalQty = legacyTotal + (sugarReq * 0.63);
      final double finFat = finalQty > 0 ? (initialFatKg / finalQty) * 100.0 : 0.0;
      final double finSnf = finalQty > 0 ? ((initialSnfKg + (smpReq * (effectiveSmpFactor / 100.0))) / finalQty) * 100.0 : 0.0;

      final List<BreakdownStep> steps = [
        BreakdownStep(
          stepTitle: 'STEP 1',
          formula: 'Initial Milk Quantity = Entered Volume',
          calculation: '${Formatters.formatSmart(legacyMilk)} Litres',
        ),
        BreakdownStep(
          stepTitle: 'STEP 2',
          formula: 'Initial Milk FAT = Tested / Lab Value',
          calculation: '${Formatters.formatPercent(rawFat)} (${Formatters.formatDecimal(initialFatKg)} Kg Fat Mass)',
        ),
        BreakdownStep(
          stepTitle: 'STEP 3',
          formula: 'Initial Milk SNF = Tested / Lab Value',
          calculation: '${Formatters.formatPercent(rawSnf)} (${Formatters.formatDecimal(initialSnfKg)} Kg SNF Mass)',
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
          formula: 'Required SMP (Kg) = (Target SNF Mass - Initial SNF Mass) ÷ SMP SNF Ratio ($effectiveSmpFactor%)',
          calculation: smpReq > 0
              ? '${Formatters.formatDecimal(smpReq)} Kg SMP'
              : '0.00 Kg (Initial SNF meets or exceeds target)',
        ),
        BreakdownStep(
          stepTitle: 'STEP 7',
          formula: 'Required Water (L) = (Initial Fat Mass ÷ Target Fat%) - Initial Milk Quantity',
          calculation: waterReq > 0
              ? '${Formatters.formatDecimal(waterReq)} Litres Water'
              : '0.00 Litres (No dilution required)',
        ),
      ];

      return StandardizationResult(
        totalBatch: legacyTotal,
        milkTaken: legacyMilk,
        presentFat: rawFat,
        presentSnf: rawSnf,
        availableFatKg: initialFatKg,
        finalFat: finFat,
        availableSnfKg: initialSnfKg,
        requiredSnfKg: reqSnfKg,
        snfDeficitKg: snfDef,
        smpRequired: smpReq,
        sugarRequired: sugarReq,
        waterRequired: waterReq,
        finalQuantity: finalQty,
        finalSnf: finSnf,
        targetFat: targetFat,
        targetSnf: targetSnf,
        sugarPercent: effSugar,
        smpFactor: effectiveSmpFactor,
        formulaVersion: formulaVersion,
        breakdownSteps: steps,
      );
    }

    double actualTotalBatch = totalBatch ?? 1700.0;
    double actualMilkTaken = milkTaken ?? 0.0;
    bool isAutoCalculatedMilk = false;
    final List<String> warnings = [];

    if (rawFat < 0 || rawSnf < 0) {
      warnings.add('Fat and SNF values cannot be negative.');
    }

    // Auto-calculate Milk Taken if not provided:
    // (remember if we didnot given how much milk we have taken then from total batch quantity
    // when you will find amount of water needed you must remember our products selected products fat snf depending on these you will need to make)
    if (actualMilkTaken <= 0.0) {
      if (rawFat > 0.0) {
        actualMilkTaken = (actualTotalBatch * targetFat) / rawFat;
        isAutoCalculatedMilk = true;
      } else {
        actualMilkTaken = actualTotalBatch;
      }
    }

    if (actualMilkTaken > actualTotalBatch) {
      warnings.add('Milk Taken (${Formatters.formatDecimal(actualMilkTaken)} L) exceeds Total Batch (${Formatters.formatDecimal(actualTotalBatch)} L).');
    }

    // 1. Milk Fat
    // Available Fat kg = Milk Taken * Present Fat % / 100
    final double availableFatKg = (actualMilkTaken * rawFat) / 100.0;
    // Final Fat % = (Fat kg / Total Batch) * 100
    final double finalFat = actualTotalBatch > 0.0 ? (availableFatKg / actualTotalBatch) * 100.0 : 0.0;

    // 2. Milk SNF
    // Available SNF kg = Milk Taken * Present SNF % / 100
    final double availableSnfKg = (actualMilkTaken * rawSnf) / 100.0;
    // Required SNF kg = Total Batch * Target SNF % / 100
    final double requiredSnfKg = (actualTotalBatch * targetSnf) / 100.0;
    // SNF Deficit = Required SNF - Available SNF
    final double rawSnfDeficit = requiredSnfKg - availableSnfKg;
    final double snfDeficitKg = rawSnfDeficit > 0.0 ? rawSnfDeficit : 0.0;

    // 3. SMP Required
    // SMP Required = SNF Deficit * 95% (or configured SMP factor)
    final double smpRequired = snfDeficitKg * (effectiveSmpFactor / 100.0);

    // 4. Sugar Calculation
    final double effectiveSugarPercent = sugarPercent > 0.0
        ? sugarPercent
        : (targetProduct.toLowerCase().contains('lassi')
            ? 15.0
            : (targetProduct.toLowerCase().contains('sweet') ? 12.0 : 0.0));
    final double sugarRequired = (actualTotalBatch * effectiveSugarPercent) / 100.0;

    // 5. Water Required
    // Water = Total Batch - (Milk Taken + SNF Deficit)
    double rawWater = 0.0;
    if (waterCalculationMethod == 'withSugarDisplacement') {
      rawWater = actualTotalBatch - (actualMilkTaken + snfDeficitKg + (sugarRequired * 0.63));
    } else {
      rawWater = actualTotalBatch - (actualMilkTaken + snfDeficitKg);
    }
    final double waterRequired = rawWater > 0.0 ? rawWater : 0.0;

    // Final SNF verification
    final double finalSnf = actualTotalBatch > 0.0
        ? ((availableSnfKg + (smpRequired * (effectiveSmpFactor / 100.0))) / actualTotalBatch) * 100.0
        : targetSnf;

    // Validation warnings
    if (rawFat < targetFat && !isAutoCalculatedMilk) {
      warnings.add('Present Milk Fat (${Formatters.formatPercent(rawFat)}) is less than Target Fat (${Formatters.formatPercent(targetFat)}). Final fat will be lower than target standard.');
    }
    if (requiredSnfKg <= availableSnfKg) {
      warnings.add('Present milk SNF (${Formatters.formatPercent(rawSnf)}) satisfies target SNF (${Formatters.formatPercent(targetSnf)}). No SMP addition required.');
    }
    if ((actualMilkTaken + snfDeficitKg) > actualTotalBatch) {
      warnings.add('Sum of Milk Taken and SNF Deficit exceeds Total Batch. Water requirement is 0 L.');
    }

    // Step-by-step breakdown
    final List<BreakdownStep> steps = [
      BreakdownStep(
        stepTitle: 'STEP 1: BATCH ALLOCATION',
        formula: 'Total Target Batch = ${Formatters.formatSmart(actualTotalBatch)} L | Milk Taken = ${Formatters.formatDecimal(actualMilkTaken)} L',
        calculation: isAutoCalculatedMilk
            ? 'Milk Taken auto-derived to hit ${Formatters.formatPercent(targetFat)} Fat: (${Formatters.formatSmart(actualTotalBatch)} × ${Formatters.formatPercent(targetFat)}) ÷ ${Formatters.formatPercent(rawFat)} = ${Formatters.formatDecimal(actualMilkTaken)} L'
            : 'Operator specified Milk Taken: ${Formatters.formatDecimal(actualMilkTaken)} Litres',
      ),
      BreakdownStep(
        stepTitle: 'STEP 2: MILK FAT MASS & FINAL FAT %',
        formula: 'Fat kg = (Milk Taken × Present Fat %) ÷ 100 | Final Fat % = (Fat kg ÷ Total Batch) × 100',
        calculation: '(${Formatters.formatDecimal(actualMilkTaken)} × ${Formatters.formatPercent(rawFat)}) ÷ 100 = ${Formatters.formatDecimal(availableFatKg)} kg Fat Available → Final Fat: ${Formatters.formatPercent(finalFat)}',
      ),
      BreakdownStep(
        stepTitle: 'STEP 3: SNF MASS BALANCE',
        formula: 'Available SNF = (Milk Taken × Present SNF %) ÷ 100 | Required SNF = (Total Batch × Target SNF %) ÷ 100',
        calculation: 'Available SNF: ${Formatters.formatDecimal(availableSnfKg)} kg | Required SNF: ${Formatters.formatDecimal(requiredSnfKg)} kg',
      ),
      BreakdownStep(
        stepTitle: 'STEP 4: SNF DEFICIT',
        formula: 'SNF Deficit = Required SNF - Available SNF',
        calculation: '${Formatters.formatDecimal(requiredSnfKg)} kg - ${Formatters.formatDecimal(availableSnfKg)} kg = ${Formatters.formatDecimal(snfDeficitKg)} kg',
        note: snfDeficitKg <= 0 ? 'No deficit detected; available SNF is sufficient' : 'Deficit to be fulfilled using SMP',
      ),
      BreakdownStep(
        stepTitle: 'STEP 5: SMP REQUIRED (${Formatters.formatDecimal(effectiveSmpFactor)}% Factor)',
        formula: 'SMP Required = SNF Deficit × (${Formatters.formatDecimal(effectiveSmpFactor)} ÷ 100)',
        calculation: '${Formatters.formatDecimal(snfDeficitKg)} × ${Formatters.formatDecimal(effectiveSmpFactor / 100.0)} = ${Formatters.formatDecimal(smpRequired)} kg SMP',
      ),
      BreakdownStep(
        stepTitle: 'STEP 6: SUGAR ADDITION (${Formatters.formatDecimal(effectiveSugarPercent)}%)',
        formula: 'Sugar = Total Batch × (${Formatters.formatDecimal(effectiveSugarPercent)} ÷ 100)',
        calculation: effectiveSugarPercent > 0
            ? '${Formatters.formatSmart(actualTotalBatch)} × ${Formatters.formatDecimal(effectiveSugarPercent / 100.0)} = ${Formatters.formatDecimal(sugarRequired)} kg Sugar'
            : '0.00 kg (Unsweetened product standard)',
      ),
      BreakdownStep(
        stepTitle: 'STEP 7: WATER REQUIRED',
        formula: 'Water = Total Batch - (Milk Taken + SNF Deficit)',
        calculation: '${Formatters.formatSmart(actualTotalBatch)} - (${Formatters.formatDecimal(actualMilkTaken)} + ${Formatters.formatDecimal(snfDeficitKg)}) = ${Formatters.formatDecimal(waterRequired)} Litres Water',
      ),
    ];

    return StandardizationResult(
      totalBatch: actualTotalBatch,
      milkTaken: actualMilkTaken,
      presentFat: rawFat,
      presentSnf: rawSnf,
      availableFatKg: availableFatKg,
      finalFat: finalFat,
      availableSnfKg: availableSnfKg,
      requiredSnfKg: requiredSnfKg,
      snfDeficitKg: snfDeficitKg,
      smpRequired: smpRequired,
      sugarRequired: sugarRequired,
      waterRequired: waterRequired,
      finalQuantity: actualTotalBatch,
      finalSnf: finalSnf,
      targetFat: targetFat,
      targetSnf: targetSnf,
      sugarPercent: effectiveSugarPercent,
      smpFactor: effectiveSmpFactor,
      isAutoCalculatedMilk: isAutoCalculatedMilk,
      warnings: warnings,
      formulaVersion: formulaVersion,
      breakdownSteps: steps,
    );
  }

  /// Reverse Calculation for operator-entered Target Fat % and Target SNF %
  static StandardizationResult reverseCalculate({
    required double totalBatch,
    double? milkTaken,
    required double presentFat,
    required double presentSnf,
    required double desiredFinalFat,
    required double desiredTargetSnf,
    double sugarPercent = 0.0,
    double smpFactor = 95.0,
    String targetProduct = 'Reverse Standardized Batch',
    String waterCalculationMethod = 'standard',
  }) {
    double actualMilk = milkTaken ?? 0.0;
    if (actualMilk <= 0.0 && presentFat > 0.0) {
      actualMilk = (totalBatch * desiredFinalFat) / presentFat;
    }

    return calculate(
      totalBatch: totalBatch,
      milkTaken: actualMilk,
      presentFat: presentFat,
      presentSnf: presentSnf,
      targetProduct: targetProduct,
      targetFat: desiredFinalFat,
      targetSnf: desiredTargetSnf,
      sugarPercent: sugarPercent,
      smpFactor: smpFactor,
      waterCalculationMethod: waterCalculationMethod,
    );
  }
}
