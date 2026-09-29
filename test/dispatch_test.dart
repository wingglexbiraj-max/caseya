import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/dispatch_record.dart';
import 'package:caseya/models/product_model.dart';
import 'package:caseya/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test Product definitions matching plant metadata
  const lassiProduct = ProductModel(
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
    allowedInputModes: ['Pieces', 'Crates', 'Litres'],
  );

  const curdProduct = ProductModel(
    productId: '9900026',
    productName: 'Sweet Curd Cup 400g (S400)',
    itemCode: '9900026',
    shortCode: 'S400',
    category: 'Curd',
    unit: 'g',
    packSize: 400,
    packSizeDisplay: '400 g',
    piecesPerCrate: 15,
    perCrateQty: 6.0,
    allowedInputModes: ['Pieces', 'Crates', 'Kg'],
  );

  const purabiPlusProduct = ProductModel(
    productId: '9900095',
    productName: 'Purabi Plus 250 ml (PP250)',
    itemCode: '9900095',
    shortCode: 'PP250',
    category: 'Milk',
    unit: 'ml',
    packSize: 250,
    packSizeDisplay: '250 ml',
    piecesPerCrate: 48,
    perCrateQty: 12.0,
    allowedInputModes: ['Pieces', 'Crates', 'Litres'],
  );

  group('Product Metadata Integration & Reusable Conversion Engine Tests', () {
    test('1. Purabi Lassi 200ml entered in Crates mode (10 crates)', () {
      final item = DispatchItem.fromInput(
        id: 'item-1',
        dispatchId: 'disp-1',
        product: lassiProduct,
        inputMode: 'Crates',
        inputQuantity: 10.0,
      );

      expect(item.crates, 10.0);
      expect(item.pieces, 300);
      expect(item.normalizedQuantity, 60.0);
      expect(item.normalizedUnit, 'Litres');
      expect(item.shortUnit, 'L');
    });

    test('2. Purabi Lassi 200ml entered in Pieces mode (300 pieces)', () {
      final item = DispatchItem.fromInput(
        id: 'item-2',
        dispatchId: 'disp-1',
        product: lassiProduct,
        inputMode: 'Pieces',
        inputQuantity: 300,
      );

      expect(item.crates, 10.0);
      expect(item.pieces, 300);
      expect(item.normalizedQuantity, 60.0);
      expect(item.normalizedUnit, 'Litres');
    });

    test('3. Purabi Lassi 200ml entered in Litres mode (60 L)', () {
      final item = DispatchItem.fromInput(
        id: 'item-3',
        dispatchId: 'disp-1',
        product: lassiProduct,
        inputMode: 'Litres',
        inputQuantity: 60.0,
      );

      expect(item.crates, 10.0);
      expect(item.pieces, 300);
      expect(item.normalizedQuantity, 60.0);
      expect(item.normalizedUnit, 'Litres');
    });

    test('4. Sweet Curd Cup 400g entered in Crates mode (5 crates)', () {
      final item = DispatchItem.fromInput(
        id: 'item-4',
        dispatchId: 'disp-1',
        product: curdProduct,
        inputMode: 'Crates',
        inputQuantity: 5.0,
      );

      expect(item.crates, 5.0);
      expect(item.pieces, 75);
      expect(item.normalizedQuantity, 30.0);
      expect(item.normalizedUnit, 'Kg');
      expect(item.shortUnit, 'kg');
    });
  });

  group('Multiple Products Per Vehicle & Dynamic Daily Consolidation', () {
    test('Vehicle dispatch parent contains multiple product lines', () {
      final item1 = DispatchItem.fromInput(
        id: 'i1',
        dispatchId: 'v1',
        product: lassiProduct,
        inputMode: 'Crates',
        inputQuantity: 10.0, // 10 cr, 300 pcs, 60 L
      );
      final item2 = DispatchItem.fromInput(
        id: 'i2',
        dispatchId: 'v1',
        product: purabiPlusProduct,
        inputMode: 'Crates',
        inputQuantity: 20.0, // 20 cr, 960 pcs, 240 L
      );
      final item3 = DispatchItem.fromInput(
        id: 'i3',
        dispatchId: 'v1',
        product: curdProduct,
        inputMode: 'Crates',
        inputQuantity: 5.0, // 5 cr, 75 pcs, 30 kg
      );

      final vehicleDispatch = VehicleDispatch(
        id: 'v1',
        dispatchDate: '2026-09-29',
        distributorName: 'Distributor A',
        vehicleNumber: 'AS01AB1234',
        dispatchTime: '08:35 AM',
        createdBy: 'Officer 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [item1, item2, item3],
      );

      expect(vehicleDispatch.productLineCount, 3);
      expect(vehicleDispatch.totalCrates, 35.0);
      expect(vehicleDispatch.totalPieces, 1335);
      expect(vehicleDispatch.totalLitres, 300.0); // 60 + 240
      expect(vehicleDispatch.totalKg, 30.0); // Curd
      expect(vehicleDispatch.summaryLabel, '3 Products • 35 Crates');
    });

    test('Section 12: Prevents double counting & dynamically recalculates on edit', () {
      // Vehicle A dispatches 10 crates Lassi
      var vehicleA = VehicleDispatch(
        id: 'va',
        dispatchDate: '2026-09-29',
        distributorName: 'Distributor A',
        vehicleNumber: 'AS01AB1234',
        dispatchTime: '08:00 AM',
        createdBy: 'Officer 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'ia1',
            dispatchId: 'va',
            product: lassiProduct,
            inputMode: 'Crates',
            inputQuantity: 10.0,
          ),
        ],
      );

      // Vehicle B dispatches 15 crates Lassi
      final vehicleB = VehicleDispatch(
        id: 'vb',
        dispatchDate: '2026-09-29',
        distributorName: 'Distributor B',
        vehicleNumber: 'AS02CD5678',
        dispatchTime: '09:00 AM',
        createdBy: 'Officer 1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'ib1',
            dispatchId: 'vb',
            product: lassiProduct,
            inputMode: 'Crates',
            inputQuantity: 15.0,
          ),
        ],
      );

      List<VehicleDispatch> dispatches = [vehicleA, vehicleB];

      // Daily Lassi total: 10 + 15 = 25 crates / 750 pieces / 150 L
      double totalCrates = dispatches.fold(0.0, (acc, v) => acc + v.totalCrates);
      int totalPieces = dispatches.fold(0, (acc, v) => acc + v.totalPieces);
      double totalLitres = dispatches.fold(0.0, (acc, v) => acc + v.totalLitres);

      expect(totalCrates, 25.0);
      expect(totalPieces, 750);
      expect(totalLitres, 150.0);

      // Operator edits Vehicle A from 10 -> 12 crates
      vehicleA = vehicleA.copyWith(
        items: [
          DispatchItem.fromInput(
            id: 'ia1',
            dispatchId: 'va',
            product: lassiProduct,
            inputMode: 'Crates',
            inputQuantity: 12.0,
          ),
        ],
      );

      dispatches = [vehicleA, vehicleB];

      // Daily total automatically becomes 27 crates / 810 pieces / 162 L
      totalCrates = dispatches.fold(0.0, (acc, v) => acc + v.totalCrates);
      totalPieces = dispatches.fold(0, (acc, v) => acc + v.totalPieces);
      totalLitres = dispatches.fold(0.0, (acc, v) => acc + v.totalLitres);

      expect(totalCrates, 27.0);
      expect(totalPieces, 810);
      expect(totalLitres, 162.0);
    });
  });

  group('LocalStorageService Dispatch Persistence Tests', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      await LocalStorageService.init();
    });

    test('Initial dispatches are seeded and retrieve correctly', () async {
      final dispatches = await LocalStorageService.getDispatches();
      expect(dispatches.isNotEmpty, isTrue);

      final todayStr = '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${DateTime.now().day.toString().padLeft(2, '0')}';
      final todayDispatches = await LocalStorageService.getDispatchesByDate(todayStr);

      expect(todayDispatches.length, greaterThanOrEqualTo(2));
      final v1 = todayDispatches.firstWhere((d) => d.vehicleNumber == 'AS01AB1234');
      expect(v1.distributorName, 'Distributor A');
      expect(v1.items.length, 3);

      final v2 = todayDispatches.firstWhere((d) => d.vehicleNumber == 'AS02CD5678');
      expect(v2.distributorName, 'Distributor B');
      expect(v2.items.length, 2);
    });

    test('Adding and deleting a vehicle dispatch works without data corruption', () async {
      final newDispatch = VehicleDispatch(
        id: 'test-disp-99',
        dispatchDate: '2026-09-30',
        distributorName: 'City North Hub',
        vehicleNumber: 'AS01XX9999',
        dispatchTime: '11:00 AM',
        createdBy: 'Tester',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 't-item-1',
            dispatchId: 'test-disp-99',
            product: lassiProduct,
            inputMode: 'Crates',
            inputQuantity: 8.0,
          ),
        ],
      );

      await LocalStorageService.addDispatch(newDispatch);
      var all = await LocalStorageService.getDispatches();
      expect(all.any((d) => d.id == 'test-disp-99'), isTrue);

      await LocalStorageService.deleteDispatch('test-disp-99');
      all = await LocalStorageService.getDispatches();
      expect(all.any((d) => d.id == 'test-disp-99'), isFalse);
    });
  });
}
