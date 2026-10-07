import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item_model.dart';
import '../models/stock_ledger_entry_model.dart';
import '../services/inventory_stock_service.dart';
import '../services/local_storage_service.dart';
import 'production_provider.dart';
import 'standardization_provider.dart';
import 'batch_records_provider.dart';

class InventoryStockState {
  final List<InventoryItemModel> allItems;
  final List<StockDeductionEntry> deductionLedger;
  final List<InwardStockEntry> inwardLedger;
  final Map<String, double> addedStockMap;
  final Map<String, String> lastUpdatedMap;
  final Map<String, String> lastUpdatedByMap;
  final String selectedCategory;
  final String searchQuery;
  final double totalSugarUsedKg;
  final double totalSmpUsedKg;
  final int totalCupsUsed;
  final int totalFoilsUsed;
  final int totalSpoonsUsed;

  const InventoryStockState({
    required this.allItems,
    required this.deductionLedger,
    this.inwardLedger = const [],
    this.addedStockMap = const {},
    this.lastUpdatedMap = const {},
    this.lastUpdatedByMap = const {},
    this.selectedCategory = 'All',
    this.searchQuery = '',
    this.totalSugarUsedKg = 0.0,
    this.totalSmpUsedKg = 0.0,
    this.totalCupsUsed = 0,
    this.totalFoilsUsed = 0,
    this.totalSpoonsUsed = 0,
  });

