import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/batch_record_model.dart';
import 'package:caseya/services/batch_recipe_service.dart';

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
  });
}
