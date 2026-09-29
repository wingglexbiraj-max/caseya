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
      expect(result.breakdownSteps.length, 5);
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
}