  /// Filtered items based on active category and search text
  List<InventoryItemModel> get filteredItems {
    final q = searchQuery.trim().toLowerCase();
    return allItems.where((item) {
      final matchesCategory = selectedCategory == 'All' || item.category == selectedCategory;
      final matchesQuery = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.details.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.packagingUnit.toLowerCase().contains(q);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  /// Dynamic item count per category for filter chips e.g. 'Cups (7)'
  Map<String, int> get categoryCounts {
    final Map<String, int> counts = {'All': allItems.length};
    for (final item in allItems) {
      counts[item.category] = (counts[item.category] ?? 0) + 1;
    }
    return counts;
  }

  InventoryStockState copyWith({
    List<InventoryItemModel>? allItems,
    List<StockDeductionEntry>? deductionLedger,
    List<InwardStockEntry>? inwardLedger,
    Map<String, double>? addedStockMap,
    Map<String, String>? lastUpdatedMap,
    Map<String, String>? lastUpdatedByMap,
    String? selectedCategory,
    String? searchQuery,
    double? totalSugarUsedKg,
    double? totalSmpUsedKg,
    int? totalCupsUsed,
    int? totalFoilsUsed,
    int? totalSpoonsUsed,
  }) {
    return InventoryStockState(
      allItems: allItems ?? this.allItems,
      deductionLedger: deductionLedger ?? this.deductionLedger,
      inwardLedger: inwardLedger ?? this.inwardLedger,
      addedStockMap: addedStockMap ?? this.addedStockMap,
      lastUpdatedMap: lastUpdatedMap ?? this.lastUpdatedMap,
      lastUpdatedByMap: lastUpdatedByMap ?? this.lastUpdatedByMap,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      searchQuery: searchQuery ?? this.searchQuery,
      totalSugarUsedKg: totalSugarUsedKg ?? this.totalSugarUsedKg,
      totalSmpUsedKg: totalSmpUsedKg ?? this.totalSmpUsedKg,
      totalCupsUsed: totalCupsUsed ?? this.totalCupsUsed,
      totalFoilsUsed: totalFoilsUsed ?? this.totalFoilsUsed,
      totalSpoonsUsed: totalSpoonsUsed ?? this.totalSpoonsUsed,
    );
  }
}

class InventoryStockNotifier extends StateNotifier<InventoryStockState> {
  final Ref? _ref;
  dynamic _lastProdRecords;
  dynamic _lastStdRecords;
  dynamic _lastBatchRecords;
  List<StockDeductionEntry> _manualIssues = [];

  InventoryStockNotifier([this._ref])
      : super(InventoryStockState(
          allItems: InventoryStockService.getBaselineItems(),
          deductionLedger: const [],
        )) {
    _setupListeners();
    _loadPersistedData();
  }

  void _setupListeners() {
    final ref = _ref;
    if (ref == null) return;

    _recalculateFromRef();

    ref.listen<ProductionState>(productionProvider, (previous, next) {
      if (previous?.allRecords != next.allRecords) {
        _recalculateFromRef();
      }
    });

    ref.listen<StandardizationState>(standardizationProvider, (previous, next) {
      if (previous?.history != next.history) {
        _recalculateFromRef();
      }
    });

    ref.listen<BatchRecordsState>(batchRecordsProvider, (previous, next) {
      if (previous?.batches != next.batches) {
        _recalculateFromRef();
      }
    });
  }

  Future<void> _loadPersistedData() async {
    await loadInwardStock();
    await loadManualIssues();
    _recalculateFromRef();
  }

  void _recalculateFromRef() {
    final ref = _ref;
    if (ref == null) return;
    final prod = ref.read(productionProvider).allRecords;
    final std = ref.read(standardizationProvider).history;
    final batch = ref.read(batchRecordsProvider).batches;
    updateWithRecords(
      productionRecords: prod,
      standardizationRecords: std,
      batchRecords: batch,
    );
  }

  /// Loads persisted manual stock issue overrides from local storage
  Future<void> loadManualIssues() async {
    _manualIssues = await LocalStorageService.getManualStockIssues();
    if (!mounted) return;
    _recalculate();
  }

  /// Loads persisted inward stock receipts from local storage
  Future<void> loadInwardStock() async {
    final records = await LocalStorageService.getInwardStockRecords();
    if (!mounted) return;
    if (records.isNotEmpty) {
      final Map<String, double> addedMap = {};
      final Map<String, String> updatedMap = {};
      final Map<String, String> updatedByMap = {};
      // Sort oldest to newest so newest timestamp overrides
      for (final r in records.reversed) {
        addedMap[r.itemId] = (addedMap[r.itemId] ?? 0.0) + r.quantity;
        updatedMap[r.itemId] = '${r.date} • ${r.time}';
        if (r.loggedBy.isNotEmpty) {
          updatedByMap[r.itemId] = r.loggedBy;
        }
      }
      state = state.copyWith(
        inwardLedger: records,
        addedStockMap: addedMap,
        lastUpdatedMap: updatedMap,
        lastUpdatedByMap: updatedByMap,
      );
      _recalculate();
    }
  }

  /// Updates or records inward inventory stock for a specific date and item
  Future<void> setOrUpdateInwardStock({
    required String itemId,
    required double quantity,
    required double packages,
    required String date,
    required String time,
    String loggedBy = 'Biraj Goswami',
    String notes = '',
  }) async {
    final item = state.allItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => InventoryStockService.getBaselineItems().firstWhere(
        (i) => i.id == itemId,
        orElse: () => InventoryStockService.getBaselineItems().first,
      ),
    );
    final targetDate = StockLedgerCalculator.parseAnyDate(date) ?? DateTime.now();

    // Filter out previous inward entries on the target date for this item
    final remainingInward = state.inwardLedger.where((e) {
      if (e.itemId != itemId) return true;
      return !StockLedgerCalculator.isSameDay(targetDate, e.date);
    }).toList();

    List<InwardStockEntry> updatedInward;
    if (quantity > 0) {
      final entry = InwardStockEntry(
        id: 'INWARD-${DateTime.now().millisecondsSinceEpoch}',
        itemId: itemId,
        itemName: item.name,
        quantity: quantity,
        packages: packages,
        unit: item.baseUnit,
        packagingUnit: item.packagingUnit,
        date: date,
        time: time,
        loggedBy: loggedBy,
        notes: notes,
      );
      updatedInward = [entry, ...remainingInward];
    } else {
      updatedInward = remainingInward;
    }

    final Map<String, double> addedMap = {};
    final Map<String, String> updatedMap = {};
    final Map<String, String> updatedByMap = {};
    for (final r in updatedInward.reversed) {
      addedMap[r.itemId] = (addedMap[r.itemId] ?? 0.0) + r.quantity;
      updatedMap[r.itemId] = '${r.date} • ${r.time}';
      if (r.loggedBy.isNotEmpty) {
        updatedByMap[r.itemId] = r.loggedBy;
      }
    }

    state = state.copyWith(
      inwardLedger: updatedInward,
      addedStockMap: addedMap,
      lastUpdatedMap: updatedMap,
      lastUpdatedByMap: updatedByMap,
    );

    await LocalStorageService.saveAllInwardStockRecords(updatedInward);
    _recalculate();
  }

  /// Updates or records manual stock issue for a specific date and item
  Future<void> setOrUpdateIssuedStock({
    required String itemId,
    required double quantity,
    required String date,
    required String time,
    String loggedBy = 'Biraj Goswami',
    String notes = '',
  }) async {
    final item = state.allItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => InventoryStockService.getBaselineItems().firstWhere(
        (i) => i.id == itemId,
        orElse: () => InventoryStockService.getBaselineItems().first,
      ),
    );
    final targetDate = StockLedgerCalculator.parseAnyDate(date) ?? DateTime.now();

    // Remove any previous manual issue on this date for this item
    final remainingIssues = _manualIssues.where((e) {
      if (e.inventoryItemId != itemId) return true;
      return !StockLedgerCalculator.isSameDay(targetDate, e.date);
    }).toList();

    if (quantity > 0) {
      final entry = StockDeductionEntry(
        id: 'ISSUE-${DateTime.now().millisecondsSinceEpoch}',
        date: date,
        time: time,
        source: 'Store Issue Register',
        referenceId: loggedBy,
        batchNo: 'STORE-ISSUE',
        productName: notes.isNotEmpty ? notes : 'Store Material Issue',
        inventoryItemId: itemId,
        inventoryItemName: item.name,
        quantityDeducted: quantity,
        unit: item.baseUnit,
        isCrossVerified: true,
        notes: notes,
      );
      _manualIssues = [entry, ...remainingIssues];
    } else {
      _manualIssues = remainingIssues;
    }

    await LocalStorageService.saveAllManualStockIssues(_manualIssues);
    _recalculate();
  }

  /// Adds inward inventory stock in real time and persists to local storage.
  /// Subsequent receipts on the same date accumulate (sum together) in the ledger.
  Future<void> addInwardStock({
    required String itemId,
    required double quantity,
    required double packages,
    required String date,
    required String time,
    String loggedBy = 'Biraj Goswami',
    String notes = '',
  }) async {
    if (quantity <= 0 && packages <= 0) return;

    final item = state.allItems.firstWhere(
      (i) => i.id == itemId,
      orElse: () => InventoryStockService.getBaselineItems().firstWhere(
        (i) => i.id == itemId,
        orElse: () => InventoryStockService.getBaselineItems().first,
      ),
    );

    final effectiveQty = quantity > 0
        ? quantity
        : (item.itemsPerPackage > 0 ? packages * item.itemsPerPackage : packages);
    final effectivePackages = packages > 0
        ? packages
        : (item.itemsPerPackage > 0 ? effectiveQty / item.itemsPerPackage : 0.0);

    final entry = InwardStockEntry(
      id: 'INWARD-${DateTime.now().millisecondsSinceEpoch}-${state.inwardLedger.length + 1}',
      itemId: itemId,
      itemName: item.name,
      quantity: effectiveQty,
      packages: effectivePackages,
      unit: item.baseUnit,
      packagingUnit: item.packagingUnit,
      date: date,
      time: time,
      loggedBy: loggedBy,
      notes: notes,
    );

    // Append to existing inward ledger without overwriting any prior entries on this date
    final updatedInward = [entry, ...state.inwardLedger];

    final Map<String, double> addedMap = {};
    final Map<String, String> updatedMap = {};
    final Map<String, String> updatedByMap = {};
    for (final r in updatedInward.reversed) {
      addedMap[r.itemId] = (addedMap[r.itemId] ?? 0.0) + r.quantity;
      updatedMap[r.itemId] = '${r.date} • ${r.time}';
      if (r.loggedBy.isNotEmpty) {
        updatedByMap[r.itemId] = r.loggedBy;
      }
    }

    state = state.copyWith(
      inwardLedger: updatedInward,
      addedStockMap: addedMap,
      lastUpdatedMap: updatedMap,
      lastUpdatedByMap: updatedByMap,
    );

    await LocalStorageService.saveAllInwardStockRecords(updatedInward);
    _recalculate();
  }

  void _recalculate() {
    if (_ref != null) {
      _recalculateFromRef();
    } else if (_lastProdRecords != null && _lastStdRecords != null && _lastBatchRecords != null) {
      updateWithRecords(
        productionRecords: _lastProdRecords,
        standardizationRecords: _lastStdRecords,
        batchRecords: _lastBatchRecords,
      );
    }
  }

  void setSelectedCategory(String category) {
    state = state.copyWith(selectedCategory: category);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '');
  }

