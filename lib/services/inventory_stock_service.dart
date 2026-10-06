import 'package:flutter/material.dart';
import '../core/constants/dairy_products.dart';
import '../models/inventory_item_model.dart';
import '../models/operations_models.dart';
import '../models/standardization_record.dart';
import '../models/batch_record_model.dart';

class InventoryCalculationResult {
  final List<InventoryItemModel> items;
  final List<StockDeductionEntry> deductionLedger;
  final double totalSugarUsedKg;
  final double totalSmpUsedKg;
  final int totalCupsUsed;
  final int totalFoilsUsed;
  final int totalSpoonsUsed;

  const InventoryCalculationResult({
    required this.items,
    required this.deductionLedger,
    required this.totalSugarUsedKg,
    required this.totalSmpUsedKg,
    required this.totalCupsUsed,
    required this.totalFoilsUsed,
    this.totalSpoonsUsed = 0,
  });
}

class InventoryStockService {
  /// Canonical baseline inventory items in the plant
  static List<InventoryItemModel> getBaselineItems() {
    return const [
      // --- CUPS (7 Items) ---
      InventoryItemModel(
        id: 'cup_lassi_200',
        name: 'Lassi Cup (200ml)',
        category: 'Cups',
        baseUnit: 'pcs',
        packagingUnit: 'Boxes',
        itemsPerPackage: 2500.0,
        initialPackages: 33.0,
        initialTotalQty: 82500.0,
        details: '1 box contains 2500 cups',
        icon: Icons.local_drink_rounded,
        criticalLimit: 75000.0,
        adequateLimit: 90000.0,
        limitDescription: 'Adequate: >90,000 • Low: 70,000–90,000 • Critical: <75,000',
      ),
      InventoryItemModel(
        id: 'cup_s80',
        name: 'S80 Cup (Sweet Curd 80g)',
        category: 'Cups',
        baseUnit: 'pcs',
        packagingUnit: 'Boxes',
        itemsPerPackage: 2400.0,
        initialPackages: 22.0,
        initialTotalQty: 52800.0,
        details: '1 box contains 2400 cups',
        icon: Icons.takeout_dining_rounded,
        criticalLimit: 30000.0,
        adequateLimit: 42000.0,
        limitDescription: 'Adequate: >42,000 • Low: 30,000–42,000 • Critical: <30,000',
      ),
      InventoryItemModel(
        id: 'cup_s200',
        name: 'S200 Cup (Sweet Curd 200g)',
        category: 'Cups',
        baseUnit: 'pcs',
        packagingUnit: 'Boxes',
        itemsPerPackage: 2000.0,
        initialPackages: 11.0,
        initialTotalQty: 22000.0,
        details: '1 box contains 2000 cups',
        icon: Icons.takeout_dining_rounded,
        criticalLimit: 3500.0,
        adequateLimit: 4900.0,
        limitDescription: 'Adequate: >4,900 • Low: 3,500–4,900 • Critical: <3,500',
      ),
      InventoryItemModel(
        id: 'cup_s400',
        name: 'S400 Cup (Sweet Curd 400g)',
        category: 'Cups',
        baseUnit: 'pcs',
        packagingUnit: 'Boxes',
        itemsPerPackage: 1000.0,
        initialPackages: 40.0,
        initialTotalQty: 40000.0,
        details: '1 box contains 1000 cups',
        icon: Icons.takeout_dining_rounded,
        criticalLimit: 10000.0,
        adequateLimit: 14000.0,
        limitDescription: 'Adequate: >14,000 • Low: 10,000–14,000 • Critical: <10,000',
      ),
      InventoryItemModel(
        id: 'cup_p80',
        name: 'P80 Cup (Plain Curd 80g)',
        category: 'Cups',
        baseUnit: 'pcs',
        packagingUnit: 'Boxes',
        itemsPerPackage: 2400.0,
        initialPackages: 16.0,
        initialTotalQty: 38400.0,
        details: '1 box contains 2400 cups',
        icon: Icons.takeout_dining_rounded,
        criticalLimit: 6000.0,
        adequateLimit: 7000.0,
        limitDescription: 'Adequate: >7,000 • Low: 6,000–7,000 • Critical: <6,000',
      ),
      InventoryItemModel(
        id: 'cup_p200',
        name: 'P200 Cup (Plain Curd 200g)',
        category: 'Cups',
        baseUnit: 'pcs',
        packagingUnit: 'Boxes',
        itemsPerPackage: 2000.0,
        initialPackages: 5.0,
        initialTotalQty: 10000.0,
        details: '1 box contains 2000 cups',
        icon: Icons.takeout_dining_rounded,
        criticalLimit: 2400.0,
        adequateLimit: 2800.0,
        limitDescription: 'Adequate: >2,800 • Low: 2,400–2,800 • Critical: <2,400',
      ),
      InventoryItemModel(
        id: 'cup_p400',
        name: 'P400 Cup (Plain Curd 400g)',
        category: 'Cups',
        baseUnit: 'pcs',
        packagingUnit: 'Boxes',
        itemsPerPackage: 1000.0,
        initialPackages: 47.0,
        initialTotalQty: 47000.0,
        details: '1 box contains 1000 cups',
        icon: Icons.takeout_dining_rounded,
        criticalLimit: 6000.0,
        adequateLimit: 7000.0,
        limitDescription: 'Adequate: >7,000 • Low: 6,000–7,000 • Critical: <6,000',
      ),

      // --- POLY ROLL (8 Items) ---
      InventoryItemModel(
        id: 'poly_std_500',
        name: 'Poly Film STD 500ml',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 8.0,
        initialTotalQty: 8.0,
        details: '1 roll • Standardized milk 500ml film',
        icon: Icons.album_rounded,
        criticalLimit: 3.0,
        adequateLimit: 5.0,
        limitDescription: 'Adequate: >5 • Low: 3–5 • Critical: <3',
      ),
      InventoryItemModel(
        id: 'poly_std_250',
        name: 'Poly Film STD 250ml',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 42.0,
        initialTotalQty: 42.0,
        details: '1 roll • Standardized milk 250ml film',
        icon: Icons.album_rounded,
        criticalLimit: 2.0,
        adequateLimit: 4.0,
        limitDescription: 'Adequate: >4 • Low: 2–4 • Critical: <2',
      ),
      InventoryItemModel(
        id: 'poly_std_200',
        name: 'Poly Film STD 200ml',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 15.0,
        initialTotalQty: 15.0,
        details: '1 roll • Standardized milk 200ml film',
        icon: Icons.album_rounded,
        criticalLimit: 2.0,
        adequateLimit: 4.0,
        limitDescription: 'Adequate: >4 • Low: 2–4 • Critical: <2',
      ),
      InventoryItemModel(
        id: 'poly_sm_500',
        name: 'Poly Film SM+ 500ml',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 5.0,
        initialTotalQty: 5.0,
        details: '1 roll • Smart Plus toned milk 500ml film',
        icon: Icons.album_rounded,
        criticalLimit: 3.0,
        adequateLimit: 5.0,
        limitDescription: 'Adequate: >5 • Low: 3–5 • Critical: <3',
      ),
      InventoryItemModel(
        id: 'poly_scp_400',
        name: 'Poly Film Sweet Curd 400gm',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 3.0,
        initialTotalQty: 3.0,
        details: '1 roll • Sweet curd 400g pouch film',
        icon: Icons.album_rounded,
        criticalLimit: 2.0,
        adequateLimit: 3.0,
        limitDescription: 'Adequate: >3 • Low: 2–3 • Critical: <2',
      ),
      InventoryItemModel(
        id: 'poly_scp_1000',
        name: 'Poly Film Sweet Curd 1kg',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 6.0,
        initialTotalQty: 6.0,
        details: '1 roll • Sweet curd 1kg pouch film',
        icon: Icons.album_rounded,
        criticalLimit: 2.0,
        adequateLimit: 3.0,
        limitDescription: 'Adequate: >3 • Low: 2–3 • Critical: <2',
      ),
      InventoryItemModel(
        id: 'poly_pcp_400',
        name: 'Poly Film Plain Curd 400gm',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 3.0,
        initialTotalQty: 3.0,
        details: '1 roll • Plain curd 400g pouch film',
        icon: Icons.album_rounded,
        criticalLimit: 2.0,
        adequateLimit: 3.0,
        limitDescription: 'Adequate: >3 • Low: 2–3 • Critical: <2',
      ),
      InventoryItemModel(
        id: 'poly_pcp_1000',
        name: 'Poly Film Plain Curd 1kg',
        category: 'Poly Roll',
        baseUnit: 'Rolls',
        packagingUnit: 'Rolls',
        itemsPerPackage: 1.0,
        initialPackages: 7.0,
        initialTotalQty: 7.0,
        details: '1 roll • Plain curd 1kg pouch film',
        icon: Icons.album_rounded,
        criticalLimit: 2.0,
        adequateLimit: 3.0,
        limitDescription: 'Adequate: >3 • Low: 2–3 • Critical: <2',
      ),

      // --- ALUMINIUM FOIL (4 Items) ---
      InventoryItemModel(
        id: 'foil_pink_80',
        name: 'Alum Foil (Pink) 80gm',
        category: 'Aluminium Foil',
        baseUnit: 'lids',
        packagingUnit: 'Boxes',
        itemsPerPackage: 37800.0,
        initialPackages: 22.0,
        initialTotalQty: 831600.0,
        details: '1 box contains 37800 lids',
        icon: Icons.circle_outlined,
        criticalLimit: 30000.0,
        adequateLimit: 42000.0,
        limitDescription: 'Adequate: >42,000 • Low: 30,000–42,000 • Critical: <30,000',
      ),
      InventoryItemModel(
        id: 'foil_pink_200_400',
        name: 'Alum Foil (Pink) 200/400gm',
        category: 'Aluminium Foil',
        baseUnit: 'lids',
        packagingUnit: 'Boxes',
        itemsPerPackage: 25200.0,
        initialPackages: 12.0,
        initialTotalQty: 302400.0,
        details: '1 box contains 25200 lids',
        icon: Icons.circle_outlined,
        criticalLimit: 10000.0,
        adequateLimit: 14000.0,
        limitDescription: 'Adequate: >14,000 • Low: 10,000–14,000 • Critical: <10,000',
      ),
      InventoryItemModel(
        id: 'foil_blue_80',
        name: 'Alum Foil (Blue) 80gm',
        category: 'Aluminium Foil',
        baseUnit: 'lids',
        packagingUnit: 'Boxes',
        itemsPerPackage: 37800.0,
        initialPackages: 69.0,
        initialTotalQty: 2608200.0,
        details: '1 box contains 37800 lids',
        icon: Icons.circle_outlined,
        criticalLimit: 75000.0,
        adequateLimit: 90000.0,
        limitDescription: 'Adequate: >90,000 • Low: 70,000–90,000 • Critical: <75,000',
      ),
      InventoryItemModel(
        id: 'foil_blue_200_400',
        name: 'Alum Foil (Blue) 200/400gm',
        category: 'Aluminium Foil',
        baseUnit: 'lids',
        packagingUnit: 'Boxes',
        itemsPerPackage: 25200.0,
        initialPackages: 35.0,
        initialTotalQty: 882000.0,
        details: '1 box contains 25200 lids',
        icon: Icons.circle_outlined,
        criticalLimit: 10000.0,
        adequateLimit: 14000.0,
        limitDescription: 'Adequate: >14,000 • Low: 10,000–14,000 • Critical: <10,000',
      ),

      // --- SERVING MATERIAL (1 Item) ---
      InventoryItemModel(
        id: 'serving_wooden_spoon',
        name: 'Wooden Spoon',
        category: 'Serving Material',
        baseUnit: 'pieces',
        packagingUnit: 'Boxes',
        itemsPerPackage: 18000.0,
        initialPackages: 7.0,
        initialTotalQty: 126000.0,
        details: '1 box contains 18000 pieces',
        icon: Icons.flatware_rounded,
        criticalLimit: 69000.0,
        adequateLimit: 80500.0,
        limitDescription: 'Adequate: >80,500 • Low: 69,000–80,500 • Critical: <69,000',
      ),

      // --- INGREDIENTS (2 Items) ---
      InventoryItemModel(
        id: 'ingredient_sugar',
        name: 'Sugar',
        category: 'Ingredients',
        baseUnit: 'kg',
        packagingUnit: 'Boxes',
        itemsPerPackage: 50.0,
        initialPackages: 19.0,
        initialTotalQty: 950.0,
        details: '1 box contains 50 kg',
        icon: Icons.inventory_2_rounded,
        criticalLimit: 2250.0,
        adequateLimit: 2700.0,
        limitDescription: 'Adequate: >2,700 kg • Low: 2,250–2,700 kg • Critical: <2,250 kg',
      ),
      InventoryItemModel(
        id: 'ingredient_smp',
        name: 'SMP (Skimmed Milk Powder)',
        category: 'Ingredients',
        baseUnit: 'kg',
        packagingUnit: 'Bags',
        itemsPerPackage: 25.0,
        initialPackages: 57.0,
        initialTotalQty: 1425.0,
        details: '1 bag contains 25kg',
        icon: Icons.grain_rounded,
        criticalLimit: 1500.0,
        adequateLimit: 1750.0,
        limitDescription: 'Adequate: >1,750 kg • Low: 1,500–1,750 kg • Critical: <1,500 kg',
      ),
    ];
  }

