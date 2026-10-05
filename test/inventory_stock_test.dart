import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/operations_models.dart';
import 'package:caseya/models/standardization_record.dart';
import 'package:caseya/models/batch_record_model.dart';
import 'package:caseya/services/inventory_stock_service.dart';

void main() {
  group('Inventory Stock & Production Register Connection Tests', () {
    test('1. Lassi 20 cups deduction deducts Lassi Cup 200ml and Foil 80gm (Blue)', () {
      final records = [
        const ProductionRecord(
          recordId: 'PR-TEST-001',
          date: '2026-10-05',
          time: '10:00 AM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900007',
          productName: 'Lassi 200 ml',
          batchNo: 'B-LASSI-01',
          quantityProduced: 4.0, // 4 Litres = 20 cups (0.2 L / cup)
          unit: 'Litres',
          cratesProduced: 0.67,
          piecesProduced: 20,
        ),
      ];

      final result = InventoryStockService.calculateInventoryStock(
        productionRecords: records,
        standardizationRecords: [],
        batchRecords: [],
      );

      final lassiCup = result.items.firstWhere((i) => i.id == 'cup_lassi_200');
      final blueFoil80 = result.items.firstWhere((i) => i.id == 'foil_blue_80');

      // Baseline: 82,500 pcs - 20 = 82,480 pcs
      expect(lassiCup.consumedQty, equals(20.0));
      expect(lassiCup.remainingQty, equals(82480.0));

      // Baseline Foil Blue 80: 2,608,200 lids - 20 = 2,608,180 lids
      expect(blueFoil80.consumedQty, equals(20.0));
      expect(blueFoil80.remainingQty, equals(2608200.0 - 20.0));

      expect(result.totalCupsUsed, equals(20));
      expect(result.totalFoilsUsed, equals(20));
    });

    test('2. Sweet Curd S80 deducts S80 cup and Foil 80gm (Pink)', () {
      final records = [
        const ProductionRecord(
          recordId: 'PR-TEST-002',
          date: '2026-10-05',
          time: '11:00 AM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900025',
          productName: 'Sweet Curd Cup (S80)',
          batchNo: 'B-S80-01',
          quantityProduced: 4.8,
          unit: 'Kg',
          cratesProduced: 1.0,
          piecesProduced: 60,
        ),
      ];

      final result = InventoryStockService.calculateInventoryStock(
        productionRecords: records,
        standardizationRecords: [],
        batchRecords: [],
      );

      final s80Cup = result.items.firstWhere((i) => i.id == 'cup_s80');
      final pinkFoil80 = result.items.firstWhere((i) => i.id == 'foil_pink_80');

      // Baseline: 52,800 pcs - 60 = 52,740 pcs
      expect(s80Cup.consumedQty, equals(60.0));
      expect(s80Cup.remainingQty, equals(52740.0));

      // Baseline Foil Pink 80: 831,600 lids - 60 = 831,540 lids
      expect(pinkFoil80.consumedQty, equals(60.0));
      expect(pinkFoil80.remainingQty, equals(831540.0));
    });

    test('3. Sweet Curd S200 and S400 deduct Foil 200/400gm (Pink)', () {
      final records = [
        const ProductionRecord(
          recordId: 'PR-TEST-003',
          date: '2026-10-05',
          time: '12:00 PM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900011',
          productName: 'Sweet Curd Cup (S200)',
          batchNo: 'B-S200-01',
          quantityProduced: 6.0,
          unit: 'Kg',
          cratesProduced: 1.0,
          piecesProduced: 30,
        ),
        const ProductionRecord(
          recordId: 'PR-TEST-004',
          date: '2026-10-05',
          time: '01:00 PM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900010',
          productName: 'Sweet Curd Cup (S400)',
          batchNo: 'B-S400-01',
          quantityProduced: 6.0,
          unit: 'Kg',
          cratesProduced: 1.0,
          piecesProduced: 15,
        ),
      ];

      final result = InventoryStockService.calculateInventoryStock(
        productionRecords: records,
        standardizationRecords: [],
        batchRecords: [],
      );

      final s200Cup = result.items.firstWhere((i) => i.id == 'cup_s200');
      final s400Cup = result.items.firstWhere((i) => i.id == 'cup_s400');
      final pinkFoil200_400 = result.items.firstWhere((i) => i.id == 'foil_pink_200_400');

      expect(s200Cup.consumedQty, equals(30.0));
      expect(s400Cup.consumedQty, equals(15.0));

      // Pink 200/400 foil consumed = 30 (from S200) + 15 (from S400) = 45 lids
      expect(pinkFoil200_400.consumedQty, equals(45.0));
      expect(pinkFoil200_400.remainingQty, equals(302400.0 - 45.0));
    });

    test('4. Plain Curd P80 shares Foil 80gm (Blue) with Lassi 200ml', () {
      final records = [
        const ProductionRecord(
          recordId: 'PR-TEST-005',
          date: '2026-10-05',
          time: '02:00 PM',
          shift: 'Shift B',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900026',
          productName: 'Plain Curd Cup (P80)',
          batchNo: 'B-P80-01',
          quantityProduced: 4.8,
          unit: 'Kg',
          cratesProduced: 1.0,
          piecesProduced: 60,
        ),
        const ProductionRecord(
          recordId: 'PR-TEST-006',
          date: '2026-10-05',
          time: '02:30 PM',
          shift: 'Shift B',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900007',
          productName: 'Lassi 200 ml',
          batchNo: 'B-LASSI-02',
          quantityProduced: 8.0,
          unit: 'Litres',
          cratesProduced: 1.33,
          piecesProduced: 40,
        ),
      ];

      final result = InventoryStockService.calculateInventoryStock(
        productionRecords: records,
        standardizationRecords: [],
        batchRecords: [],
      );

      final p80Cup = result.items.firstWhere((i) => i.id == 'cup_p80');
      final lassiCup = result.items.firstWhere((i) => i.id == 'cup_lassi_200');
      final blueFoil80 = result.items.firstWhere((i) => i.id == 'foil_blue_80');

      expect(p80Cup.consumedQty, equals(60.0));
      expect(lassiCup.consumedQty, equals(40.0));

      // Foil 80gm (Blue) is shared: 60 (P80) + 40 (Lassi) = 100 lids
      expect(blueFoil80.consumedQty, equals(100.0));
      expect(blueFoil80.remainingQty, equals(2608200.0 - 100.0));
    });

    test('5. Plain Curd P200 and P400 deduct Foil 200/400gm (Blue)', () {
      final records = [
        const ProductionRecord(
          recordId: 'PR-TEST-007',
          date: '2026-10-05',
          time: '03:00 PM',
          shift: 'Shift B',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: 'P200',
          productName: 'Plain Curd Cup (P200)',
          batchNo: 'B-P200-01',
          quantityProduced: 6.0,
          unit: 'Kg',
          cratesProduced: 1.0,
          piecesProduced: 30,
        ),
        const ProductionRecord(
          recordId: 'PR-TEST-008',
          date: '2026-10-05',
          time: '03:30 PM',
          shift: 'Shift B',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900013',
          productName: 'Plain Curd Cup (P400)',
          batchNo: 'B-P400-01',
          quantityProduced: 6.0,
          unit: 'Kg',
          cratesProduced: 1.0,
          piecesProduced: 15,
        ),
      ];

      final result = InventoryStockService.calculateInventoryStock(
        productionRecords: records,
        standardizationRecords: [],
        batchRecords: [],
      );

      final p200Cup = result.items.firstWhere((i) => i.id == 'cup_p200');
      final p400Cup = result.items.firstWhere((i) => i.id == 'cup_p400');
      final blueFoil200_400 = result.items.firstWhere((i) => i.id == 'foil_blue_200_400');

      expect(p200Cup.consumedQty, equals(30.0));
      expect(p400Cup.consumedQty, equals(15.0));

      // Foil 200/400gm (Blue): 30 + 15 = 45 lids
      expect(blueFoil200_400.consumedQty, equals(45.0));
      expect(blueFoil200_400.remainingQty, equals(882000.0 - 45.0));
    });

    test('6. Sugar & SMP deductions from Milk Standardization with dual cross-verification', () {
      final stdRecords = [
        StandardizationRecord(
          recordId: 'STD-20261005-01',
          date: '2026-10-05',
          time: '09:00 AM',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          totalBatchRequired: 1700.0,
          inputMilkQuantity: 1400.0,
          inputFat: 4.3,
          inputSnf: 8.33,
          targetProductId: 'sweet_curd',
          targetProductName: 'Sweet Curd',
          targetFat: 3.5,
          targetSnf: 10.0,
          waterRequired: 0.0,
          smpRequired: 53.4, // 53.4 kg SMP
          sugarRequired: 204.0, // 204.0 kg Sugar
          finalQuantity: 1700.0,
          finalFat: 3.5,
          finalSnf: 10.0,
          calculationFormulaVersion: 'v2.0',
          createdAt: DateTime.now(),
        ),
      ];

      // Same batch entered in Daily Batch Making (Cross-verification scenario)
      final batchRecords = [
        BatchRecordModel(
          id: 'STD-20261005-01',
          productionDate: '2026-10-05',
          productId: 'sweet_curd',
          productName: 'Sweet Curd',
          batchNumber: 'STD-20261005-01',
          batchQuantity: 1700.0,
          batchUnit: 'L',
          ingredients: [
            const BatchIngredientModel(
              id: 'ING-1',
              batchId: 'STD-20261005-01',
              ingredientName: 'Sugar',
              quantity: 204.0,
              unit: 'kg',
            ),
            const BatchIngredientModel(
              id: 'ING-2',
              batchId: 'STD-20261005-01',
              ingredientName: 'SMP',
              quantity: 53.4,
              unit: 'kg',
            ),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      // Production entry also referencing this standardization record
      final prodRecords = [
        const ProductionRecord(
          recordId: 'PR-TEST-009',
          date: '2026-10-05',
          time: '11:00 AM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900010',
          productName: 'Sweet Curd Cup (S400)',
          batchNo: 'B-SC-01',
          quantityProduced: 1700.0,
          unit: 'Kg',
          cratesProduced: 283.33,
          piecesProduced: 4250,
          standardizationRecordId: 'STD-20261005-01',
        ),
      ];

      final result = InventoryStockService.calculateInventoryStock(
        productionRecords: prodRecords,
        standardizationRecords: stdRecords,
        batchRecords: batchRecords,
      );

      final sugarItem = result.items.firstWhere((i) => i.id == 'ingredient_sugar');
      final smpItem = result.items.firstWhere((i) => i.id == 'ingredient_smp');

      // Crucial: Sugar and SMP must NOT be double-counted!
      // Exactly 204.0 kg Sugar deducted once:
      expect(result.totalSugarUsedKg, equals(204.0));
      expect(sugarItem.consumedQty, equals(204.0));
      expect(sugarItem.remainingQty, equals(950.0 - 204.0)); // 746 kg
      expect(sugarItem.remainingPackages, equals((950.0 - 204.0) / 50.0)); // 14.92 bags

      // Exactly 53.4 kg SMP deducted once:
      expect(result.totalSmpUsedKg, equals(53.4));
      expect(smpItem.consumedQty, equals(53.4));
      expect(smpItem.remainingQty, equals(1425.0 - 53.4)); // 1371.6 kg
      expect(smpItem.remainingPackages, equals((1425.0 - 53.4) / 25.0)); // 54.864 bags

      // Cross-verification detected in ledger
      final sugarLedgerEntry = result.deductionLedger.firstWhere((l) => l.inventoryItemId == 'ingredient_sugar');
      expect(sugarLedgerEntry.isCrossVerified, isTrue);
    });

    test('7. Curd cups (S80, S200, S400, P80, P200, P400) minus 1 Wooden Spoon per cup (100 cups = 100 spoons)', () {
      final records = [
        const ProductionRecord(
          recordId: 'PR-TEST-SPOON-01',
          date: '2026-10-05',
          time: '04:00 PM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900025',
          productName: 'Sweet Curd Cup (S80)',
          batchNo: 'B-SC-100',
          quantityProduced: 8.0,
          unit: 'Kg',
          cratesProduced: 1.67,
          piecesProduced: 100, // 100 cups produced
        ),
      ];

      final result = InventoryStockService.calculateInventoryStock(
        productionRecords: records,
        standardizationRecords: [],
        batchRecords: [],
      );

      final spoonItem = result.items.firstWhere((i) => i.id == 'serving_wooden_spoon');

      // Baseline: 126,000 pcs (7 boxes @ 18,000 pcs/box) - 100 spoons = 125,900 pcs
      expect(result.totalSpoonsUsed, equals(100));
      expect(spoonItem.consumedQty, equals(100.0));
      expect(spoonItem.remainingQty, equals(125900.0));
      expect(spoonItem.remainingPackages, equals(125900.0 / 18000.0));

      final spoonLedger = result.deductionLedger.firstWhere((l) => l.inventoryItemId == 'serving_wooden_spoon');
      expect(spoonLedger.quantityDeducted, equals(100.0));
      expect(spoonLedger.unit, equals('pcs'));
    });
  });
}
