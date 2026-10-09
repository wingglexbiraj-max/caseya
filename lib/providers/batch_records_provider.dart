import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/batch_record_model.dart';
import '../repositories/batch_repository.dart';

final batchRepositoryProvider = Provider((ref) => BatchRepository());

class BatchRecordsState {
  final List<BatchRecordModel> batches;
  final bool isLoading;
  final DateTime? selectedDate;
  final DateTimeRange? dateRange;
  final String selectedProduct;
  final String searchQuery;
  final String? errorMessage;
  final String? successMessage;

  const BatchRecordsState({
    this.batches = const [],
    this.isLoading = false,
    this.selectedDate,
    this.dateRange,
    this.selectedProduct = 'All',
    this.searchQuery = '',
    this.errorMessage,
    this.successMessage,
  });

  BatchRecordsState copyWith({
    List<BatchRecordModel>? batches,
    bool? isLoading,
    DateTime? selectedDate,
    bool clearSelectedDate = false,
    DateTimeRange? dateRange,
    bool clearDateRange = false,
    String? selectedProduct,
    String? searchQuery,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return BatchRecordsState(
      batches: batches ?? this.batches,
      isLoading: isLoading ?? this.isLoading,
      selectedDate: clearSelectedDate ? null : (selectedDate ?? this.selectedDate),
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
      selectedProduct: selectedProduct ?? this.selectedProduct,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }

  /// Filtered list of batches based on active date, product, and search filters
  List<BatchRecordModel> get filteredBatches {
    return batches.where((batch) {
      // 1. Single Date filter
      if (selectedDate != null) {
        final dateStr =
            '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';
        if (batch.productionDate != dateStr) {
          return false;
        }
      }

      // 2. Date Range filter
      if (dateRange != null) {
        final bDate = DateTime.tryParse(batch.productionDate);
        if (bDate != null) {
          final start = DateTime(dateRange!.start.year, dateRange!.start.month, dateRange!.start.day);
          final end = DateTime(dateRange!.end.year, dateRange!.end.month, dateRange!.end.day, 23, 59, 59);
          if (bDate.isBefore(start) || bDate.isAfter(end)) {
            return false;
          }
        }
      }

      // 3. Product filter
      if (selectedProduct != 'All') {
        if (batch.productName.toLowerCase() != selectedProduct.toLowerCase()) {
          return false;
        }
      }

      // 4. Search query filter
      if (searchQuery.trim().isNotEmpty) {
        final q = searchQuery.toLowerCase().trim();
        final matchesBatchNum = batch.batchNumber.toLowerCase().contains(q);
        final matchesProduct = batch.productName.toLowerCase().contains(q);
        final matchesNotes = (batch.notes ?? '').toLowerCase().contains(q);
        final matchesIngredient = batch.ingredients.any(
          (ing) => ing.ingredientName.toLowerCase().contains(q),
        );
        if (!matchesBatchNum && !matchesProduct && !matchesNotes && !matchesIngredient) {
          return false;
        }
      }

      return true;
    }).toList();
  }

  /// Batches grouped by production date, sorted in descending order (latest date first)
  Map<String, List<BatchRecordModel>> get groupedByDate {
    final map = <String, List<BatchRecordModel>>{};
    for (final b in filteredBatches) {
      map.putIfAbsent(b.productionDate, () => []);
      map[b.productionDate]!.add(b);
    }

    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    final sortedMap = <String, List<BatchRecordModel>>{};
    for (final k in sortedKeys) {
      sortedMap[k] = map[k]!;
    }
    return sortedMap;
  }

  /// Daily summaries for all dates in current filtered view
  Map<String, DailyBatchSummary> get dailySummaries {
    final summaries = <String, DailyBatchSummary>{};
    for (final entry in groupedByDate.entries) {
      summaries[entry.key] = DailyBatchSummary.fromBatches(entry.key, entry.value);
    }
    return summaries;
  }
}

class BatchRecordsNotifier extends StateNotifier<BatchRecordsState> {
  final BatchRepository _repository;

  BatchRecordsNotifier(this._repository)
      : super(BatchRecordsState(selectedDate: DateTime.now())) {
    loadBatches();
  }

  Future<void> loadBatches() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      final list = await _repository.getBatches();
      // Sort newest to oldest
      list.sort((a, b) => b.productionDate.compareTo(a.productionDate));
      state = state.copyWith(batches: list, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load batch records: $e',
      );
    }
  }

  Future<void> refresh() async => loadBatches();

  Future<bool> createBatch(BatchRecordModel batch) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.addBatch(batch);
      final list = [batch, ...state.batches];
      list.sort((a, b) => b.productionDate.compareTo(a.productionDate));
      state = state.copyWith(
        batches: list,
        isLoading: false,
        successMessage: 'Batch ${batch.batchNumber} saved successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to save batch: $e',
      );
      return false;
    }
  }

  Future<bool> updateBatch(BatchRecordModel batch) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.updateBatch(batch);
      final list = List<BatchRecordModel>.from(state.batches);
      final index = list.indexWhere((b) => b.id == batch.id);
      if (index >= 0) {
        list[index] = batch;
      } else {
        list.add(batch);
      }
      list.sort((a, b) => b.productionDate.compareTo(a.productionDate));
      state = state.copyWith(
        batches: list,
        isLoading: false,
        successMessage: 'Batch ${batch.batchNumber} updated successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update batch: $e',
      );
      return false;
    }
  }

  Future<bool> deleteBatch(String id) async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    try {
      await _repository.deleteBatch(id);
      final list = state.batches.where((b) => b.id != id).toList();
      state = state.copyWith(
        batches: list,
        isLoading: false,
        successMessage: 'Batch removed successfully.',
      );
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to delete batch: $e',
      );
      return false;
    }
  }

  void setDateFilter(DateTime? date) {
    state = state.copyWith(
      selectedDate: date,
      clearSelectedDate: date == null,
      clearDateRange: true,
    );
  }

  void setDateRangeFilter(DateTimeRange? range) {
    state = state.copyWith(
      dateRange: range,
      clearDateRange: range == null,
      clearSelectedDate: true,
    );
  }

  void setProductFilter(String product) {
    state = state.copyWith(selectedProduct: product);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedDate: DateTime.now(),
      clearDateRange: true,
      selectedProduct: 'All',
      searchQuery: '',
      clearMessages: true,
    );
  }

  /// Automatically generates the next batch number for the specified date and product
  /// Format: BT-YYYYMMDD-01, BT-YYYYMMDD-02...
  String generateNextBatchNumber(String dateStr, String productName) {
    final cleanDate = dateStr.replaceAll('-', '');
    final prefix = 'BT-$cleanDate';
    final existingOnDate = state.batches.where(
      (b) => b.productionDate == dateStr || b.batchNumber.startsWith(prefix),
    ).length;
    final nextNum = (existingOnDate + 1).toString().padLeft(2, '0');
    return '$prefix-$nextNum';
  }
}

final batchRecordsProvider =
    StateNotifierProvider<BatchRecordsNotifier, BatchRecordsState>((ref) {
  final repo = ref.watch(batchRepositoryProvider);
  return BatchRecordsNotifier(repo);
});