  /// Calculates dynamically deducted inventory stock and detailed deduction ledger
  static InventoryCalculationResult calculateInventoryStock({
    required List<ProductionRecord> productionRecords,
    required List<StandardizationRecord> standardizationRecords,
    required List<BatchRecordModel> batchRecords,
    List<InventoryItemModel>? customBaseline,
    Map<String, double>? addedStockMap,
    Map<String, String>? lastUpdatedMap,
  }) {
    final baseline = customBaseline ?? getBaselineItems();
    final Map<String, double> consumedMap = {};
    for (final item in baseline) {
      consumedMap[item.id] = 0.0;
    }

    final List<StockDeductionEntry> ledger = [];

    int totalCupsUsed = 0;
    int totalFoilsUsed = 0;
    int totalSpoonsUsed = 0;
    double totalSugarUsedKg = 0.0;
    double totalSmpUsedKg = 0.0;

    // =========================================================================
    // 1. DEDUCT CUPS & FOILS FROM PRODUCTION REGISTER ENTRIES
    // =========================================================================
    for (final record in productionRecords) {
      final pcs = _resolvePieces(record);
      if (pcs <= 0) continue;

      final pId = record.productId.trim().toLowerCase();
      final pName = record.productName.trim().toLowerCase();
      bool isCurdCup = false;

      // --- Case 1: Lassi 200 ml ---
      // Uses: Lassi Cup (200ml) & Foil 80gm (Blue)
      if (pId == '9900007' || pName.contains('lassi')) {
        consumedMap['cup_lassi_200'] = (consumedMap['cup_lassi_200'] ?? 0.0) + pcs;
        consumedMap['foil_blue_80'] = (consumedMap['foil_blue_80'] ?? 0.0) + pcs;
        totalCupsUsed += pcs;
        totalFoilsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-CUP-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'cup_lassi_200',
          inventoryItemName: 'Lassi Cup (200ml)',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 cup per unit produced for Lassi 200 ml',
        ));

        ledger.add(StockDeductionEntry(
          id: 'DED-FOIL-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'foil_blue_80',
          inventoryItemName: 'Foil 80gm (Blue)',
          quantityDeducted: pcs.toDouble(),
          unit: 'lids',
          notes: 'Alum Foil (Blue) 80gm used 1:1 for Lassi 200 ml',
        ));
      }
      // --- Case 2: Sweet Curd Cup S80 ---
      // Uses: S80 Cup (Sweet Curd 80g) & Foil 80gm (Pink) & Wooden Spoon (1:1)
      else if (pId == '9900025' || (pName.contains('sweet curd') && (pName.contains('80') || pName.contains('s80')))) {
        isCurdCup = true;
        consumedMap['cup_s80'] = (consumedMap['cup_s80'] ?? 0.0) + pcs;
        consumedMap['foil_pink_80'] = (consumedMap['foil_pink_80'] ?? 0.0) + pcs;
        totalCupsUsed += pcs;
        totalFoilsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-CUP-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'cup_s80',
          inventoryItemName: 'S80 Cup (Sweet Curd 80g)',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 cup per unit produced for Sweet Curd S80',
        ));

        ledger.add(StockDeductionEntry(
          id: 'DED-FOIL-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'foil_pink_80',
          inventoryItemName: 'Foil 80gm (Pink)',
          quantityDeducted: pcs.toDouble(),
          unit: 'lids',
          notes: 'Alum Foil (Pink) 80gm used 1:1 for S80',
        ));
      }
      // --- Case 3: Sweet Curd Cup S200 ---
      // Uses: S200 Cup (Sweet Curd 200g) & Foil 200/400gm (Pink) & Wooden Spoon (1:1)
      else if (pId == '9900011' || (pName.contains('sweet curd') && (pName.contains('200') || pName.contains('s200')))) {
        isCurdCup = true;
        consumedMap['cup_s200'] = (consumedMap['cup_s200'] ?? 0.0) + pcs;
        consumedMap['foil_pink_200_400'] = (consumedMap['foil_pink_200_400'] ?? 0.0) + pcs;
        totalCupsUsed += pcs;
        totalFoilsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-CUP-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'cup_s200',
          inventoryItemName: 'S200 Cup (Sweet Curd 200g)',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 cup per unit produced for Sweet Curd S200',
        ));

        ledger.add(StockDeductionEntry(
          id: 'DED-FOIL-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'foil_pink_200_400',
          inventoryItemName: 'Foil 200/400gm (Pink)',
          quantityDeducted: pcs.toDouble(),
          unit: 'lids',
          notes: 'Alum Foil (Pink) 200/400gm used 1:1 for S200',
        ));
      }
      // --- Case 4: Sweet Curd Cup S400 ---
      // Uses: S400 Cup (Sweet Curd 400g) & Foil 200/400gm (Pink) & Wooden Spoon (1:1)
      // Note: Must NOT match Sweet Curd Pouch SCP400
      else if ((pId == '9900010' || (pName.contains('sweet curd') && pName.contains('400') && (pName.contains('cup') || pName.contains('s400')))) &&
          !pName.contains('pouch') && !pId.contains('scp')) {
        isCurdCup = true;
        consumedMap['cup_s400'] = (consumedMap['cup_s400'] ?? 0.0) + pcs;
        consumedMap['foil_pink_200_400'] = (consumedMap['foil_pink_200_400'] ?? 0.0) + pcs;
        totalCupsUsed += pcs;
        totalFoilsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-CUP-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'cup_s400',
          inventoryItemName: 'S400 Cup (Sweet Curd 400g)',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 cup per unit produced for Sweet Curd S400',
        ));

        ledger.add(StockDeductionEntry(
          id: 'DED-FOIL-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'foil_pink_200_400',
          inventoryItemName: 'Foil 200/400gm (Pink)',
          quantityDeducted: pcs.toDouble(),
          unit: 'lids',
          notes: 'Alum Foil (Pink) 200/400gm used 1:1 for S400',
        ));
      }
      // --- Case 5: Plain Curd Cup P80 ---
      // Uses: P80 Cup (Plain Curd 80g) & Foil 80gm (Blue) & Wooden Spoon (1:1)
      // (Shared with Lassi 200ml)
      else if (pId == '9900026' || (pName.contains('plain curd') && (pName.contains('80') || pName.contains('p80')))) {
        isCurdCup = true;
        consumedMap['cup_p80'] = (consumedMap['cup_p80'] ?? 0.0) + pcs;
        consumedMap['foil_blue_80'] = (consumedMap['foil_blue_80'] ?? 0.0) + pcs;
        totalCupsUsed += pcs;
        totalFoilsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-CUP-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'cup_p80',
          inventoryItemName: 'P80 Cup (Plain Curd 80g)',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 cup per unit produced for Plain Curd P80',
        ));

        ledger.add(StockDeductionEntry(
          id: 'DED-FOIL-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'foil_blue_80',
          inventoryItemName: 'Foil 80gm (Blue)',
          quantityDeducted: pcs.toDouble(),
          unit: 'lids',
          notes: 'Alum Foil (Blue) 80gm used 1:1 for P80 (Shared with Lassi)',
        ));
      }
      // --- Case 6: Plain Curd Cup P200 ---
      // Uses: P200 Cup (Plain Curd 200g) & Foil 200/400gm (Blue) & Wooden Spoon (1:1)
      else if (pId == 'p200' || (pName.contains('plain curd') && (pName.contains('200') || pName.contains('p200')))) {
        isCurdCup = true;
        consumedMap['cup_p200'] = (consumedMap['cup_p200'] ?? 0.0) + pcs;
        consumedMap['foil_blue_200_400'] = (consumedMap['foil_blue_200_400'] ?? 0.0) + pcs;
        totalCupsUsed += pcs;
        totalFoilsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-CUP-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'cup_p200',
          inventoryItemName: 'P200 Cup (Plain Curd 200g)',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 cup per unit produced for Plain Curd P200',
        ));

        ledger.add(StockDeductionEntry(
          id: 'DED-FOIL-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'foil_blue_200_400',
          inventoryItemName: 'Foil 200/400gm (Blue)',
          quantityDeducted: pcs.toDouble(),
          unit: 'lids',
          notes: 'Alum Foil (Blue) 200/400gm used 1:1 for P200',
        ));
      }
      // --- Case 7: Plain Curd Cup P400 ---
      // Uses: P400 Cup (Plain Curd 400g) & Foil 200/400gm (Blue) & Wooden Spoon (1:1)
      // Note: Must NOT match Plain Curd Pouch PCP400
      else if ((pId == '9900013' || (pName.contains('plain curd') && pName.contains('400') && (pName.contains('cup') || pName.contains('p400')))) &&
          !pName.contains('pouch') && !pId.contains('pcp')) {
        isCurdCup = true;
        consumedMap['cup_p400'] = (consumedMap['cup_p400'] ?? 0.0) + pcs;
        consumedMap['foil_blue_200_400'] = (consumedMap['foil_blue_200_400'] ?? 0.0) + pcs;
        totalCupsUsed += pcs;
        totalFoilsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-CUP-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'cup_p400',
          inventoryItemName: 'P400 Cup (Plain Curd 400g)',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 cup per unit produced for Plain Curd P400',
        ));

        ledger.add(StockDeductionEntry(
          id: 'DED-FOIL-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'foil_blue_200_400',
          inventoryItemName: 'Foil 200/400gm (Blue)',
          quantityDeducted: pcs.toDouble(),
          unit: 'lids',
          notes: 'Alum Foil (Blue) 200/400gm used 1:1 for P400',
        ));
      }

      // --- Wooden Spoon Deduction for Curd Cups (S80, S200, S400, P80, P200, P400) ---
      // 1 cup = 1 wooden spoon allocated for dispatch
      if (isCurdCup) {
        consumedMap['serving_wooden_spoon'] = (consumedMap['serving_wooden_spoon'] ?? 0.0) + pcs;
        totalSpoonsUsed += pcs;

        ledger.add(StockDeductionEntry(
          id: 'DED-SPOON-${record.recordId}',
          date: record.date,
          time: record.time,
          source: 'Production Register',
          referenceId: record.recordId,
          batchNo: record.batchNo,
          productName: record.productName,
          inventoryItemId: 'serving_wooden_spoon',
          inventoryItemName: 'Wooden Spoon',
          quantityDeducted: pcs.toDouble(),
          unit: 'pcs',
          notes: '1 wooden spoon per cup allocated for dispatch (${record.productName})',
        ));
      }
    }

    // =========================================================================
    // 2. DEDUCT SUGAR & SMP WITH DUAL CROSS-VERIFICATION
    // =========================================================================
    // Track unique processed batch keys to prevent double-counting across
    // Milk Standardization, Daily Batch Making, and Production Registers.
    final Set<String> processedBatchKeys = {};

    // A. Process batches from Milk Standardization
    for (final std in standardizationRecords) {
      final sugar = std.sugarRequired;
      final smp = std.smpRequired;

      if (sugar <= 0 && smp <= 0) continue;

      // Construct a unified key for this batch
      final batchKey = _normalizeBatchKey(
        recordId: std.recordId,
        date: std.date,
        productName: std.targetProductName,
      );

      if (processedBatchKeys.contains(batchKey)) continue;
      processedBatchKeys.add(batchKey);

      // Check cross-verification against Production Records or Batch Making Records
      final isCrossVerifiedWithProd = productionRecords.any((p) =>
          (p.standardizationRecordId != null && p.standardizationRecordId == std.recordId) ||
          (p.batchNo.isNotEmpty && std.notes.contains(p.batchNo)) ||
          (p.date == std.date &&
              (p.productName.toLowerCase().contains(std.targetProductName.toLowerCase()) ||
                  std.targetProductName.toLowerCase().contains(p.productName.toLowerCase()))));

      final isCrossVerifiedWithBatch = batchRecords.any((b) =>
          b.batchNumber == std.recordId ||
          (b.notes != null && b.notes!.contains(std.recordId)) ||
          (b.productionDate == std.date &&
              (b.productName.toLowerCase().contains(std.targetProductName.toLowerCase()) ||
                  std.targetProductName.toLowerCase().contains(b.productName.toLowerCase()))));

      final isCrossVerified = isCrossVerifiedWithProd || isCrossVerifiedWithBatch;

      final verificationTag = isCrossVerified
          ? '✓ Cross-Verified (Standardization + ${isCrossVerifiedWithProd ? 'Production' : 'Batch Register'})'
          : 'Standardization Batch Formulation';

      if (sugar > 0) {
        consumedMap['ingredient_sugar'] = (consumedMap['ingredient_sugar'] ?? 0.0) + sugar;
        totalSugarUsedKg += sugar;

        ledger.add(StockDeductionEntry(
          id: 'DED-SUGAR-${std.recordId}',
          date: std.date,
          time: std.time,
          source: 'Milk Standardization',
          referenceId: std.recordId,
          batchNo: std.recordId,
          productName: std.targetProductName,
          inventoryItemId: 'ingredient_sugar',
          inventoryItemName: 'Sugar',
          quantityDeducted: sugar,
          unit: 'kg',
          isCrossVerified: isCrossVerified,
          notes: '$verificationTag • Batch Formulation: ${std.targetProductName}',
        ));
      }

      if (smp > 0) {
        consumedMap['ingredient_smp'] = (consumedMap['ingredient_smp'] ?? 0.0) + smp;
        totalSmpUsedKg += smp;

        ledger.add(StockDeductionEntry(
          id: 'DED-SMP-${std.recordId}',
          date: std.date,
          time: std.time,
          source: 'Milk Standardization',
          referenceId: std.recordId,
          batchNo: std.recordId,
          productName: std.targetProductName,
          inventoryItemId: 'ingredient_smp',
          inventoryItemName: 'SMP (Skimmed Milk Powder)',
          quantityDeducted: smp,
          unit: 'kg',
          isCrossVerified: isCrossVerified,
          notes: '$verificationTag • Batch Formulation: ${std.targetProductName}',
        ));
      }
    }

    // B. Process batches recorded directly in Daily Batch Making that were NOT in Standardization
    for (final batch in batchRecords) {
      final batchKey = _normalizeBatchKey(
        recordId: batch.id,
        date: batch.productionDate,
        productName: batch.productName,
      );

      // If already processed via Standardization, skip double-deduction!
      if (processedBatchKeys.contains(batchKey) ||
          processedBatchKeys.contains(batch.batchNumber.toLowerCase().trim())) {
        continue;
      }
      processedBatchKeys.add(batchKey);
      if (batch.batchNumber.trim().isNotEmpty) {
        processedBatchKeys.add(batch.batchNumber.toLowerCase().trim());
      }

      // Check ingredients
      for (final ing in batch.ingredients) {
        final ingName = ing.ingredientName.trim().toLowerCase();
        final qty = ing.quantity;
        if (qty <= 0) continue;

        if (ingName.contains('sugar')) {
          consumedMap['ingredient_sugar'] = (consumedMap['ingredient_sugar'] ?? 0.0) + qty;
          totalSugarUsedKg += qty;

          ledger.add(StockDeductionEntry(
            id: 'DED-SUGAR-${batch.id}-${ing.id}',
            date: batch.productionDate,
            time: '08:00 AM',
            source: 'Daily Batch Making',
            referenceId: batch.id,
            batchNo: batch.batchNumber,
            productName: batch.productName,
            inventoryItemId: 'ingredient_sugar',
            inventoryItemName: 'Sugar',
            quantityDeducted: qty,
            unit: 'kg',
            isCrossVerified: true,
            notes: 'Batch Making Record: ${batch.batchNumber} (${batch.productName})',
          ));
        } else if (ingName.contains('smp') || ingName.contains('skimmed milk powder')) {
          consumedMap['ingredient_smp'] = (consumedMap['ingredient_smp'] ?? 0.0) + qty;
          totalSmpUsedKg += qty;

          ledger.add(StockDeductionEntry(
            id: 'DED-SMP-${batch.id}-${ing.id}',
            date: batch.productionDate,
            time: '08:00 AM',
            source: 'Daily Batch Making',
            referenceId: batch.id,
            batchNo: batch.batchNumber,
            productName: batch.productName,
            inventoryItemId: 'ingredient_smp',
            inventoryItemName: 'SMP (Skimmed Milk Powder)',
            quantityDeducted: qty,
            unit: 'kg',
            isCrossVerified: true,
            notes: 'Batch Making Record: ${batch.batchNumber} (${batch.productName})',
          ));
        }
      }
    }

    // Sort ledger by date/timestamp descending
    ledger.sort((a, b) => b.date.compareTo(a.date));

    // Construct updated items list
    final List<InventoryItemModel> updatedItems = baseline.map((item) {
      final consumed = consumedMap[item.id] ?? 0.0;
      final added = addedStockMap?[item.id] ?? item.addedQty;
      final updatedTime = lastUpdatedMap?[item.id] ?? item.lastUpdated;
      return item.copyWith(
        consumedQty: consumed,
        addedQty: added,
        lastUpdated: updatedTime,
      );
    }).toList();

    return InventoryCalculationResult(
      items: updatedItems,
      deductionLedger: ledger,
      totalSugarUsedKg: totalSugarUsedKg,
      totalSmpUsedKg: totalSmpUsedKg,
      totalCupsUsed: totalCupsUsed,
      totalFoilsUsed: totalFoilsUsed,
      totalSpoonsUsed: totalSpoonsUsed,
    );
  }

  /// Resolves the exact pieces produced for any production record
  static int _resolvePieces(ProductionRecord record) {
    if (record.piecesProduced > 0) {
      return record.piecesProduced;
    }
    // Attempt to calculate from crates or volume
    for (final p in DairyProducts.officialProducts) {
      if (p.productId == record.productId ||
          p.productName.toLowerCase() == record.productName.toLowerCase()) {
        if (record.cratesProduced > 0 && p.piecesPerCrate > 0) {
          return (record.cratesProduced * p.piecesPerCrate).round();
        }
        if (record.quantityProduced > 0 && p.packSizeInBaseUnit > 0) {
          return (record.quantityProduced / p.packSizeInBaseUnit).round();
        }
      }
    }
    return 0;
  }

  static String _normalizeBatchKey({
    required String recordId,
    required String date,
    required String productName,
  }) {
    final cleanId = recordId.trim().toLowerCase();
    if (cleanId.isNotEmpty && cleanId != 'null') {
      return cleanId;
    }
    return '${date.trim()}_${productName.trim().toLowerCase()}';
  }
}
