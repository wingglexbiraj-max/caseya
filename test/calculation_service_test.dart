import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/product_model.dart';
import 'package:caseya/services/calculation_service.dart';

void main() {
  group('Product Calculator Service Tests - 6 Manufactured Products', () {
    const s400 = ProductModel(
      productId: '9900010',
      productName: 'Sweet Curd Cup 400g (S400)',
      itemCode: '9900010',
      shortCode: 'S400',
      category: 'Curd',
      unit: 'g',
      packSize: 400,
      packSizeDisplay: '400 g',
      piecesPerCrate: 15,
      perCrateQty: 6.0,
      perCrateQtyGrams: 6000.0,
      perCrateDisplay: '6.0 kg (6000.0 g)',
      pricePerPiece: 55.0,
      shelfLife: '12 Days',
      allowedInputModes: ['Pieces', 'Crates', 'Kg'],
    );

    const p80 = ProductModel(
      productId: '9900026',
      productName: 'Plain Curd Cup 80g (P80)',
      itemCode: '9900026',
      shortCode: 'P80',
      category: 'Curd',
      unit: 'g',
      packSize: 80,
      packSizeDisplay: '80 g',
      piecesPerCrate: 60,
      perCrateQty: 4.8,
      perCrateQtyGrams: 4800.0,
      perCrateDisplay: '4.8 kg (4800.0 g)',
      pricePerPiece: 15.0,
      shelfLife: '12 Days',
      allowedInputModes: ['Pieces', 'Crates', 'Kg'],
    );

    const p400 = ProductModel(
      productId: '9900013',
      productName: 'Plain Curd Cup 400g (P400)',
      itemCode: '9900013',
      shortCode: 'P400',
      category: 'Curd',
      unit: 'g',
      packSize: 400,
      packSizeDisplay: '400 g',
      piecesPerCrate: 15,
      perCrateQty: 6.0,
      perCrateQtyGrams: 6000.0,
      perCrateDisplay: '6.0 kg (6000.0 g)',
      pricePerPiece: 55.0,
      shelfLife: '12 Days',
      allowedInputModes: ['Pieces', 'Crates', 'Kg'],
    );

    const pl200 = ProductModel(
      productId: '9900007',
      productName: 'Purabi Lassi 200 ml (PL200)',
      itemCode: '9900007',
      shortCode: 'PL200',
      category: 'Fermented',
      unit: 'ml',
      packSize: 200,
      packSizeDisplay: '200 ml',
      piecesPerCrate: 30,
      perCrateQty: 6.0,
      perCrateQtyGrams: 6000.0,
      perCrateDisplay: '6.0 L (6000.0 ml)',
      pricePerPiece: 20.0,
      shelfLife: '7 Days',
      allowedInputModes: ['Pieces', 'Crates', 'Litres'],
    );

    const cp400 = ProductModel(
      productId: 'CP400',
      productName: 'Curd Pouch 400 g (CP400)',
      itemCode: 'NA',
      shortCode: 'CP400',
      category: 'Curd',
      unit: 'g',
      packSize: 400,
      packSizeDisplay: '400 g',
      piecesPerCrate: 30,
      perCrateQty: 12.0,
      perCrateQtyGrams: 12000.0,
      perCrateDisplay: '12.0 kg (12000.0 g)',
      pricePerPiece: 35.0,
      shelfLife: '12 Days',
      allowedInputModes: ['Pieces', 'Crates', 'Kg'],
    );

    const cp1000 = ProductModel(
      productId: 'CP1000',
      productName: 'Curd Pouch 1 kg (CP1000)',
      itemCode: 'NA',
      shortCode: 'CP1000',
      category: 'Curd',
      unit: 'g',
      packSize: 1000,
      packSizeDisplay: '1 kg (1000 g)',
      piecesPerCrate: 12,
      perCrateQty: 12.0,
      perCrateQtyGrams: 12000.0,
      perCrateDisplay: '12.0 kg (12000.0 g)',
      pricePerPiece: 75.0,
      shelfLife: '12 Days',
      allowedInputModes: ['Pieces', 'Crates', 'Kg'],
    );

    test('1. Sweet Curd Cup 400g (S400) - Crates Mode (150 Crates)', () {
      final res = CalculationService.calculateProduct(
        product: s400,
        inputMode: 'Crates',
        inputQuantity: 150.0,
      );

      expect(res.productNameWithQuantity, 'Sweet Curd Cup 400g (S400) — 150 Crates');
      expect(res.pieces, 2250);
      expect(res.crates, 150.0);
      expect(res.packingNeeded, '150 Crates');
      expect(res.totalQuantity, 900.0);
      expect(res.totalPrice, 123750.0);
      expect(res.totalPriceDisplay, '₹123,750');
    });

    test('2. Plain Curd Cup 80g (P80) - Pieces Mode (600 Pieces)', () {
      final res = CalculationService.calculateProduct(
        product: p80,
        inputMode: 'Pieces',
        inputQuantity: 600.0,
      );

      expect(res.pieces, 600);
      expect(res.crates, 10.0);
      expect(res.totalQuantity, 48.0);
      expect(res.totalPrice, 9000.0);
      expect(res.totalPriceDisplay, '₹9,000');
    });

    test('3. Plain Curd Cup 400g (P400) - Crates Mode (20 Crates)', () {
      final res = CalculationService.calculateProduct(
        product: p400,
        inputMode: 'Crates',
        inputQuantity: 20.0,
      );

      expect(res.pieces, 300); // 20 * 15
      expect(res.crates, 20.0);
      expect(res.totalQuantity, 120.0); // 300 * 0.4 kg
      expect(res.totalPrice, 16500.0); // 300 * 55.0
      expect(res.totalPriceDisplay, '₹16,500');
    });

    test('4. Purabi Lassi 200 ml (PL200) - Litres Mode (600 Litres)', () {
      final res = CalculationService.calculateProduct(
        product: pl200,
        inputMode: 'Litres',
        inputQuantity: 600.0,
      );

      expect(res.pieces, 3000);
      expect(res.crates, 100.0);
      expect(res.totalQuantity, 600.0);
      expect(res.totalPrice, 60000.0);
      expect(res.totalPriceDisplay, '₹60,000');
    });

    test('5. Curd Pouch 400 g (CP400) - Kg Mode (120 Kg)', () {
      final res = CalculationService.calculateProduct(
        product: cp400,
        inputMode: 'Kg',
        inputQuantity: 120.0,
      );

      expect(res.pieces, 300); // 120 / 0.4
      expect(res.crates, 10.0); // 300 / 30
      expect(res.totalQuantity, 120.0);
      expect(res.totalPrice, 10500.0); // 300 * 35.0
      expect(res.totalPriceDisplay, '₹10,500');
    });

    test('6. Curd Pouch 1 kg (CP1000) - Crates Mode (10 Crates)', () {
      final res = CalculationService.calculateProduct(
        product: cp1000,
        inputMode: 'Crates',
        inputQuantity: 10.0,
      );

      expect(res.pieces, 120); // 10 * 12
      expect(res.crates, 10.0);
      expect(res.totalQuantity, 120.0); // 120 * 1.0 kg
      expect(res.totalPrice, 9000.0); // 120 * 75.0
      expect(res.totalPriceDisplay, '₹9,000');
    });
  });
}
