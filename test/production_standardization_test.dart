import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/models/standardization_record.dart';
import 'package:caseya/providers/production_provider.dart';
import 'package:caseya/repositories/production_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Production Register & Milk Standardization Integration Tests', () {
    late ProductionRepository repo;
    late ProductionNotifier notifier;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      repo = ProductionRepository();
      notifier = ProductionNotifier(repo);
      await notifier.init();
    });

    test('findBestProductMatch maps standardization batch to correct packaging catalog product', () {
      final stdBatch = StandardizationRecord(
        recordId: 'STD-20260930-001',
        date: '2026-09-30',
        time: '10:00 AM',
        employeeId: 'EMP001',
        employeeName: 'Biraj',
        inputMilkQuantity: 500,
        inputFat: 4.5,
        inputSnf: 8.5,
        targetProductId: 'STD_MILK',
        targetProductName: 'STD Milk',
        targetFat: 4.5,
        targetSnf: 8.5,
        waterRequired: 0,
        smpRequired: 0,
        sugarRequired: 0,
        finalQuantity: 500,
        finalFat: 4.5,
        finalSnf: 8.5,
        calculationFormulaVersion: 'v2',
        createdAt: DateTime.now(),
      );

      final state = notifier.currentState;
      final matchedProduct = state.findBestProductMatch(stdBatch);
      expect(matchedProduct, isNotNull);
      expect(matchedProduct!.productName.toLowerCase(), contains('std'));
    });

    test('selectStandardizationBatch populates product, quantity, crates, and pieces', () {
      final stdBatch = StandardizationRecord(
        recordId: 'STD-20260930-002',
        date: '2026-09-30',
        time: '11:00 AM',
        employeeId: 'EMP001',
        employeeName: 'Biraj',
        inputMilkQuantity: 480,
        inputFat: 4.5,
        inputSnf: 8.5,
        targetProductId: 'STD_MILK',
        targetProductName: 'STD Milk',
        targetFat: 4.5,
        targetSnf: 8.5,
        waterRequired: 0,
        smpRequired: 0,
        sugarRequired: 0,
        finalQuantity: 480,
        finalFat: 4.5,
        finalSnf: 8.5,
        calculationFormulaVersion: 'v2',
        createdAt: DateTime.now(),
      );

      notifier.selectStandardizationBatch(stdBatch);
      final state = notifier.currentState;

      expect(state.selectedStandardizationBatch, equals(stdBatch));
      expect(state.quantity, equals(480.0));
      expect(state.pieces, greaterThan(0));
      expect(state.crates, greaterThan(0));
    });

    test('isStandardizationBatchPrepared detects if batch was recorded in production register', () async {
      final stdBatch = StandardizationRecord(
        recordId: 'STD-20260930-003',
        date: '2026-09-30',
        time: '01:00 PM',
        employeeId: 'EMP001',
        employeeName: 'Biraj',
        inputMilkQuantity: 300,
        inputFat: 4.5,
        inputSnf: 8.5,
        targetProductId: 'STD_MILK',
        targetProductName: 'STD Milk',
        targetFat: 4.5,
        targetSnf: 8.5,
        waterRequired: 0,
        smpRequired: 0,
        sugarRequired: 0,
        finalQuantity: 300,
        finalFat: 4.5,
        finalSnf: 8.5,
        calculationFormulaVersion: 'v2',
        createdAt: DateTime.now(),
      );

      // Before recording, isStandardizationBatchPrepared is false
      expect(notifier.currentState.isStandardizationBatchPrepared(stdBatch), isFalse);

      // Select batch & record production entry
      notifier.selectStandardizationBatch(stdBatch);
      final recorded = await notifier.recordProductionEntry(employeeId: 'EMP001');
      expect(recorded, isTrue);

      // Now should detect as already prepared
      expect(notifier.currentState.isStandardizationBatchPrepared(stdBatch), isTrue);
    });
  });
}
