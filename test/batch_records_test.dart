import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/batch_record_model.dart';
import 'package:caseya/services/batch_recipe_service.dart';
import 'package:caseya/models/inventory_item_model.dart';
import 'package:caseya/models/stock_ledger_entry_model.dart';

void main() {
  group('Daily Batch Making Records Tests', () {
    test('DailyBatchSummary aggregates multi-batch ingredient consumption correctly', () {
      final batches = [
        // Batch 1: Lassi (500 L)
        BatchRecordModel(
          id: 'B1',
          productionDate: '2026-09-28',
          productId: 'LASSI',
          productName: 'Lassi',
          batchNumber: 'BT-20260928-01',
          batchQuantity: 500.0,
          batchUnit: 'L',
          ingredients: const [
            BatchIngredientModel(id: 'i1', batchId: 'B1', ingredientName: 'Milk', quantity: 300.0, unit: 'L'),
            BatchIngredientModel(id: 'i2', batchId: 'B1', ingredientName: 'Water', quantity: 200.0, unit: 'L'),
            BatchIngredientModel(id: 'i3', batchId: 'B1', ingredientName: 'SMP', quantity: 29.0, unit: 'kg'),
            BatchIngredientModel(id: 'i4', batchId: 'B1', ingredientName: 'Sugar', quantity: 46.0, unit: 'kg'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Batch 2: Curd (1000 L)
        BatchRecordModel(
          id: 'B2',
          productionDate: '2026-09-28',
          productId: 'CURD',
          productName: 'Curd',
          batchNumber: 'BT-20260928-02',
          batchQuantity: 1000.0,
          batchUnit: 'L',
          ingredients: const [
            BatchIngredientModel(id: 'i5', batchId: 'B2', ingredientName: 'Milk', quantity: 1000.0, unit: 'L'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        // Batch 3: Lassi (1000 L)
        BatchRecordModel(
          id: 'B3',
          productionDate: '2026-09-28',
          productId: 'LASSI',
          productName: 'Lassi',
          batchNumber: 'BT-20260928-03',
          batchQuantity: 1000.0,
          batchUnit: 'L',
          ingredients: const [
            BatchIngredientModel(id: 'i6', batchId: 'B3', ingredientName: 'Milk', quantity: 500.0, unit: 'L'),
            BatchIngredientModel(id: 'i7', batchId: 'B3', ingredientName: 'Water', quantity: 200.0, unit: 'L'),
            BatchIngredientModel(id: 'i8', batchId: 'B3', ingredientName: 'SMP', quantity: 29.0, unit: 'kg'),
            BatchIngredientModel(id: 'i9', batchId: 'B3', ingredientName: 'Sugar', quantity: 46.0, unit: 'kg'),
          ],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];

      final summary = DailyBatchSummary.fromBatches('2026-09-28', batches);

      // Verify overall daily metrics
      expect(summary.totalBatches, 3);
      expect(summary.totalQuantity, 2500.0);
      expect(summary.productsProduced, containsAll(['Lassi', 'Curd']));

      // Verify aggregated ingredient consumption
      // Milk: 300L + 1000L + 500L = 1800 L
      expect(summary.ingredientTotals['Milk']!['L'], 1800.0);

      // Water: 200L + 200L = 400 L
      expect(summary.ingredientTotals['Water']!['L'], 400.0);

      // SMP: 29kg + 29kg = 58 kg
      expect(summary.ingredientTotals['SMP']!['kg'], 58.0);

      // Sugar: 46kg + 46kg = 92 kg
      expect(summary.ingredientTotals['Sugar']!['kg'], 92.0);
    });

    test('BatchRecordModel serialization maintains dynamic ingredients relationship', () {
      final batch = BatchRecordModel(
        id: 'BT-TEST-01',
        productionDate: '2026-09-28',
        productId: 'LASSI',
        productName: 'Lassi',
        batchNumber: 'BT-20260928-01',
        batchQuantity: 500.0,
        batchUnit: 'L',
        shift: 'Shift A',
        operatorName: 'Biraj Goswami',
        notes: 'Test batch notes',
        ingredients: const [
          BatchIngredientModel(id: 'ING-1', batchId: 'BT-TEST-01', ingredientName: 'Milk', quantity: 300.0, unit: 'L'),
          BatchIngredientModel(id: 'ING-2', batchId: 'BT-TEST-01', ingredientName: 'Sugar', quantity: 46.0, unit: 'kg'),
        ],
        createdAt: DateTime(2026, 9, 28, 10, 0),
        updatedAt: DateTime(2026, 9, 28, 10, 0),
      );

      final json = batch.toJson();
      final restored = BatchRecordModel.fromJson(json);

      expect(restored.id, 'BT-TEST-01');
      expect(restored.productName, 'Lassi');
      expect(restored.batchQuantity, 500.0);
      expect(restored.ingredients.length, 2);
      expect(restored.ingredients.first.ingredientName, 'Milk');
      expect(restored.ingredients.first.quantity, 300.0);
      expect(restored.ingredients.first.unit, 'L');
      expect(restored.ingredients.last.ingredientName, 'Sugar');
      expect(restored.ingredients.last.quantity, 46.0);
    });

    test('BatchRecipeService provides valid standard recipes for initial products', () {
      final lassiRecipe = BatchRecipeService.getRecipeForProduct('Lassi');
      expect(lassiRecipe, isNotNull);
      expect(lassiRecipe!.ingredients.length, 4);
      expect(lassiRecipe.ingredients.map((e) => e.ingredientName), containsAll(['Milk', 'Water', 'SMP', 'Sugar']));

      final curdRecipe = BatchRecipeService.getRecipeForProduct('Curd');
      expect(curdRecipe, isNotNull);
      expect(curdRecipe!.ingredients.any((e) => e.ingredientName == 'Milk'), isTrue);

      final milkPouchRecipe = BatchRecipeService.getRecipeForProduct('Milk Pouch');
      expect(milkPouchRecipe, isNotNull);
      expect(milkPouchRecipe!.ingredients.first.ingredientName, 'Milk');
    });

    test('BatchRecordModel supports fatPercent serialization, deserialization, and copyWith', () {
      final batch = BatchRecordModel(
        id: 'BT-FAT-01',
        productionDate: '2026-10-06',
        productId: 'CURD',
        productName: 'Curd',
        batchNumber: 'BT-20261006-01',
        batchQuantity: 1000.0,
        batchUnit: 'L',
        fatPercent: 4.5,
        ingredients: const [
          BatchIngredientModel(id: 'i1', batchId: 'BT-FAT-01', ingredientName: 'SMP', quantity: 35.0, unit: 'kg'),
          BatchIngredientModel(id: 'i2', batchId: 'BT-FAT-01', ingredientName: 'Sugar', quantity: 50.0, unit: 'kg'),
        ],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final json = batch.toJson();
      expect(json['fat_percent'], 4.5);

      final restored = BatchRecordModel.fromJson(json);
      expect(restored.fatPercent, 4.5);

      final updated = restored.copyWith(fatPercent: 5.2);
      expect(updated.fatPercent, 5.2);
      expect(updated.id, 'BT-FAT-01');
    });

    test('StockLedgerCalculator guarantees continuous opening and closing balances across arbitrary months and years', () {
      const sugarItem = InventoryItemModel(
        id: 'ingredient_sugar',
        name: 'Sugar',
        category: 'Ingredients',
        baseUnit: 'kg',
        packagingUnit: 'Bags',
        itemsPerPackage: 50.0,
        initialPackages: 20.0,
        initialTotalQty: 1000.0,
        details: 'Initial sugar stock',
        icon: Icons.inventory_2_rounded,
      );

      // Dec 2025 receipts and issues
      final List<InwardStockEntry> inward2025 = [
        const InwardStockEntry(
          id: 'IN-2025-12',
          itemId: 'ingredient_sugar',
          itemName: 'Sugar',
          date: '2025-12-10',
          time: '10:00 AM',
          quantity: 500.0,
          packages: 10.0,
          unit: 'kg',
          packagingUnit: 'Bags',
          loggedBy: 'Biraj Goswami',
          notes: 'December inward arrival',
        ),
      ];

      final List<StockDeductionEntry> issues2025 = [
        const StockDeductionEntry(
          id: 'OUT-2025-12',
          date: '2025-12-20',
          time: '08:00 AM',
          source: 'Daily Batch Making',
          referenceId: 'B-DEC',
          batchNo: 'B-DEC',
          productName: 'Sweet Curd',
          inventoryItemId: 'ingredient_sugar',
          inventoryItemName: 'Sugar',
          quantityDeducted: 200.0,
          unit: 'kg',
        ),
      ];

      // Calculate Dec 2025 ledger
      final dec2025Result = StockLedgerCalculator.calculateMonthlyLedger(
        item: sugarItem,
        month: DateTime(2025, 12, 1),
        inwardLedger: inward2025,
        deductionLedger: issues2025,
      );

      expect(dec2025Result.openingStock, 1000.0);
      expect(dec2025Result.totalReceipts, 500.0);
      expect(dec2025Result.totalIssues, 200.0);
      expect(dec2025Result.closingStock, 1300.0);

      // Jan 2026 ledger: Opening stock MUST equal Dec 2025 closing stock (1300.0)
      final jan2026Result = StockLedgerCalculator.calculateMonthlyLedger(
        item: sugarItem,
        month: DateTime(2026, 1, 1),
        inwardLedger: inward2025,
        deductionLedger: issues2025,
      );

      expect(jan2026Result.openingStock, 1300.0);
      expect(jan2026Result.openingStock, dec2025Result.closingStock);

      // Day 1 previous stock equals opening stock
      expect(jan2026Result.rows.first.previousStock, 1300.0);
    });
  });
}
