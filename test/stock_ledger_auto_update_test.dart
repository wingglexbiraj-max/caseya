import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:caseya/models/inventory_item_model.dart';
import 'package:caseya/models/operations_models.dart';
import 'package:caseya/models/batch_record_model.dart';
import 'package:caseya/models/stock_ledger_entry_model.dart';
import 'package:caseya/services/inventory_stock_service.dart';
import 'package:caseya/providers/inventory_stock_provider.dart';
import 'package:caseya/providers/production_provider.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:caseya/pages/stock/stock_page.dart';
import 'package:caseya/core/constants/dairy_products.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Production Register & Daily Batch Making to Stock Ledger Auto-Update Tests', () {
    test('1. Poly Film is automatically deducted when pouch products (STD 500 ml & SCP 400) are produced', () {
      final records = [
        const ProductionRecord(
          recordId: 'PR-STD-001',
          date: '2026-10-06',
          time: '09:00 AM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: '9900027',
          productName: 'STD 500 ml',
          batchNo: 'BT-20261006-STD-01',
          quantityProduced: 2500.0,
          unit: 'Litres',
          cratesProduced: 104.16,
          piecesProduced: 5000, // 5000 pouches = 1.0 roll of poly_std_500
        ),
        const ProductionRecord(
          recordId: 'PR-SCP-002',
          date: '2026-10-06',
          time: '11:00 AM',
          shift: 'Shift A',
          employeeId: 'EMP-01',
          employeeName: 'Biraj Goswami',
          productId: 'SCP400',
          productName: 'Sweet Curd Pouch 400 gm (SCP 400)',
          batchNo: 'BT-20261006-SCP-01',
          quantityProduced: 1600.0,
          unit: 'kg',
          cratesProduced: 133.3,
          piecesProduced: 4000, // 4000 pouches = 1.0 roll of poly_scp_400
        ),
      ];

      final calc = InventoryStockService.calculateInventoryStock(
        productionRecords: records,
        standardizationRecords: [],
        batchRecords: [],
      );

      final stdRoll = calc.items.firstWhere((i) => i.id == 'poly_std_500');
      final scpRoll = calc.items.firstWhere((i) => i.id == 'poly_scp_400');

      expect(stdRoll.consumedQty, equals(1.0));
      expect(scpRoll.consumedQty, equals(1.0));

      final polyDeductions = calc.deductionLedger.where((d) => d.inventoryItemId.startsWith('poly_')).toList();
      expect(polyDeductions.length, equals(2));
      expect(polyDeductions.any((d) => d.inventoryItemId == 'poly_std_500' && d.quantityDeducted == 1.0), isTrue);
      expect(polyDeductions.any((d) => d.inventoryItemId == 'poly_scp_400' && d.quantityDeducted == 1.0), isTrue);
    });

    test('2. Daily Batch Making automatically deducts Sugar and SMP with date-wise ledger entries', () {
      final now = DateTime.now();
      final batch = BatchRecordModel(
        id: 'BR-TEST-001',
        productionDate: '2026-10-06',
        productId: 'LASSI',
        productName: 'Lassi',
        batchNumber: 'BT-20261006-LASSI-01',
        batchQuantity: 500.0,
        batchUnit: 'L',
        shift: 'Shift A',
        operatorName: 'Biraj Goswami',
        ingredients: [
          BatchIngredientModel(
            id: 'ING-1',
            batchId: 'BT-20261006-LASSI-01',
            ingredientName: 'Sugar',
            quantity: 46.0,
            unit: 'kg',
          ),
          BatchIngredientModel(
            id: 'ING-2',
            batchId: 'BT-20261006-LASSI-01',
            ingredientName: 'SMP',
            quantity: 29.0,
            unit: 'kg',
          ),
        ],
        createdAt: now,
        updatedAt: now,
      );

      final calc = InventoryStockService.calculateInventoryStock(
        productionRecords: [],
        standardizationRecords: [],
        batchRecords: [batch],
      );

      final sugarItem = calc.items.firstWhere((i) => i.id == 'ingredient_sugar');
      final smpItem = calc.items.firstWhere((i) => i.id == 'ingredient_smp');

      expect(sugarItem.consumedQty, equals(46.0));
      expect(smpItem.consumedQty, equals(29.0));

      final sugarDeductions = calc.deductionLedger.where((d) => d.inventoryItemId == 'ingredient_sugar').toList();
      final smpDeductions = calc.deductionLedger.where((d) => d.inventoryItemId == 'ingredient_smp').toList();

      expect(sugarDeductions.length, equals(1));
      expect(sugarDeductions.first.quantityDeducted, equals(46.0));
      expect(sugarDeductions.first.source, equals('Daily Batch Making'));
      expect(sugarDeductions.first.date, equals('2026-10-06'));

      expect(smpDeductions.length, equals(1));
      expect(smpDeductions.first.quantityDeducted, equals(29.0));
      expect(smpDeductions.first.source, equals('Daily Batch Making'));
      expect(smpDeductions.first.date, equals('2026-10-06'));
    });

    test('3. StockLedgerCalculator correctly formats date-wise ledger rows for Sugar and Poly Film', () {
      final sugarItem = InventoryStockService.getBaselineItems().firstWhere((i) => i.id == 'ingredient_sugar');

      final deductions = [
        StockDeductionEntry(
          id: 'DED-SUGAR-1',
          date: '2026-10-06',
          time: '10:00 AM',
          source: 'Daily Batch Making',
          referenceId: 'BR-1',
          batchNo: 'BT-20261006-LASSI-01',
          productName: 'Lassi',
          inventoryItemId: 'ingredient_sugar',
          inventoryItemName: 'Sugar',
          quantityDeducted: 46.0,
          unit: 'kg',
          notes: 'Batch formulation',
        ),
      ];

      final ledger = StockLedgerCalculator.calculateMonthlyLedger(
        item: sugarItem,
        month: DateTime(2026, 10, 1),
        inwardLedger: [],
        deductionLedger: deductions,
      );

      expect(ledger.openingStock, equals(sugarItem.initialTotalQty));
      expect(ledger.totalIssues, equals(46.0));
      expect(ledger.closingStock, equals(sugarItem.initialTotalQty - 46.0));

      final day6Row = ledger.rows.firstWhere((r) => r.date.day == 6);
      expect(day6Row.issuedQty, equals(46.0));
      expect(day6Row.balanceStock, equals(sugarItem.initialTotalQty - 46.0));
      expect(day6Row.particulars, equals('Issued for Lassi'));

      // Verify binary XLSX workbook generation
      final xlsxBytes = ledger.toXlsx();
      expect(xlsxBytes, isNotEmpty);
      expect(xlsxBytes.length, greaterThan(1000));
    });

    test('4. Reactive ProviderContainer updates inventoryStockProvider when ProductionNotifier logs a record', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Trigger initial read and let init() finish
      container.read(inventoryStockProvider);
      await Future.delayed(const Duration(milliseconds: 50));

      final testRecord = const ProductionRecord(
        recordId: 'PR-TEST-REALTIME',
        date: '2026-10-06',
        time: '02:00 PM',
        shift: 'Shift A',
        employeeId: 'EMP-01',
        employeeName: 'Biraj Goswami',
        productId: '9900007',
        productName: 'Lassi 200 ml',
        batchNo: 'BT-REALTIME-01',
        quantityProduced: 200.0,
        unit: 'Litres',
        cratesProduced: 33.3,
        piecesProduced: 1000,
      );

      container.read(productionProvider.notifier).state =
          container.read(productionProvider).copyWith(allRecords: [testRecord]);

      // Allow microtask to process
      await Future.delayed(const Duration(milliseconds: 30));

      final updatedStock = container.read(inventoryStockProvider);
      expect(updatedStock.deductionLedger.any((d) => d.referenceId == 'PR-TEST-REALTIME'), isTrue);
      final lassiCupDeduction = updatedStock.deductionLedger.firstWhere((d) => d.referenceId == 'PR-TEST-REALTIME');
      expect(lassiCupDeduction.inventoryItemId, equals('cup_lassi_200'));
      expect(lassiCupDeduction.quantityDeducted, equals(1000.0));
    });

    testWidgets('5. StockPage date-wise daily stock report ledger updates automatically for Production Record', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1280, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final now = DateTime.now();
      final dateIso = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final testRecord = ProductionRecord(
        recordId: 'PR-TEST-LASSI',
        date: dateIso,
        time: '10:00 AM',
        shift: 'Shift A',
        employeeId: 'EMP-01',
        employeeName: 'Biraj Goswami',
        productId: '9900007',
        productName: 'Lassi 200 ml',
        batchNo: 'BT-${now.year}-LASSI-01',
        quantityProduced: 200.0,
        unit: 'Litres',
        cratesProduced: 33.3,
        piecesProduced: 5555,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: StockPage(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Before our new production record, 5,555 pcs deduction does NOT exist
      expect(find.textContaining('5,555'), findsNothing);

      // Now record a new production entry dynamically (simulating user saving in Production Register)
      container.read(productionProvider.notifier).state =
          container.read(productionProvider).copyWith(allRecords: [testRecord]);

      // Pump to trigger widget rebuild without page navigation or reload
      await tester.pumpAndSettle();

      // Since Lassi Cup (200ml) is the default active material in StockPage,
      // verify the ledger table automatically and reactively shows Issued Quantity 5,555 pcs and clean simplified particulars!
      expect(find.textContaining('5,555'), findsWidgets);
      expect(find.textContaining('Issued for Lassi 200 ml'), findsOneWidget);

      // Verify Issued Quantity cells do NOT contain an edit pencil icon
      expect(find.byTooltip('Edit Issued on ${now.day}'), findsNothing);
    });

    test('6. Adding stock in boxes and subsequent addition in pcs on the same day accumulates cumulative receipts in ledger', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(inventoryStockProvider.notifier);
      final item = container.read(inventoryStockProvider).allItems.firstWhere((i) => i.id == 'cup_lassi_200');

      // 1. First inward addition: 10 boxes (10 * 2500 = 25,000 pcs)
      await notifier.addInwardStock(
        itemId: item.id,
        quantity: 25000.0,
        packages: 10.0,
        date: '2026-10-06',
        time: '09:30 AM',
        loggedBy: 'Biraj Goswami',
        notes: 'Morning shipment 10 boxes',
      );

      var state = container.read(inventoryStockProvider);
      var ledger = StockLedgerCalculator.calculateMonthlyLedger(
        item: item,
        month: DateTime(2026, 10, 1),
        inwardLedger: state.inwardLedger,
        deductionLedger: state.deductionLedger,
      );

      var day6Row = ledger.rows.firstWhere((r) => r.date.day == 6);
      expect(day6Row.receiptQty, equals(25000.0));
      expect(day6Row.inwardEntries.length, equals(1));

      // 2. Second inward addition on the SAME day: 500 loose pcs
      await notifier.addInwardStock(
        itemId: item.id,
        quantity: 500.0,
        packages: 0.2,
        date: '2026-10-06',
        time: '01:15 PM',
        loggedBy: 'Biraj Goswami',
        notes: 'Loose pieces top-up',
      );

      state = container.read(inventoryStockProvider);
      ledger = StockLedgerCalculator.calculateMonthlyLedger(
        item: item,
        month: DateTime(2026, 10, 1),
        inwardLedger: state.inwardLedger,
        deductionLedger: state.deductionLedger,
      );

      day6Row = ledger.rows.firstWhere((r) => r.date.day == 6);
      // Verify that the previous 25,000 pcs was NOT erased and is summed with 500 pcs!
      expect(day6Row.receiptQty, equals(25500.0));
      expect(day6Row.inwardEntries.length, equals(2));
      expect(day6Row.particulars.contains('Received'), isTrue);

      // 3. Third inward addition on the SAME day: 2 more boxes (5,000 pcs)
      await notifier.addInwardStock(
        itemId: item.id,
        quantity: 5000.0,
        packages: 2.0,
        date: '2026-10-06',
        time: '04:45 PM',
        loggedBy: 'Biraj Goswami',
        notes: 'Evening shipment 2 boxes',
      );

      state = container.read(inventoryStockProvider);
      ledger = StockLedgerCalculator.calculateMonthlyLedger(
        item: item,
        month: DateTime(2026, 10, 1),
        inwardLedger: state.inwardLedger,
        deductionLedger: state.deductionLedger,
      );

      day6Row = ledger.rows.firstWhere((r) => r.date.day == 6);
      // Verify cumulative total: 25,000 + 500 + 5,000 = 30,500 pcs!
      expect(day6Row.receiptQty, equals(30500.0));
      expect(day6Row.inwardEntries.length, equals(3));
      expect(day6Row.particulars.contains('Received'), isTrue);
    });

    test('7. Excel file export generates single decorative workbook with exact filename pattern', () {
      final item = InventoryStockService.getBaselineItems().firstWhere((i) => i.id == 'cup_lassi_200');
      final month = DateTime(2026, 8, 1); // August 2026
      final monthStr = DateFormat('MMMM_yyyy').format(month);

      // Verify exact requested filename pattern: Stock_Ledger_cup_lassi_200_August_2026.xlsx
      final expectedFilename = 'Stock_Ledger_${item.id}_$monthStr.xlsx';
      expect(expectedFilename, equals('Stock_Ledger_cup_lassi_200_August_2026.xlsx'));

      final ledger = StockLedgerCalculator.calculateMonthlyLedger(
        item: item,
        month: month,
        inwardLedger: [
          InwardStockEntry(
            id: 'INW-AUG-1',
            itemId: item.id,
            itemName: item.name,
            quantity: 5000.0,
            packages: 2.0,
            unit: item.baseUnit,
            packagingUnit: item.packagingUnit,
            date: '2026-08-05',
            time: '10:00 AM',
            loggedBy: 'Biraj Goswami',
            notes: 'Batch shipment',
          ),
        ],
        deductionLedger: [],
      );

      final bytes = ledger.toXlsx();
      expect(bytes, isNotEmpty);

      // Decode Excel workbook and verify decorative structure
      final decodedExcel = Excel.decodeBytes(bytes);
      expect(decodedExcel.tables.containsKey('Stock Ledger'), isTrue);
      final sheet = decodedExcel.tables['Stock Ledger']!;

      // Verify Title Banner
      expect(sheet.rows[0][0]?.value.toString(), contains('CASEYA DAIRY PLANT'));
      // Verify Subtitle
      expect(sheet.rows[1][0]?.value.toString(), contains('Lassi Cup'));
      // Verify KPI Summary Labels & Values
      expect(sheet.rows[2][0]?.value.toString(), equals('Opening Stock'));
      expect(sheet.rows[2][1]?.value.toString(), equals('Total Received'));
      expect(sheet.rows[2][2]?.value.toString(), equals('Total Issued'));
      expect(sheet.rows[2][3]?.value.toString(), equals('Closing Balance'));
      // Verify Table Column Headers
      expect(sheet.rows[5][0]?.value.toString(), equals('Date'));
      expect(sheet.rows[5][1]?.value.toString(), contains('Particulars'));
      expect(sheet.rows[5][3]?.value.toString(), contains('Received Qty'));
      expect(sheet.rows[5][4]?.value.toString(), contains('Issued Qty'));
      expect(sheet.rows[5][5]?.value.toString(), contains('Balance Stock'));
    });

    test('8. Back-dated production entry for Lassi updates ledger for both Lassi Cup (200ml) and Alum Foil (Blue) 80gm', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Simulate back date entry in August: 2026-08-15
      final backDate = DateTime(2026, 8, 15);
      final lassiProduct = DairyProducts.officialProducts.firstWhere((p) => p.productId == '9900007');

      // Set up production notifier state as user would on the form
      final prodNotifier = container.read(productionProvider.notifier);
      prodNotifier.setDate(backDate);
      prodNotifier.selectProduct(lassiProduct);
      prodNotifier.updateFromPieces(20);

      // Verify state before recording
      expect(container.read(productionProvider).selectedDate, equals(backDate));
      expect(container.read(productionProvider).pieces, equals(20));

      // Record production entry
      final success = await prodNotifier.recordProductionEntry(employeeId: 'EMP-01');
      expect(success, isTrue);

      // Check stock state
      final stockState = container.read(inventoryStockProvider);

      // 1. Check deduction ledger has entries for both cup_lassi_200 and foil_blue_80
      final cupDeductions = stockState.deductionLedger
          .where((d) => d.inventoryItemId == 'cup_lassi_200' && d.date == '2026-08-15')
          .toList();
      final foilDeductions = stockState.deductionLedger
          .where((d) => d.inventoryItemId == 'foil_blue_80' && d.date == '2026-08-15')
          .toList();

      expect(cupDeductions.isNotEmpty, isTrue, reason: 'cup_lassi_200 deduction should exist for 2026-08-15');
      expect(foilDeductions.isNotEmpty, isTrue, reason: 'foil_blue_80 deduction should exist for 2026-08-15');
      expect(cupDeductions.first.quantityDeducted, equals(20.0));
      expect(foilDeductions.first.quantityDeducted, equals(20.0));

      // 2. Check August 2026 Monthly Stock Ledger for cup_lassi_200
      final cupItem = stockState.allItems.firstWhere((i) => i.id == 'cup_lassi_200');
      final cupLedger = StockLedgerCalculator.calculateMonthlyLedger(
        item: cupItem,
        month: DateTime(2026, 8, 1),
        inwardLedger: stockState.inwardLedger,
        deductionLedger: stockState.deductionLedger,
      );

      final cupDay15 = cupLedger.rows.firstWhere((r) => r.date.day == 15);
      expect(cupDay15.issuedQty, equals(20.0));
      expect(cupDay15.hasActivity, isTrue);

      // 3. Check August 2026 Monthly Stock Ledger for foil_blue_80
      final foilItem = stockState.allItems.firstWhere((i) => i.id == 'foil_blue_80');
      final foilLedger = StockLedgerCalculator.calculateMonthlyLedger(
        item: foilItem,
        month: DateTime(2026, 8, 1),
        inwardLedger: stockState.inwardLedger,
        deductionLedger: stockState.deductionLedger,
      );

      final foilDay15 = foilLedger.rows.firstWhere((r) => r.date.day == 15);
      expect(foilDay15.issuedQty, equals(20.0));
      expect(foilDay15.hasActivity, isTrue);

      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
  });
}
