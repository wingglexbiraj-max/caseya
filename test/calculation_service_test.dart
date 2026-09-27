import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/product_model.dart';
import 'package:caseya/services/calculation_service.dart';

void main() {
  group('Product Calculator Service Tests', () {
    const milk500 = ProductModel(
      productId: 'PRD-001',
      productName: 'Purabi Plus Milk 500 ml',
      itemCode: '9900001',
      shortCode: 'PPM500',
      category: 'Milk',
      unit: 'ml',
      packSize: 500,
      packSizeDisplay: '500 ml',
      piecesPerCrate: 20,
      pricePerPiece: 28.0,
      allowedInputModes: ['Pieces', 'Crates', 'Litres'],
    );

    const sweetCurd400 = ProductModel(
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

    const plainCurd80 = ProductModel(
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

    const lassi200 = ProductModel(
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

    const curdPouch1000 = ProductModel(
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

    test('Sweet Curd Cup 400g (S400) - 150 Crates calculation', () {
      final res = CalculationService.calculateProduct(
        product: sweetCurd400,
        inputMode: 'Crates',
        inputQuantity: 150.0,
      );

      // Product name plus quantity
      expect(res.productNameWithQuantity, 'Sweet Curd Cup 400g (S400) — 150 Crates');
      // Total pieces required: 150 * 15 = 2250 pieces
      expect(res.pieces, 2250);
      // Packing needed: 150 Crates
      expect(res.crates, 150.0);
      expect(res.packingNeeded, '150 Crates');
      // Total quantity: 2250 * 0.4 kg = 900.0 kg
      expect(res.totalQuantity, 900.0);
      // Total price: 2250 * 55.0 = ₹1,23,750.0
      expect(res.totalPrice, 123750.0);
      expect(res.totalPriceDisplay, '₹123,750');
      expect(res.breakdownSteps.length, greaterThanOrEqualTo(4));
    });

    test('Plain Curd Cup 80g (P80) - 600 Pieces calculation', () {
      final res = CalculationService.calculateProduct(
        product: plainCurd80,
        inputMode: 'Pieces',
        inputQuantity: 600.0,
      );

      expect(res.pieces, 600);
      expect(res.crates, 10.0); // 600 / 60
      expect(res.totalQuantity, 48.0); // 600 * 0.08 kg
      expect(res.totalPrice, 9000.0); // 600 * 15.0
      expect(res.totalPriceDisplay, '₹9,000');
    });

    test('Purabi Lassi 200 ml (PL200) - 600 Litres calculation', () {
      final res = CalculationService.calculateProduct(
        product: lassi200,
        inputMode: 'Litres',
        inputQuantity: 600.0,
      );

      // 600 L / 0.2 L = 3000 pieces
      expect(res.pieces, 3000);
      // 3000 / 30 = 100 crates
      expect(res.crates, 100.0);
      expect(res.totalQuantity, 600.0);
      // 3000 * 20.0 = ₹60,000
      expect(res.totalPrice, 60000.0);
    });

    test('Curd Pouch 1 kg (CP1000) - 10 Crates calculation', () {
      final res = CalculationService.calculateProduct(
        product: curdPouch1000,
        inputMode: 'Crates',
        inputQuantity: 10.0,
      );

      expect(res.pieces, 120); // 10 * 12
      expect(res.crates, 10.0);
      expect(res.totalQuantity, 120.0); // 120 * 1.0 kg
      expect(res.totalPrice, 9000.0); // 120 * 75.0
    });

    test('Purabi Plus Milk 500 ml - Pieces mode backward compatibility', () {
      final res = CalculationService.calculateProduct(
        product: milk500,
        inputMode: 'Pieces',
        inputQuantity: 3000.0,
      );

      expect(res.pieces, 3000);
      expect(res.crates, 150.0);
      expect(res.volumeLitres, 1500.0);
      expect(res.totalPrice, 84000.0); // 3000 * 28
    });
  });
}
