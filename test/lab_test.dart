import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/lab_milk_test.dart';
import 'package:caseya/models/silo_model.dart';
import 'package:caseya/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LabMilkTest Model Tests', () {
    test('Serialization and deserialization', () {
      final testEntry = LabMilkTest(
        id: 'test-1',
        testDate: '2026-09-29',
        testTime: '08:35 AM',
        siloId: 'PMST',
        siloName: 'PMST',
        fatPercentage: 4.30,
        snfPercentage: 8.33,
        labUserId: 'user-1',
        labUserName: 'Lab User',
        remarks: 'Morning test',
        createdAt: DateTime.parse('2026-09-29 08:35:00'),
        updatedAt: DateTime.parse('2026-09-29 08:35:00'),
      );

      final json = testEntry.toJson();
      final restored = LabMilkTest.fromJson(json);

      expect(restored.id, 'test-1');
      expect(restored.testDate, '2026-09-29');
      expect(restored.testTime, '08:35 AM');
      expect(restored.siloId, 'PMST');
      expect(restored.fatPercentage, 4.30);
      expect(restored.snfPercentage, 8.33);
      expect(restored.labUserName, 'Lab User');
      expect(restored.remarks, 'Morning test');
    });

    test('Validation logic flags unusual or invalid values', () {
      // Valid normal reading
      final valid = LabMilkTest(
        id: '1',
        testDate: '2026-09-29',
        testTime: '08:00 AM',
        siloId: 'RMST',
        siloName: 'RMST',
        fatPercentage: 4.20,
        snfPercentage: 8.35,
        labUserId: 'u1',
        labUserName: 'Lab Person',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(valid.isFatValid, isTrue);
      expect(valid.isSnfValid, isTrue);
      expect(valid.isFatUnusual, isFalse);
      expect(valid.isSnfUnusual, isFalse);

      // Invalid zero or negative values
      final invalid = LabMilkTest(
        id: '2',
        testDate: '2026-09-29',
        testTime: '08:00 AM',
        siloId: 'RMST',
        siloName: 'RMST',
        fatPercentage: -1.0,
        snfPercentage: 0.0,
        labUserId: 'u1',
        labUserName: 'Lab Person',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(invalid.isFatValid, isFalse);
      expect(invalid.isSnfValid, isFalse);

      // Unusual high/low values
      final unusual = LabMilkTest(
        id: '3',
        testDate: '2026-09-29',
        testTime: '08:00 AM',
        siloId: 'RMST',
        siloName: 'RMST',
        fatPercentage: 12.5, // > 10.0
        snfPercentage: 6.0,  // < 7.0
        labUserId: 'u1',
        labUserName: 'Lab Person',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(unusual.isFatValid, isTrue);
      expect(unusual.isFatUnusual, isTrue);
      expect(unusual.isSnfUnusual, isTrue);
    });
  });

  group('Silo Latest Reading Logic', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
    });

    test('Latest reading picks the most recent timestamp for the specific silo on that date', () async {
      // Setup PMST readings at 08:00, 10:30, and 14:00
      final r1 = LabMilkTest(
        id: 'pmst-1',
        testDate: '2026-09-29',
        testTime: '08:00 AM',
        siloId: 'PMST',
        siloName: 'PMST',
        fatPercentage: 4.20,
        snfPercentage: 8.30,
        labUserId: 'u1',
        labUserName: 'Lab User',
        createdAt: DateTime(2026, 9, 29, 8, 0),
        updatedAt: DateTime(2026, 9, 29, 8, 0),
      );

      final r2 = LabMilkTest(
        id: 'pmst-2',
        testDate: '2026-09-29',
        testTime: '10:30 AM',
        siloId: 'PMST',
        siloName: 'PMST',
        fatPercentage: 4.30,
        snfPercentage: 8.33,
        labUserId: 'u1',
        labUserName: 'Lab User',
        createdAt: DateTime(2026, 9, 29, 10, 30),
        updatedAt: DateTime(2026, 9, 29, 10, 30),
      );

      final r3 = LabMilkTest(
        id: 'pmst-3',
        testDate: '2026-09-29',
        testTime: '02:00 PM',
        siloId: 'PMST',
        siloName: 'PMST',
        fatPercentage: 4.25,
        snfPercentage: 8.31,
        labUserId: 'u1',
        labUserName: 'Lab User',
        createdAt: DateTime(2026, 9, 29, 14, 0),
        updatedAt: DateTime(2026, 9, 29, 14, 0),
      );

      // Also an RMST reading at 15:00
      final rmst1 = LabMilkTest(
        id: 'rmst-1',
        testDate: '2026-09-29',
        testTime: '03:00 PM',
        siloId: 'RMST',
        siloName: 'RMST',
        fatPercentage: 3.90,
        snfPercentage: 8.40,
        labUserId: 'u1',
        labUserName: 'Lab User',
        createdAt: DateTime(2026, 9, 29, 15, 0),
        updatedAt: DateTime(2026, 9, 29, 15, 0),
      );

      await LocalStorageService.addLabMilkTest(r1);
      await LocalStorageService.addLabMilkTest(r2);
      await LocalStorageService.addLabMilkTest(r3);
      await LocalStorageService.addLabMilkTest(rmst1);

      // Verify that all 4 tests exist separately (no overwrites)
      final allTests = await LocalStorageService.getLabMilkTests();
      expect(allTests.where((t) => t.id.startsWith('pmst') || t.id.startsWith('rmst')).length, 4);

      // Fetch latest reading for PMST specifically
      final latestPmst = await LocalStorageService.getLatestReadingForSilo('PMST', todayDateStr: '2026-09-29');
      expect(latestPmst, isNotNull);
      expect(latestPmst!.id, 'pmst-3');
      expect(latestPmst.fatPercentage, 4.25);
      expect(latestPmst.snfPercentage, 8.31);
      expect(latestPmst.testTime, '02:00 PM');

      // Fetch latest reading for RMST specifically
      final latestRmst = await LocalStorageService.getLatestReadingForSilo('RMST', todayDateStr: '2026-09-29');
      expect(latestRmst, isNotNull);
      expect(latestRmst!.id, 'rmst-1');
      expect(latestRmst.fatPercentage, 3.90);
      expect(latestRmst.snfPercentage, 8.40);

      // Fetch latest reading for Silo 1 which has no reading on this date
      final latestSilo1 = await LocalStorageService.getLatestReadingForSilo('SILO_1', todayDateStr: '2025-01-01');
      expect(latestSilo1, isNull);
    });

    test('Configurable silos can be added and retrieved', () async {
      final silos = await LocalStorageService.getSilos();
      expect(silos.length, 2);
      expect(silos.map((s) => s.id), containsAll(['RMST', 'PMST']));

      // Add a custom silo
      const newSilo = SiloModel(
        id: 'SILO_3',
        name: 'Silo 3',
        description: 'New Storage Tank',
        capacityLitres: 40000,
      );
      await LocalStorageService.addSilo(newSilo);

      final updatedSilos = await LocalStorageService.getSilos();
      expect(updatedSilos.length, 3);
      expect(updatedSilos.any((s) => s.name == 'Silo 3'), isTrue);
    });
  });
}
