import 'package:flutter_test/flutter_test.dart';
import 'package:caseya/models/dispatch_record.dart';
import 'package:caseya/core/constants/dairy_products.dart';
import 'package:caseya/services/calculation_service.dart';
import 'package:caseya/services/local_storage_service.dart';
import 'package:caseya/providers/dispatch_provider.dart';
import 'package:caseya/repositories/dispatch_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Test Product definitions matching plant metadata
  final lassiProduct = DairyProducts.officialProducts.firstWhere(
    (p) => p.shortCode == 'Lassi 200' || p.productName.contains('Lassi'),
  );

  final s80Product = DairyProducts.officialProducts.firstWhere(
    (p) => p.shortCode == 'S80' || p.productName.contains('S80'),
  );

  final milkStdProduct = DairyProducts.officialProducts.firstWhere(
    (p) => p.shortCode == 'STD 500' || p.productName.contains('STD 500'),
  );

  group('Scenario: Multi-Vehicle Morning Dispatch Aggregation (Vehicle A, B, C)', () {
    test('Vehicle A (20 Lassi + 20 S80), Vehicle B (10 Lassi + 30 S80), Vehicle C (1 Lassi) -> 31 Lassi, 50 S80', () {
      const dispatchDate = '2026-10-09';

      // 1. Vehicle A takes 20 Lassi pieces and 20 S80 pieces
      final vehicleA = VehicleDispatch(
        id: 'disp-A',
        dispatchDate: dispatchDate,
        distributorName: 'Distributor Alpha',
        vehicleNumber: 'Vehicle A',
        dispatchTime: '06:15 AM',
        createdBy: 'Morning Dispatcher',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'item-A1',
            dispatchId: 'disp-A',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 20,
          ),
          DispatchItem.fromInput(
            id: 'item-A2',
            dispatchId: 'disp-A',
            product: s80Product,
            inputMode: 'Pieces',
            inputQuantity: 20,
          ),
        ],
      );

      // Verify Vehicle A individual items
      expect(vehicleA.items[0].pieces, 20);
      expect(vehicleA.items[1].pieces, 20);

      // 2. Vehicle B takes 10 Lassi pieces and 30 S80 pieces
      final vehicleB = VehicleDispatch(
        id: 'disp-B',
        dispatchDate: dispatchDate,
        distributorName: 'Distributor Beta',
        vehicleNumber: 'Vehicle B',
        dispatchTime: '06:45 AM',
        createdBy: 'Morning Dispatcher',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'item-B1',
            dispatchId: 'disp-B',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 10,
          ),
          DispatchItem.fromInput(
            id: 'item-B2',
            dispatchId: 'disp-B',
            product: s80Product,
            inputMode: 'Pieces',
            inputQuantity: 30,
          ),
        ],
      );

      // 3. Vehicle C takes 1 Lassi piece
      final vehicleC = VehicleDispatch(
        id: 'disp-C',
        dispatchDate: dispatchDate,
        distributorName: 'Distributor Gamma',
        vehicleNumber: 'Vehicle C',
        dispatchTime: '07:10 AM',
        createdBy: 'Morning Dispatcher',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'item-C1',
            dispatchId: 'disp-C',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 1,
          ),
        ],
      );

      // 4. Test DispatchState aggregation (Never overwrite previous vehicles!)
      final state = DispatchState(
        selectedDate: dispatchDate,
        rangeStartDate: dispatchDate,
        rangeEndDate: dispatchDate,
        dispatches: [vehicleA, vehicleB, vehicleC],
        products: DairyProducts.officialProducts,
      );

      expect(state.dispatchesForSelectedDate.length, 3);
      expect(state.totalVehiclesForSelectedDate, 3);
      expect(state.totalDistributorsForSelectedDate, 3);

      final summaries = state.dailyProductSummaries;

      // Find Lassi in consolidated summaries
      final lassiSummary = summaries.firstWhere((s) => s.productId == lassiProduct.productId);
      // Lassi: 20 + 10 + 1 = 31 pieces!
      expect(lassiSummary.totalPieces, 31);
      expect(lassiSummary.vehicleCount, 3);
      // 31 pieces * 0.200 L = 6.2 L
      expect(lassiSummary.totalQuantity, closeTo(6.2, 0.001));
      expect(lassiSummary.normalizedUnit, 'Litres');

      // Find S80 in consolidated summaries
      final s80Summary = summaries.firstWhere((s) => s.productId == s80Product.productId);
      // S80: 20 + 30 = 50 pieces!
      expect(s80Summary.totalPieces, 50);
      expect(s80Summary.vehicleCount, 2);
      // 50 pieces * 0.080 kg = 4.0 kg
      expect(s80Summary.totalQuantity, closeTo(4.0, 0.001));
      expect(s80Summary.normalizedUnit, 'Kg');

      // Test that total pieces for the day is 31 + 50 = 81 pieces
      expect(state.totalPiecesForSelectedDate, 81);
    });

    test('Saving another vehicle with Milk STD 500 in Crates computes accurate piece conversions', () {
      const dispatchDate = '2026-10-09';

      // Vehicle D takes 30 crates of Milk STD 500ml (24 pcs/crate = 720 pieces, 360 L)
      final vehicleD = VehicleDispatch(
        id: 'disp-D',
        dispatchDate: dispatchDate,
        distributorName: 'Central Depot',
        vehicleNumber: 'Vehicle D',
        dispatchTime: '07:30 AM',
        createdBy: 'Morning Dispatcher',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'item-D1',
            dispatchId: 'disp-D',
            product: milkStdProduct,
            inputMode: 'Crates',
            inputQuantity: 30,
          ),
        ],
      );

      final item = vehicleD.items.first;
      expect(item.crates, 30.0);
      expect(item.pieces, 30 * 24); // 720 pieces
      expect(item.normalizedQuantity, 360.0); // 360 Litres
      expect(item.normalizedUnit, 'Litres');
    });

    test('Date switching accurately filters dispatches by selected date', () {
      final dispOct09 = VehicleDispatch(
        id: 'disp-1',
        dispatchDate: '2026-10-09',
        distributorName: 'Distributor A',
        vehicleNumber: 'AS-01-A',
        dispatchTime: '08:00 AM',
        createdBy: 'Officer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'i1',
            dispatchId: 'disp-1',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 20,
          ),
        ],
      );

      final dispOct10 = VehicleDispatch(
        id: 'disp-2',
        dispatchDate: '2026-10-10',
        distributorName: 'Distributor B',
        vehicleNumber: 'AS-01-B',
        dispatchTime: '08:00 AM',
        createdBy: 'Officer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'i2',
            dispatchId: 'disp-2',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 50,
          ),
        ],
      );

      final stateOct09 = DispatchState(
        selectedDate: '2026-10-09',
        rangeStartDate: '2026-10-09',
        rangeEndDate: '2026-10-09',
        dispatches: [dispOct09, dispOct10],
      );

      expect(stateOct09.dispatchesForSelectedDate.length, 1);
      expect(stateOct09.totalPiecesForSelectedDate, 20);

      final stateOct10 = stateOct09.copyWith(selectedDate: '2026-10-10');
      expect(stateOct10.dispatchesForSelectedDate.length, 1);
      expect(stateOct10.totalPiecesForSelectedDate, 50);
    });

    test('Editing an existing vehicle dispatch recalculates daily totals', () {
      var vehicle = VehicleDispatch(
        id: 'disp-edit',
        dispatchDate: '2026-10-09',
        distributorName: 'Distributor A',
        vehicleNumber: 'Vehicle A',
        dispatchTime: '08:00 AM',
        createdBy: 'Officer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'i-edit-1',
            dispatchId: 'disp-edit',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 20,
          ),
        ],
      );

      var state = DispatchState(
        selectedDate: '2026-10-09',
        rangeStartDate: '2026-10-09',
        rangeEndDate: '2026-10-09',
        dispatches: [vehicle],
      );

      expect(state.totalPiecesForSelectedDate, 20);

      // Edit: Vehicle A quantity updated to 35 pieces
      vehicle = vehicle.copyWith(
        items: [
          DispatchItem.fromInput(
            id: 'i-edit-1',
            dispatchId: 'disp-edit',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 35,
          ),
        ],
      );

      state = state.copyWith(dispatches: [vehicle]);
      expect(state.totalPiecesForSelectedDate, 35);
    });

    test('Deleting a vehicle dispatch recalculates daily totals and removes line items', () {
      final v1 = VehicleDispatch(
        id: 'disp-del-1',
        dispatchDate: '2026-10-09',
        distributorName: 'Distributor A',
        vehicleNumber: 'Vehicle A',
        dispatchTime: '08:00 AM',
        createdBy: 'Officer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'i-1',
            dispatchId: 'disp-del-1',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 20,
          ),
        ],
      );

      final v2 = VehicleDispatch(
        id: 'disp-del-2',
        dispatchDate: '2026-10-09',
        distributorName: 'Distributor B',
        vehicleNumber: 'Vehicle B',
        dispatchTime: '08:30 AM',
        createdBy: 'Officer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'i-2',
            dispatchId: 'disp-del-2',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 15,
          ),
        ],
      );

      var state = DispatchState(
        selectedDate: '2026-10-09',
        rangeStartDate: '2026-10-09',
        rangeEndDate: '2026-10-09',
        dispatches: [v1, v2],
      );

      expect(state.totalPiecesForSelectedDate, 35);
      expect(state.dispatchesForSelectedDate.length, 2);

      // Delete v1
      state = state.copyWith(dispatches: [v2]);
      expect(state.totalPiecesForSelectedDate, 15);
      expect(state.dispatchesForSelectedDate.length, 1);
    });

    test('CSV Exporter produces valid CSV headers and rows for vehicles, products, and distributors', () {
      final notifier = DispatchNotifier(DispatchRepository());

      final vehicle = VehicleDispatch(
        id: 'disp-csv',
        dispatchDate: '2026-10-09',
        distributorName: 'Distributor Alpha',
        vehicleNumber: 'AS-01-A',
        dispatchTime: '08:00 AM',
        createdBy: 'Officer',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        items: [
          DispatchItem.fromInput(
            id: 'i-csv-1',
            dispatchId: 'disp-csv',
            product: lassiProduct,
            inputMode: 'Pieces',
            inputQuantity: 31,
          ),
        ],
      );

      // 1. Vehicle records CSV
      final vehicleCsv = notifier.generateVehicleRecordsCsv([vehicle]);
      expect(vehicleCsv.contains('Dispatch ID,Date,Dispatched At'), isTrue);
      expect(vehicleCsv.contains('AS-01-A'), isTrue);
      expect(vehicleCsv.contains('Distributor Alpha'), isTrue);

      // 2. Product-wise CSV
      final productSummary = DailyDispatchProductSummary(
        productId: lassiProduct.productId,
        productName: lassiProduct.productName,
        shortCode: lassiProduct.shortCode,
        itemCode: lassiProduct.itemCode,
        packSizeDisplay: lassiProduct.packSizeDisplay,
        totalCrates: 1.03,
        totalPieces: 31,
        totalQuantity: 6.2,
        normalizedUnit: 'Litres',
        vehicleCount: 3,
        distributorCount: 2,
        revenue: 620.0,
      );

      final productCsv = notifier.generateProductWiseCsv([productSummary], 'Today');
      expect(productCsv.contains('Product Code,Product Name'), isTrue);
      expect(productCsv.contains(lassiProduct.itemCode), isTrue);
      expect(productCsv.contains('31'), isTrue);

      // 3. Distributor-wise CSV
      final distSummary = DistributorDailySummary(
        distributorName: 'Distributor Alpha',
        vehicles: ['Vehicle A', 'Vehicle B'],
        dispatches: [vehicle],
        productItems: vehicle.items,
        totalCrates: 1.03,
        totalLitres: 6.2,
        totalKg: 0.0,
      );

      final distCsv = notifier.generateDistributorWiseCsv([distSummary], 'Today');
      expect(distCsv.contains('Distributor,Total Trips/Dispatches'), isTrue);
      expect(distCsv.contains('Distributor Alpha'), isTrue);
      expect(distCsv.contains('Vehicle A, Vehicle B'), isTrue);
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

  group('29-Product Catalogue & Packaging Configuration Verification', () {
    test('Official catalogue contains exactly 29 products', () {
      expect(DairyProducts.officialProducts.length, 29);
    });

    test('All 29 products have exact names, units, packaging and prices', () {
      final products = {for (final p in DairyProducts.officialProducts) p.productName: p};

      // 1. STD 200ml — ₹15 per packet; 60 pieces per crate
      final std200 = products['STD 200ml']!;
      expect(std200.productName, 'STD 200ml');
      expect(std200.pricePerPiece, 15.0);
      expect(std200.piecesPerCrate, 60);
      expect(std200.individualSaleUnit, 'packet');
      expect(std200.bulkPackingUnit, 'Crates');
      expect(std200.hasCrateConfiguration, isTrue);

      // 2. STD 250ml — ₹18 per packet; 48 pieces per crate
      final std250 = products['STD 250ml']!;
      expect(std250.productName, 'STD 250ml');
      expect(std250.pricePerPiece, 18.0);
      expect(std250.piecesPerCrate, 48);
      expect(std250.individualSaleUnit, 'packet');
      expect(std250.bulkPackingUnit, 'Crates');

      // 3. STD 500ml — ₹35 per packet; 24 pieces per crate
      final std500 = products['STD 500ml']!;
      expect(std500.productName, 'STD 500ml');
      expect(std500.pricePerPiece, 35.0);
      expect(std500.piecesPerCrate, 24);
      expect(std500.individualSaleUnit, 'packet');
      expect(std200.hasCrateConfiguration, isTrue);

      // 4. SM+ 500ml — Defence supply; price not specified; 24 pieces per crate
      final sm500 = products['SM+ 500ml']!;
      expect(sm500.productName, 'SM+ 500ml');
      expect(sm500.pricePerPiece, 0.0);
      expect(sm500.hasPriceConfiguration, isFalse);
      expect(sm500.priceCustomLabel, 'Defence Supply');
      expect(sm500.piecesPerCrate, 24);
      expect(sm500.individualSaleUnit, 'packet');
      expect(sm500.bulkPackingUnit, 'Crates');

      // 5. Lassi — ₹20 per cup; 30 pieces per crate
      final lassi = products['Lassi']!;
      expect(lassi.productName, 'Lassi');
      expect(lassi.pricePerPiece, 20.0);
      expect(lassi.piecesPerCrate, 30);
      expect(lassi.individualSaleUnit, 'cup');
      expect(lassi.bulkPackingUnit, 'Crates');

      // 6. S80 — ₹15 per cup; 60 pieces per crate
      final s80 = products['S80']!;
      expect(s80.productName, 'S80');
      expect(s80.pricePerPiece, 15.0);
      expect(s80.piecesPerCrate, 60);
      expect(s80.individualSaleUnit, 'cup');
      expect(s80.bulkPackingUnit, 'Crates');

      // 7. S200 — ₹30 per cup; 30 pieces per crate
      final s200 = products['S200']!;
      expect(s200.productName, 'S200');
      expect(s200.pricePerPiece, 30.0);
      expect(s200.piecesPerCrate, 30);
      expect(s200.individualSaleUnit, 'cup');

      // 8. S400 — ₹55 per cup; 15 pieces per crate
      final s400 = products['S400']!;
      expect(s400.productName, 'S400');
      expect(s400.pricePerPiece, 55.0);
      expect(s400.piecesPerCrate, 15);
      expect(s400.individualSaleUnit, 'cup');

      // 9. Sweet Curd Pouch 400gm — ₹40 per packet; 30 pieces per crate
      final scp400 = products['Sweet Curd Pouch 400gm']!;
      expect(scp400.productName, 'Sweet Curd Pouch 400gm');
      expect(scp400.pricePerPiece, 40.0);
      expect(scp400.piecesPerCrate, 30);
      expect(scp400.individualSaleUnit, 'packet');

      // 10. P80 — ₹15 per cup; 60 pieces per crate
      final p80 = products['P80']!;
      expect(p80.productName, 'P80');
      expect(p80.pricePerPiece, 15.0);
      expect(p80.piecesPerCrate, 60);
      expect(p80.individualSaleUnit, 'cup');

      // 11. P200 — ₹30 per cup; 30 pieces per crate
      final p200 = products['P200']!;
      expect(p200.productName, 'P200');
      expect(p200.pricePerPiece, 30.0);
      expect(p200.piecesPerCrate, 30);
      expect(p200.individualSaleUnit, 'cup');

      // 12. P400 — ₹55 per cup; 15 pieces per crate
      final p400 = products['P400']!;
      expect(p400.productName, 'P400');
      expect(p400.pricePerPiece, 55.0);
      expect(p400.piecesPerCrate, 15);
      expect(p400.individualSaleUnit, 'cup');

      // 13. Plain Curd Pouch 400gm — ₹35 per packet; 30 pieces per crate
      final pcp400 = products['Plain Curd Pouch 400gm']!;
      expect(pcp400.productName, 'Plain Curd Pouch 400gm');
      expect(pcp400.pricePerPiece, 35.0);
      expect(pcp400.piecesPerCrate, 30);
      expect(pcp400.individualSaleUnit, 'packet');

      // 14. Plain Curd Pouch 1kg — ₹75 per packet; crate size not specified
      final pcp1k = products['Plain Curd Pouch 1kg']!;
      expect(pcp1k.productName, 'Plain Curd Pouch 1kg');
      expect(pcp1k.pricePerPiece, 75.0);
      expect(pcp1k.piecesPerCrate, 0);
      expect(pcp1k.hasCrateConfiguration, isFalse);
      expect(pcp1k.bulkPackingUnit, isNull);
      expect(pcp1k.individualSaleUnit, 'packet');

      // 15. UHT 200ml — ₹17.50 per packet; crate size not specified
      final uht200 = products['UHT 200ml']!;
      expect(uht200.productName, 'UHT 200ml');
      expect(uht200.pricePerPiece, 17.5);
      expect(uht200.piecesPerCrate, 0);
      expect(uht200.hasCrateConfiguration, isFalse);

      // 16. UHT 1000ml — ₹74 per packet; crate size not specified
      final uht1k = products['UHT 1000ml']!;
      expect(uht1k.productName, 'UHT 1000ml');
      expect(uht1k.pricePerPiece, 74.0);
      expect(uht1k.piecesPerCrate, 0);
      expect(uht1k.hasCrateConfiguration, isFalse);

      // 17-20. Flavoured Milk (Kesar, Mango, Hazelnut, Strawberry) — ₹25 per bottle
      for (final flavor in ['Flavoured Milk (Kesar)', 'Flavoured Milk (Mango)', 'Flavoured Milk (Hazelnut)', 'Flavoured Milk (Strawberry)']) {
        final fm = products[flavor]!;
        expect(fm.pricePerPiece, 25.0);
        expect(fm.individualSaleUnit, 'bottle');
        expect(fm.hasCrateConfiguration, isFalse);
        expect(fm.bulkPackingUnit, isNull);
      }

      // 21. Paneer — ₹92 per packet; 20 packets per box
      final paneer = products['Paneer']!;
      expect(paneer.productName, 'Paneer');
      expect(paneer.pricePerPiece, 92.0);
      expect(paneer.piecesPerCrate, 20);
      expect(paneer.individualSaleUnit, 'packet');
      expect(paneer.bulkPackingUnit, 'Boxes');
      expect(paneer.hasCrateConfiguration, isTrue);

      // 22. Kalakaand — ₹140 per packet; packaging size not specified
      final kalakaand = products['Kalakaand']!;
      expect(kalakaand.productName, 'Kalakaand');
      expect(kalakaand.pricePerPiece, 140.0);
      expect(kalakaand.hasCrateConfiguration, isFalse);

      // 23. Milk Cake — ₹150 per packet; packaging size not specified
      final milkCake = products['Milk Cake']!;
      expect(milkCake.productName, 'Milk Cake');
      expect(milkCake.pricePerPiece, 150.0);
      expect(milkCake.hasCrateConfiguration, isFalse);

      // 24. Peda — sold by packet; price not specified
      final peda = products['Peda']!;
      expect(peda.productName, 'Peda');
      expect(peda.pricePerPiece, 0.0);
      expect(peda.hasPriceConfiguration, isFalse);
      expect(peda.priceCustomLabel, 'Price Pending');
      expect(peda.hasCrateConfiguration, isFalse);

      // 25. Ghee 200gm — ₹20 per bottle; packaging size not specified
      final ghee200 = products['Ghee 200gm']!;
      expect(ghee200.productName, 'Ghee 200gm');
      expect(ghee200.pricePerPiece, 20.0);
      expect(ghee200.individualSaleUnit, 'bottle');

      // 26. Ghee 500gm — ₹420 per bottle; packaging size not specified
      final ghee500 = products['Ghee 500gm']!;
      expect(ghee500.productName, 'Ghee 500gm');
      expect(ghee500.pricePerPiece, 420.0);
      expect(ghee500.individualSaleUnit, 'bottle');

      // 27-29. Honey 125gm (₹100), Honey 250gm (₹180), Honey 500gm (₹330)
      final h125 = products['Honey 125gm']!;
      expect(h125.productName, 'Honey 125gm');
      expect(h125.pricePerPiece, 100.0);
      expect(h125.individualSaleUnit, 'bottle');

      final h250 = products['Honey 250gm']!;
      expect(h250.productName, 'Honey 250gm');
      expect(h250.pricePerPiece, 180.0);
      expect(h250.individualSaleUnit, 'bottle');

      final h500 = products['Honey 500gm']!;
      expect(h500.productName, 'Honey 500gm');
      expect(h500.pricePerPiece, 330.0);
      expect(h500.individualSaleUnit, 'bottle');
    });

    test('Paneer Box packaging conversion: 5 Boxes = 100 packets, 20kg weight, exact ₹9,200', () {
      final paneer = DairyProducts.officialProducts.firstWhere((p) => p.productName == 'Paneer');

      final calc = CalculationService.calculateProduct(
        product: paneer,
        inputMode: 'Boxes',
        inputQuantity: 5.0,
      );

      expect(calc.crates, 5.0);
      expect(calc.pieces, 100); // 5 * 20
      expect(calc.totalQuantity, 20.0); // 100 * 0.200 kg
      expect(calc.totalPrice, 9200.0); // 100 * 92
      expect(calc.packingNeeded, '5 Boxes');

      final itemFromBox = DispatchItem.fromInput(
        id: 'paneer-box-1',
        dispatchId: 'disp-test',
        product: paneer,
        inputMode: 'Boxes',
        inputQuantity: 5.0,
      );

      expect(itemFromBox.crates, 5.0);
      expect(itemFromBox.pieces, 100);
      expect(itemFromBox.normalizedQuantity, 20.0);
    });

    test('Unconfigured price products: SM+ 500ml and Peda report 0.0 value with custom labels', () {
      final smPlus = DairyProducts.officialProducts.firstWhere((p) => p.productName == 'SM+ 500ml');
      final peda = DairyProducts.officialProducts.firstWhere((p) => p.productName == 'Peda');

      final smCalc = CalculationService.calculateProduct(
        product: smPlus,
        inputMode: 'Crates',
        inputQuantity: 2.0,
      );
      expect(smCalc.pieces, 48); // 2 * 24
      expect(smCalc.totalPrice, 0.0); // No invented price
      expect(smCalc.totalPriceDisplay, 'Defence Supply');

      final pedaCalc = CalculationService.calculateProduct(
        product: peda,
        inputMode: 'Packets',
        inputQuantity: 15.0,
      );
      expect(pedaCalc.pieces, 15);
      expect(pedaCalc.totalPrice, 0.0); // No invented price
      expect(pedaCalc.totalPriceDisplay, 'Price Pending');
    });

    test('Unconfigured crate products disallow crate input and calculate correct individual price', () {
      final uht = DairyProducts.officialProducts.firstWhere((p) => p.productName == 'UHT 200ml');
      expect(uht.hasCrateConfiguration, isFalse);
      expect(uht.allowedInputModes.contains('Crates'), isFalse);

      final uhtCalc = CalculationService.calculateProduct(
        product: uht,
        inputMode: 'Packets',
        inputQuantity: 40.0,
      );
      expect(uhtCalc.pieces, 40);
      expect(uhtCalc.crates, 0.0);
      expect(uhtCalc.totalPrice, 700.0); // 40 * 17.50
    });
  });
}
