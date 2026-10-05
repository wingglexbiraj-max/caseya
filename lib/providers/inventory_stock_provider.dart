import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_item_model.dart';
import '../services/inventory_stock_service.dart';
import 'production_provider.dart';
import 'standardization_provider.dart';
import 'batch_records_provider.dart';

class InventoryStockState {
  final List<InventoryItemModel> allItems;
  final List<StockDeductionEntry> deductionLedger;
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
  InventoryStockNotifier()
      : super(const InventoryStockState(
          allItems: [],
          deductionLedger: [],
        ));

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
    final calc = InventoryStockService.calculateInventoryStock(
      productionRecords: productionRecords,
      standardizationRecords: standardizationRecords,
      batchRecords: batchRecords,
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
