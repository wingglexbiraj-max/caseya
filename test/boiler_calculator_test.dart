import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/services/boiler_calculator.dart';

void main() {
  group('Boiler Fuel Consumption Calculation Tests', () {
    test('Standard example from plant specifications (500 CM to 430 CM)', () {
      // Opening: 500 CM, Closing: 430 CM, Running: 8.5 hr, Top-up: 0
      final result = BoilerCalculator.calculate(
        openingCm: 500.0,
        closingCm: 430.0,
        runningHours: 8.5,
        fuelTopUp: 0.0,
      );

      // Level difference must be 70 CM
      expect(result.levelDifferenceCm, 70.0);

      // Fuel consumption: ((500 - 430) * 900) / 70 = (70 * 900) / 70 = 900 Litres
      expect(result.calculatedLevelConsumption, 900.0);
      expect(result.netReportedConsumption, 900.0);

      // Consumption per hour: 900 / 8.5 = 105.8823...
      expect(result.consumptionPerHour, closeTo(105.88, 0.01));
    });

    test('Boiler calculation with Top-up inclusion mode', () {
      // Opening: 515 CM, Closing: 440 CM, Diff: 75 CM, Top-up: 100 L, Running: 8 hr
      final result = BoilerCalculator.calculate(
        openingCm: 515.0,
        closingCm: 440.0,
        runningHours: 8.0,
        fuelTopUp: 100.0,
        includeTopUpInNet: true,
      );

      // Level burn: (75 * 900) / 70 = 964.2857 L
      expect(result.calculatedLevelConsumption, closeTo(964.29, 0.01));

      // Net consumption: 964.2857 + 100 = 1064.2857 L
      expect(result.netReportedConsumption, closeTo(1064.29, 0.01));

      // Per hour: 1064.2857 / 8 = 133.0357 L/hr
      expect(result.consumptionPerHour, closeTo(133.04, 0.01));
    });

    test('Boiler calculation with Top-up exclusion mode', () {
      final result = BoilerCalculator.calculate(
        openingCm: 515.0,
        closingCm: 440.0,
        runningHours: 8.0,
        fuelTopUp: 100.0,
        includeTopUpInNet: false,
      );

      // Net consumption should match only level burn when top-up is excluded
      expect(result.netReportedConsumption, closeTo(964.29, 0.01));
    });

    test('Division by zero protection when running hours is zero', () {
      final result = BoilerCalculator.calculate(
        openingCm: 500.0,
        closingCm: 430.0,
        runningHours: 0.0,
        fuelTopUp: 0.0,
      );

      expect(result.calculatedLevelConsumption, 900.0);
      expect(result.consumptionPerHour, 0.0);
      expect(result.consumptionPerHour.isFinite, isTrue);
      expect(result.consumptionPerHour.isNaN, isFalse);
    });
  });
}
