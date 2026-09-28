import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/services/milk_standardization_calculator.dart';

void main() {
  group('Milk Standardization Target Products Metadata', () {
    test('Verify standard products exist and match exact dairy plant specifications', () {
      final products = MilkStandardizationCalculator.standardizationProducts;
      expect(products.length, greaterThanOrEqualTo(6));

      // 1. std milk: target fat 4.5, target snf 8.5, sugar NA, shelf life 2 days
      final stdMilk = products.firstWhere((p) => p.productName == 'std milk');
      expect(stdMilk.targetFat, 4.5);
      expect(stdMilk.targetSnf, 8.5);
      expect(stdMilk.targetSugar, isNull);
      expect(stdMilk.targetSugarDisplay, 'NA');
      expect(stdMilk.shelfLife, '2 Days');

      // 2. army milk (sm+): target fat 3.5, target snf 8.5, sugar NA, shelf life 2 days
      final armyMilk = products.firstWhere((p) => p.productName == 'army milk (sm+)');
      expect(armyMilk.targetFat, 3.5);
      expect(armyMilk.targetSnf, 8.5);
      expect(armyMilk.targetSugar, isNull);
      expect(armyMilk.targetSugarDisplay, 'NA');
      expect(armyMilk.shelfLife, '2 Days');

      // 3. plain curd cup: target fat 3.0, target snf 14, sugar NA, shelf life 12 days
      final plainCurdCup = products.firstWhere((p) => p.productName == 'plain curd cup');
      expect(plainCurdCup.targetFat, 3.0);
      expect(plainCurdCup.targetSnf, 14.0);
      expect(plainCurdCup.targetSugar, isNull);
      expect(plainCurdCup.targetSugarDisplay, 'NA');
      expect(plainCurdCup.shelfLife, '12 Days');

      // 4. plain pouch curd: target fat 3.0, target snf 11, sugar NA, shelf life 12 days
      final plainCurdPouch = products.firstWhere((p) => p.productName == 'plain pouch curd');
      expect(plainCurdPouch.targetFat, 3.0);
      expect(plainCurdPouch.targetSnf, 11.0);
      expect(plainCurdPouch.targetSugar, isNull);
      expect(plainCurdPouch.targetSugarDisplay, 'NA');
      expect(plainCurdPouch.shelfLife, '12 Days');

      // 5. sweet curd: target fat 3, target snf 14, sugar 12%, shelf life 12 days
      final sweetCurd = products.firstWhere((p) => p.productName == 'sweet curd');
      expect(sweetCurd.targetFat, 3.0);
      expect(sweetCurd.targetSnf, 14.0);
      expect(sweetCurd.targetSugar, 12.0);
      expect(sweetCurd.targetSugarDisplay, '12%');
      expect(sweetCurd.shelfLife, '12 Days');

      // 6. lassi: target fat 1.5, target snf 7.0, sugar 15%, shelf life 7 days
      final lassi = products.firstWhere((p) => p.productName == 'lassi');
      expect(lassi.targetFat, 1.5);
      expect(lassi.targetSnf, 7.0);
      expect(lassi.targetSugar, 15.0);
      expect(lassi.targetSugarDisplay, '15%');
      expect(lassi.shelfLife, '7 Days');
    });
  });

  group('Milk Standardization Batch Formulation Engine (Official User Specification)', () {
    test('Official Dairy Plant Specification Example: Sweet Curd 1700 L Batch', () {
      // Inputs:
      // Total Batch: 1700 L
      // Milk Taken: 1400 L
      // Present Fat: 4.3%
      // Present SNF: 8.33%
      // Target SNF: 8.5%
      // Product: Sweet Curd (Sugar 12%)
      // SMP Factor: 95%
      final res = MilkStandardizationCalculator.calculate(
        totalBatch: 1700.0,
        milkTaken: 1400.0,
        presentFat: 4.3,
        presentSnf: 8.33,
        targetProduct: 'Sweet Curd',
        targetSnf: 8.5,
        sugarPercent: 12.0,
        smpFactor: 95.0,
      );

      // 1. Milk Fat:
      // Fat kg = 1400 * 4.3 / 100 = 60.20 kg
      expect(res.availableFatKg, closeTo(60.20, 0.01));
      // Final Fat % = (60.20 / 1700) * 100 = 3.54%
      expect(res.finalFat, closeTo(3.541, 0.01));

      // 2. Milk SNF:
      // Available SNF kg = 1400 * 8.33 / 100 = 116.62 kg
      expect(res.availableSnfKg, closeTo(116.62, 0.01));
      // Required SNF kg = 1700 * 8.5 / 100 = 144.50 kg
      expect(res.requiredSnfKg, closeTo(144.50, 0.01));
      // SNF Deficit = 144.50 - 116.62 = 27.88 kg
      expect(res.snfDeficitKg, closeTo(27.88, 0.01));

      // 3. SMP Required:
      // SMP Required = 27.88 * 95 / 100 = 26.486 kg (~26.49 kg)
      expect(res.smpRequired, closeTo(26.486, 0.01));

      // 4. Sugar Calculation:
      // Sweet Curd: 1700 * 12 / 100 = 204 kg
      expect(res.sugarRequired, closeTo(204.0, 0.01));

      // 5. Water Required:
      // Water = 1700 - (1400 + 26.486) = 273.514 L (~273.51 L)
      expect(res.waterRequired, closeTo(273.514, 0.01));
      // Formulation Mass-Volume Balance Verification:
      expect(res.totalFormulatedQuantity, closeTo(1700.0, 0.01));
      expect(res.milkTaken + res.smpRequired + res.waterRequired, closeTo(1700.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
      expect(res.breakdownSteps.length, greaterThanOrEqualTo(8));
    });

    test('Sweet Curd Formulation (Target Fat: 3.0%, Target SNF: 14.0%, Sugar: 12%) on 1700 L Batch', () {
      final res = MilkStandardizationCalculator.calculate(
        totalBatch: 1700.0,
        milkTaken: 1400.0,
        presentFat: 4.3,
        presentSnf: 8.33,
        targetProduct: 'sweet curd',
        targetFat: 3.0,
        targetSnf: 14.0,
        sugarPercent: 12.0,
        smpFactor: 95.0,
      );

      // Available SNF: 1400 * 8.33 / 100 = 116.62 kg
      // Required SNF: 1700 * 14.0 / 100 = 238.00 kg
      // Deficit: 238.00 - 116.62 = 121.38 kg
      expect(res.availableSnfKg, closeTo(116.62, 0.01));
      expect(res.requiredSnfKg, closeTo(238.00, 0.01));
      expect(res.snfDeficitKg, closeTo(121.38, 0.01));

      // SMP Required = 121.38 * 95 / 100 = 115.311 kg
      expect(res.smpRequired, closeTo(115.311, 0.01));

      // Sugar Required = 1700 * 12 / 100 = 204 kg (added extra)
      expect(res.sugarRequired, closeTo(204.0, 0.01));

      // Water Required = 1700 - (1400 + 115.311) = 184.689 L (~184.69 L)
      expect(res.waterRequired, closeTo(184.689, 0.01));
      expect(res.totalFormulatedQuantity, closeTo(1700.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
    });

    test('Lassi Formulation (Target Fat: 1.5%, Target SNF: 7.0%, Sugar: 15%) on 1700 L Batch', () {
      final res = MilkStandardizationCalculator.calculate(
        totalBatch: 1700.0,
        milkTaken: 1400.0,
        presentFat: 4.3,
        presentSnf: 8.33,
        targetProduct: 'lassi',
        targetFat: 1.5,
        targetSnf: 7.0, // NOT 8.5
        sugarPercent: 15.0,
        smpFactor: 95.0,
      );

      // Required SNF: 1700 * 7.0 / 100 = 119.00 kg
      // Deficit: 119.00 - 116.62 = 2.38 kg
      expect(res.requiredSnfKg, closeTo(119.00, 0.01));
      expect(res.snfDeficitKg, closeTo(2.38, 0.01));

      // SMP Required: 2.38 * 95 / 100 = 2.261 kg
      expect(res.smpRequired, closeTo(2.261, 0.01));

      // Sugar = 1700 * 15 / 100 = 255 kg
      expect(res.sugarRequired, closeTo(255.0, 0.01));

      // Water = 1700 - (1400 + 2.261) = 297.739 L (~297.74 L)
      expect(res.waterRequired, closeTo(297.739, 0.01));
      expect(res.totalFormulatedQuantity, closeTo(1700.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
    });

    test('Plain Pouch Curd Formulation (Target Fat: 3.0%, Target SNF: 11.0%, Sugar: 0%)', () {
      final res = MilkStandardizationCalculator.calculate(
        totalBatch: 1700.0,
        milkTaken: 1400.0,
        presentFat: 4.3,
        presentSnf: 8.33,
        targetProduct: 'plain pouch curd',
        targetFat: 3.0,
        targetSnf: 11.0,
        sugarPercent: 0.0,
        smpFactor: 95.0,
      );

      // Required SNF: 1700 * 11.0 / 100 = 187.00 kg
      // Deficit: 187.00 - 116.62 = 70.38 kg
      expect(res.requiredSnfKg, closeTo(187.00, 0.01));
      expect(res.snfDeficitKg, closeTo(70.38, 0.01));
      expect(res.smpRequired, closeTo(66.861, 0.01));
      expect(res.sugarRequired, 0.0);
      // Water = 1700 - (1400 + 66.861) = 233.139 L
      expect(res.waterRequired, closeTo(233.139, 0.01));
      expect(res.totalFormulatedQuantity, closeTo(1700.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
    });

    test('Plain Curd Cup Formulation (Target Fat: 3.0%, Target SNF: 14.0%, Sugar: 0%)', () {
      final res = MilkStandardizationCalculator.calculate(
        totalBatch: 1700.0,
        milkTaken: 1400.0,
        presentFat: 4.3,
        presentSnf: 8.33,
        targetProduct: 'plain curd cup',
        targetFat: 3.0,
        targetSnf: 14.0,
        sugarPercent: 0.0,
        smpFactor: 95.0,
      );

      expect(res.requiredSnfKg, closeTo(238.00, 0.01));
      expect(res.snfDeficitKg, closeTo(121.38, 0.01));
      expect(res.smpRequired, closeTo(115.311, 0.01));
      expect(res.sugarRequired, 0.0);
      // Water = 1700 - (1400 + 115.311) = 184.689 L
      expect(res.waterRequired, closeTo(184.689, 0.01));
      expect(res.totalFormulatedQuantity, closeTo(1700.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
    });

    test('Auto-calculate Milk Taken when Milk Taken is NOT given', () {
      // (remember if we didnot given how much milk we have taken then from total batch quantity
      // when you will find amount of water needed you must remember our products selected products fat snf depending on these you will need to make
      final res = MilkStandardizationCalculator.calculate(
        totalBatch: 1700.0,
        milkTaken: null, // Not given
        presentFat: 4.3,
        presentSnf: 8.33,
        targetProduct: 'Army Milk',
        targetFat: 3.5, // Army milk target fat
        targetSnf: 8.5,
        sugarPercent: 0.0,
        smpFactor: 95.0,
      );

      // Expected Milk Taken = 1700 * 3.5 / 4.3 = 1383.72 L
      expect(res.isAutoCalculatedMilk, isTrue);
      expect(res.milkTaken, closeTo(1383.72, 0.05));
      expect(res.finalFat, closeTo(3.50, 0.01));
      expect(res.waterRequired, greaterThan(0.0));
      // Formulation Mass-Volume Balance Verification:
      expect(res.totalFormulatedQuantity, closeTo(1700.0, 0.01));
      expect(res.milkTaken + res.smpRequired + res.waterRequired, closeTo(1700.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
    });

    test('Reverse Calculation for desired Target Fat % and Target SNF %', () {
      final res = MilkStandardizationCalculator.reverseCalculate(
        totalBatch: 1700.0,
        milkTaken: 1400.0,
        presentFat: 4.3,
        presentSnf: 8.33,
        desiredFinalFat: 3.54,
        desiredTargetSnf: 8.50,
        sugarPercent: 12.0,
        smpFactor: 95.0,
      );

      expect(res.finalFat, closeTo(3.54, 0.01));
      expect(res.smpRequired, closeTo(26.49, 0.05));
      expect(res.waterRequired, closeTo(273.514, 0.05));
      expect(res.sugarRequired, closeTo(204.0, 0.01));
      expect(res.totalFormulatedQuantity, closeTo(1700.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
    });

    test('Auto-calc Reverse with only Total Batch Quantity verifies Milk + SMP + Water == Total Batch', () {
      final res = MilkStandardizationCalculator.reverseCalculate(
        totalBatch: 2500.0,
        milkTaken: null, // Only Total Batch Quantity given
        presentFat: 4.5,
        presentSnf: 8.4,
        desiredFinalFat: 3.0,
        desiredTargetSnf: 11.0,
        sugarPercent: 0.0,
        smpFactor: 95.0,
      );

      // Auto derived milk = 2500 * 3.0 / 4.5 = 1666.67 L
      expect(res.isAutoCalculatedMilk, isTrue);
      expect(res.milkTaken, closeTo(1666.67, 0.05));
      expect(res.finalFat, closeTo(3.0, 0.01));
      // Verification: Milk + SMP + Water must exactly equal 2500.0 L
      expect(res.totalFormulatedQuantity, closeTo(2500.0, 0.01));
      expect(res.isBatchQuantityVerified, isTrue);
    });
  });

  group('Milk Standardization Legacy Dilution Engine Tests', () {
    test('Standardization to Lassi (1.5% FAT / 7.0% SNF / 15% Sugar)', () {
      final res = MilkStandardizationCalculator.calculate(
        milkQuantity: 5000.0,
        milkFat: 4.5,
        milkSnf: 8.5,
        targetProduct: 'lassi',
        targetFat: 1.5,
        targetSnf: 7.0,
        sugarPercent: 15.0,
      );

      expect(res.waterRequired, 10000.0);
      expect(res.sugarRequired, greaterThan(0.0));
      expect(res.finalQuantity, greaterThan(5000.0));
      expect(res.breakdownSteps.length, greaterThanOrEqualTo(7));
    });

    test('Standardization to Sweetened Curd (3.0% FAT / 14.0% SNF / 12% Sugar)', () {
      final res = MilkStandardizationCalculator.calculate(
        milkQuantity: 1000.0,
        milkFat: 4.0,
        milkSnf: 8.5,
        targetProduct: 'sweetened curd',
        targetFat: 3.0,
        targetSnf: 14.0,
        sugarPercent: 12.0,
      );

      expect(res.waterRequired, greaterThan(0.0));
      expect(res.smpRequired, greaterThan(0.0));
      expect(res.sugarRequired, greaterThan(0.0));
      expect(res.breakdownSteps.length, greaterThanOrEqualTo(7));
    });

    test('Standardization when raw milk matches target specs (No water, No SMP)', () {
      final res = MilkStandardizationCalculator.calculate(
        milkQuantity: 2000.0,
        milkFat: 4.5,
        milkSnf: 8.5,
        targetProduct: 'std milk',
        targetFat: 4.5,
        targetSnf: 8.5,
        sugarPercent: 0.0,
      );

      expect(res.waterRequired, 0.0);
      expect(res.smpRequired, 0.0);
      expect(res.sugarRequired, 0.0);
      expect(res.finalQuantity, 2000.0);
    });
  });
}