  /// Recalculates inventory when production, standardization, or batch records change
  void updateWithRecords({
    required dynamic productionRecords,
    required dynamic standardizationRecords,
    required dynamic batchRecords,
  }) {
    _lastProdRecords = productionRecords;
    _lastStdRecords = standardizationRecords;
    _lastBatchRecords = batchRecords;

    final calc = InventoryStockService.calculateInventoryStock(
      productionRecords: productionRecords,
      standardizationRecords: standardizationRecords,
      batchRecords: batchRecords,
      addedStockMap: state.addedStockMap,
      lastUpdatedMap: state.lastUpdatedMap,
      lastUpdatedByMap: state.lastUpdatedByMap,
    );

    final combinedDeductions = [
      ...calc.deductionLedger,
      ..._manualIssues,
    ];

    state = state.copyWith(
      allItems: calc.items,
      deductionLedger: combinedDeductions,
      totalSugarUsedKg: calc.totalSugarUsedKg,
      totalSmpUsedKg: calc.totalSmpUsedKg,
      totalCupsUsed: calc.totalCupsUsed,
      totalFoilsUsed: calc.totalFoilsUsed,
      totalSpoonsUsed: calc.totalSpoonsUsed,
    );
  }
}

/// Provider that reactively combines Production, Standardization, and Batch Making
final inventoryStockProvider = StateNotifierProvider<InventoryStockNotifier, InventoryStockState>((ref) {
  return InventoryStockNotifier(ref);
});
