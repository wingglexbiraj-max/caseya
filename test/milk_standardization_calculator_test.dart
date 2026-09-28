import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/services/milk_standardization_calculator.dart';

void main() {
  group('Milk Standardization Target Products Metadata', () {
    test('Verify all 6 standardized products match exact dairy plant specifications', () {
      final products = MilkStandardizationCalculator.standardizationProducts;
      expect(products.length, 6);

      // 1. std milk: target fat 4.5, target snf 8.5, sugar NA, shelf life 2 days
      final stdMilk = products.firstWhere((p) => p.productName == 'std milk');
      expect(stdMilk.targetFat, 4.5);
      expect(stdMilk.targetSnf, 8.5);
      expect(stdMilk.targetSugar, isNull);
      expect(stdMilk.targetSugarDisplay, 'NA');
      expect(stdMilk.shelfLife, '2 Days');

      // 2. army milk: target fat 3.5, target snf 8.5, sugar NA, shelf life 2 days
      final armyMilk = products.firstWhere((p) => p.productName == 'army milk');
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

      // 4. plain curd pouch: target fat 3.0, target snf 11, sugar NA, shelf life 12 days
      final plainCurdPouch = products.firstWhere((p) => p.productName == 'plain curd pouch');
      expect(plainCurdPouch.targetFat, 3.0);
      expect(plainCurdPouch.targetSnf, 11.0);
      expect(plainCurdPouch.targetSugar, isNull);
      expect(plainCurdPouch.targetSugarDisplay, 'NA');
      expect(plainCurdPouch.shelfLife, '12 Days');

      // 5. sweetened curd: target fat 3, target snf 14, sugar 12%, shelf life 12 days
      final sweetenedCurd = products.firstWhere((p) => p.productName == 'sweetened curd');
      expect(sweetenedCurd.targetFat, 3.0);
      expect(sweetenedCurd.targetSnf, 14.0);
      expect(sweetenedCurd.targetSugar, 12.0);
      expect(sweetenedCurd.targetSugarDisplay, '12%');
      expect(sweetenedCurd.shelfLife, '12 Days');

      // 6. lassi: target fat 1.5, target snf 7.0, sugar 15%, shelf life 7 days
      final lassi = products.firstWhere((p) => p.productName == 'lassi');
      expect(lassi.targetFat, 1.5);
      expect(lassi.targetSnf, 7.0);
      expect(lassi.targetSugar, 15.0);
      expect(lassi.targetSugarDisplay, '15%');
      expect(lassi.shelfLife, '7 Days');
    });
  });

  group('Milk Standardization Calculator Engine', () {
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

      // Water required to dilute Fat from 4.5% to 1.5%:
      // Initial Fat = 5000 * 0.045 = 225 Kg
      // Target Vol for Fat = 225 / 0.015 = 15000 L
      // Water = 15000 - 5000 = 10000 L
      expect(res.waterRequired, 10000.0);
      expect(res.sugarRequired, greaterThan(0.0));
      expect(res.finalQuantity, greaterThan(5000.0));
      expect(res.breakdownSteps.length, greaterThanOrEqualTo(8));
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
      expect(res.smpRequired, greaterThan(0.0)); // To reach 14.0% SNF
      expect(res.sugarRequired, greaterThan(0.0)); // 12% sugar
      expect(res.breakdownSteps.length, greaterThanOrEqualTo(8));
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
