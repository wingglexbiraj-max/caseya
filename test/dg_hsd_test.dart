import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/dg_hsd_record.dart';
import 'package:caseya/services/dg_hsd_calculator.dart';

void main() {
  group('DG HSD Fuel & Energy Calculation Tests', () {
    test('Standard DG operational calculation with valid inputs', () {
      final result = DgHsdCalculator.calculate(
        fuelAdded: 100.0,
        startPercentage: 85.0,
        endPercentage: 60.0,
        fuelConsumption: 50.0,
        kwh: 175.0,
        runningHours: 3.5,
      );

      expect(result.percentageDrop, 25.0);
      expect(result.fuelConsumption, 50.0);
      expect(result.kwh, 175.0);
      expect(result.runningHours, 3.5);
      expect(result.consumptionPerHour, closeTo(14.2857, 0.001));
      expect(result.unitsPerLitre, 3.5); // 175 / 50 = 3.5 kWh/L
      expect(result.averageLoadKw, 50.0); // 175 / 3.5 = 50 kW
      expect(result.breakdownSteps.length, 8);
    });

    test('Zero running hours handles division by zero safely', () {
      final result = DgHsdCalculator.calculate(
        fuelAdded: 0.0,
        startPercentage: 70.0,
        endPercentage: 70.0,
        fuelConsumption: 0.0,
        kwh: 0.0,
        runningHours: 0.0,
      );

      expect(result.percentageDrop, 0.0);
      expect(result.consumptionPerHour, 0.0);
      expect(result.unitsPerLitre, 0.0);
      expect(result.averageLoadKw, 0.0);
    });

    test('Zero fuel consumption handles units per litre safely', () {
      final result = DgHsdCalculator.calculate(
        fuelAdded: 0.0,
        startPercentage: 50.0,
        endPercentage: 50.0,
        fuelConsumption: 0.0,
        kwh: 100.0,
        runningHours: 2.0,
      );

      expect(result.unitsPerLitre, 0.0);
      expect(result.consumptionPerHour, 0.0);
      expect(result.averageLoadKw, 50.0);
    });
  });

  group('DgHsdRecord Model Serialization Tests', () {
    test('toJson and fromJson preserves all fields accurately', () {
      final now = DateTime.now();
      final record = DgHsdRecord(
        recordId: 'DG-TEST-001',
        date: '2026-09-29',
        time: '11:30 AM',
        shift: 'Shift A (06:00 - 14:00)',
        employeeId: 'EMP-001',
        employeeName: 'Biraj Goswami',
        fuelAdded: 150.0,
        startPercentage: 90.0,
        endPercentage: 72.0,
        percentageDrop: 18.0,
        fuelConsumption: 55.0,
        kwh: 192.5,
        runningHours: 4.0,
        consumptionPerHour: 13.75,
        unitsPerLitre: 3.5,
        remarks: 'DG ran smoothly for pasteurization run',
        createdAt: now,
        updatedAt: now,
      );

      final json = record.toJson();
      final fromJson = DgHsdRecord.fromJson(json);

      expect(fromJson.recordId, 'DG-TEST-001');
      expect(fromJson.date, '2026-09-29');
      expect(fromJson.shift, 'Shift A (06:00 - 14:00)');
      expect(fromJson.fuelAdded, 150.0);
      expect(fromJson.startPercentage, 90.0);
      expect(fromJson.endPercentage, 72.0);
      expect(fromJson.percentageDrop, 18.0);
      expect(fromJson.fuelConsumption, 55.0);
      expect(fromJson.kwh, 192.5);
      expect(fromJson.runningHours, 4.0);
      expect(fromJson.consumptionPerHour, 13.75);
      expect(fromJson.unitsPerLitre, 3.5);
      expect(fromJson.remarks, 'DG ran smoothly for pasteurization run');
    });
  });

  group('DG Fuel Tank Fuel-Level & Capacity (380 L) Calculation Tests', () {
    test('DG Tank constant capacity is configured at 380 litres', () {
      expect(DgHsdCalculator.DG_TANK_CAPACITY, 380.0);
      expect(DgHsdCalculator.dgTankCapacity, 380.0);
    });

    test('Exact User Example: Opening 25%, Top-up 100 L, Closing 15%', () {
      // Opening: 25% * 380 = 95 L
      // Top-up: 100 L -> After top-up = 195 L (51.32%)
      // Closing: 15% * 380 = 57 L
      // Consumed: 95 + 100 - 57 = 138 L
      final result = DgHsdCalculator.calculate(
        fuelAdded: 100.0,
        startPercentage: 25.0,
        endPercentage: 15.0,
        kwh: 483.0,
        runningHours: 8.0,
      );

      expect(result.openingLitres, 95.0);
      expect(result.topUpLitres, 100.0);
      expect(result.fuelAfterTopUp, 195.0);
      expect(result.percentageAfterTopUp, closeTo(51.3157, 0.01)); // 51.32%
      expect(result.closingLitres, 57.0);
      expect(result.consumedLitres, 138.0);
      expect(result.fuelConsumption, 0.0);
      expect(result.exceedsCapacity, isFalse);
      expect(result.validationError, isNull);
      expect(result.isValid, isTrue);
    });

    test('Dynamic calculation: Opening 50%, Top-up 0 L, Closing 20%', () {
      // Opening: 50% * 380 = 190 L
      // Top-up: 0 L -> After top-up = 190 L (50%)
      // Closing: 20% * 380 = 76 L
      // Consumed: 190 + 0 - 76 = 114 L
      final result = DgHsdCalculator.calculate(
        fuelAdded: 0.0,
        startPercentage: 50.0,
        endPercentage: 20.0,
        kwh: 380.0,
        runningHours: 6.0,
      );

      expect(result.openingLitres, 190.0);
      expect(result.topUpLitres, 0.0);
      expect(result.fuelAfterTopUp, 190.0);
      expect(result.percentageAfterTopUp, 50.0);
      expect(result.closingLitres, 76.0);
      expect(result.consumedLitres, 114.0);
      expect(result.fuelConsumption, 0.0);
      expect(result.exceedsCapacity, isFalse);
    });

    test('Validation: Fuel after top-up exceeding 380 L flags error', () {
      // Opening 80% (304 L) + Top-up 100 L = 404 L > 380 L
      final result = DgHsdCalculator.calculate(
        fuelAdded: 100.0,
        startPercentage: 80.0,
        endPercentage: 40.0,
        kwh: 100.0,
        runningHours: 2.0,
      );

      expect(result.exceedsCapacity, isTrue);
      expect(result.isValid, isFalse);
      expect(result.validationError, contains('exceeds DG tank capacity of 380 L'));
    });

    test('Validation: Negative top-up litres flags error', () {
      final result = DgHsdCalculator.calculate(
        fuelAdded: -20.0,
        startPercentage: 50.0,
        endPercentage: 30.0,
        kwh: 100.0,
        runningHours: 2.0,
      );

      expect(result.validationError, contains('Top-up litres cannot be negative'));
      expect(result.isValid, isFalse);
    });

    test('Validation: Percentage outside 0-100% flags error', () {
      final invalidStart = DgHsdCalculator.calculate(
        fuelAdded: 0.0,
        startPercentage: 110.0,
        endPercentage: 30.0,
        kwh: 100.0,
        runningHours: 2.0,
      );
      expect(invalidStart.validationError, contains('Opening fuel level must be between 0% and 100%'));
      expect(invalidStart.isValid, isFalse);

      final invalidEnd = DgHsdCalculator.calculate(
        fuelAdded: 0.0,
        startPercentage: 50.0,
        endPercentage: -5.0,
        kwh: 100.0,
        runningHours: 2.0,
      );
      expect(invalidEnd.validationError, contains('Closing fuel level must be between 0% and 100%'));
      expect(invalidEnd.isValid, isFalse);
    });
  });
}
