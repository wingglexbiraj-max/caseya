import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item_model.dart';
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
  dynamic _lastProdRecords;
  dynamic _lastStdRecords;
  dynamic _lastBatchRecords;

  InventoryStockNotifier()
      : super(const InventoryStockState(
          allItems: [],
          deductionLedger: [],
        )) {
    loadInwardStock();
  }

  /// Loads persisted inward stock receipts from local storage
  Future<void> loadInwardStock() async {
    final records = await LocalStorageService.getInwardStockRecords();
    if (records.isNotEmpty) {
      final Map<String, double> addedMap = {};
      final Map<String, String> updatedMap = {};
      // Sort oldest to newest so newest timestamp overrides
      for (final r in records.reversed) {
        addedMap[r.itemId] = (addedMap[r.itemId] ?? 0.0) + r.quantity;
        updatedMap[r.itemId] = '${r.date} • ${r.time}';
      }
      state = state.copyWith(
        inwardLedger: records,
        addedStockMap: addedMap,
        lastUpdatedMap: updatedMap,
      );
      _recalculate();
    }
  }

  /// Adds inward inventory stock in real time and persists to local storage
  void addInwardStock({
    required String itemId,
    required double quantity,
    required double packages,
    required String date,
    required String time,
    String notes = '',
  }) {
    final item = state.allItems.firstWhere((i) => i.id == itemId, orElse: () => state.allItems.first);
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
      notes: notes,
    );

    final updatedInward = [entry, ...state.inwardLedger];
    final updatedAddedMap = Map<String, double>.from(state.addedStockMap);
    updatedAddedMap[itemId] = (updatedAddedMap[itemId] ?? 0.0) + quantity;

    final updatedLastUpdated = Map<String, String>.from(state.lastUpdatedMap);
    updatedLastUpdated[itemId] = '$date • $time';

    state = state.copyWith(
      inwardLedger: updatedInward,
      addedStockMap: updatedAddedMap,
      lastUpdatedMap: updatedLastUpdated,
    );

    LocalStorageService.saveInwardStockRecord(entry);
    _recalculate();
  }

  void _recalculate() {
    if (_lastProdRecords != null && _lastStdRecords != null && _lastBatchRecords != null) {
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
    );

    state = state.copyWith(
      allItems: calc.items,
      deductionLedger: calc.deductionLedger,
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
  final notifier = InventoryStockNotifier();

  // Watch upstream records
  final productionState = ref.watch(productionProvider);
  final stdState = ref.watch(standardizationProvider);
  final batchState = ref.watch(batchRecordsProvider);

  notifier.updateWithRecords(
    productionRecords: productionState.allRecords,
    standardizationRecords: stdState.history,
    batchRecords: batchState.batches,
  );

  return notifier;
});
