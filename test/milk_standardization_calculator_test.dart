import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/services/milk_standardization_calculator.dart';

void main() {
  group('Milk Standardization Calculator Tests', () {
    test('Standardization from 3.8% FAT / 8.4% SNF to Lassi (2.5% FAT / 9.0% SNF)', () {
      final res = MilkStandardizationCalculator.calculate(
        milkQuantity: 5000.0,
        milkFat: 3.8,
        milkSnf: 8.4,
        targetProduct: 'Lassi',
        targetFat: 2.5,
        targetSnf: 9.0,
      );

      // Water required to dilute Fat from 3.8% to 2.5%:
      // Initial Fat = 5000 * 0.038 = 190 Kg
      // Target Vol for Fat = 190 / 0.025 = 7600 L
      // Water = 7600 - 5000 = 2600 L
      expect(res.waterRequired, 2600.0);

      // SMP required to raise SNF
      expect(res.smpRequired, greaterThan(0.0));
      expect(res.sugarRequired, greaterThan(0.0)); // Sweetened lassi recipe
      expect(res.finalQuantity, greaterThan(5000.0));
      expect(res.finalFat, closeTo(2.45, 0.2));
      expect(res.breakdownSteps.length, greaterThanOrEqualTo(8));
    });

    test('Standardization when raw milk already matches or exceeds target specs', () {
      final res = MilkStandardizationCalculator.calculate(
        milkQuantity: 2000.0,
        milkFat: 3.0,
        milkSnf: 8.5,
        targetProduct: 'Toned Milk',
        targetFat: 3.0,
        targetSnf: 8.5,
      );

      expect(res.waterRequired, 0.0);
      expect(res.smpRequired, 0.0);
      expect(res.finalQuantity, 2000.0);
    });
  });
}
