import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/product_model.dart';
import 'package:caseya/services/calculation_service.dart';

void main() {
  group('Product Calculator Service Tests', () {
    const milk500 = ProductModel(
      productId: 'PRD-001',
      productName: 'Purabi Plus Milk 500 ml',
      category: 'Milk',
      unit: 'ml',
      packSize: 500,
      packSizeDisplay: '500 ml',
      piecesPerCrate: 20,
      allowedInputModes: ['Pieces', 'Crates', 'Litres'],
    );

    const curd400 = ProductModel(
      productId: 'PRD-003',
      productName: 'Curd Pouch 400 g',
      category: 'Curd',
      unit: 'g',
      packSize: 400,
      packSizeDisplay: '400 g',
      piecesPerCrate: 25,
      allowedInputModes: ['Pieces', 'Crates', 'Kg'],
    );

    test('Pieces Mode calculation for Purabi Plus Milk 500 ml (3000 pieces)', () {
      final res = CalculationService.calculateProduct(
        product: milk500,
        inputMode: 'Pieces',
        inputQuantity: 3000.0,
      );

      expect(res.pieces, 3000);
      expect(res.crates, 150.0); // 3000 / 20 = 150 crates
      expect(res.volumeLitres, 1500.0); // 3000 * 0.5 L = 1500 Litres
      expect(res.breakdownSteps.length, 3);
    });

    test('Crates Mode calculation for Purabi Plus Milk 500 ml (150 crates)', () {
      final res = CalculationService.calculateProduct(
        product: milk500,
        inputMode: 'Crates',
        inputQuantity: 150.0,
      );

      expect(res.pieces, 3000);
      expect(res.crates, 150.0);
      expect(res.volumeLitres, 1500.0);
    });

    test('Litres Mode calculation for Purabi Plus Milk 500 ml (1500 Litres)', () {
      final res = CalculationService.calculateProduct(
        product: milk500,
        inputMode: 'Litres',
        inputQuantity: 1500.0,
      );

      expect(res.volumeLitres, 1500.0);
      expect(res.pieces, 3000);
      expect(res.crates, 150.0);
    });

    test('Curd Pouch 400g calculation with Kg input mode (1000 Kg)', () {
      final res = CalculationService.calculateProduct(
        product: curd400,
        inputMode: 'Kg',
        inputQuantity: 1000.0,
      );

      expect(res.weightKg, 1000.0);
      expect(res.pieces, 2500); // 1000 / 0.4 = 2500
      expect(res.crates, 100.0); // 2500 / 25 = 100 crates
    });
  });
}
