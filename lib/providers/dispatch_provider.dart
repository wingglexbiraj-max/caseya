import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dispatch_record.dart';
import '../models/product_model.dart';
import '../repositories/dispatch_repository.dart';

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository();
});

class DispatchState {
  final String selectedDate;
  final String? distributorFilter;
  final String searchQuery;
  final List<VehicleDispatch> dispatches;
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;

  const DispatchState({
    required this.selectedDate,
    this.distributorFilter,
    this.searchQuery = '',
    this.dispatches = const [],
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  DispatchState copyWith({
    String? selectedDate,
    String? Function()? distributorFilter,
    String? searchQuery,
    List<VehicleDispatch>? dispatches,
    List<ProductModel>? products,
    bool? isLoading,
    String? Function()? error,
  }) {
    return DispatchState(
      selectedDate: selectedDate ?? this.selectedDate,
      distributorFilter: distributorFilter != null ? distributorFilter() : this.distributorFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      dispatches: dispatches ?? this.dispatches,
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
    );
  }

  /// All dispatches for the selected date
  List<VehicleDispatch> get dispatchesForSelectedDate {
    return dispatches.where((d) => d.dispatchDate == selectedDate).toList();
  }

  /// Dispatches for selected date after applying distributor filter & search query
  List<VehicleDispatch> get filteredDispatches {
    return dispatchesForSelectedDate.where((d) {
      if (distributorFilter != null && distributorFilter!.isNotEmpty) {
        if (d.distributorName.toLowerCase() != distributorFilter!.toLowerCase()) {
          return false;
        }
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchVehicle = d.vehicleNumber.toLowerCase().contains(q);
        final matchDistributor = d.distributorName.toLowerCase().contains(q);
        final matchDriver = d.driverName.toLowerCase().contains(q);
        final matchRoute = d.route.toLowerCase().contains(q);
        final matchRemarks = d.remarks.toLowerCase().contains(q);
        final matchProducts = d.items.any((i) =>
            i.productName.toLowerCase().contains(q) ||
            i.shortCode.toLowerCase().contains(q) ||
            i.itemCode.toLowerCase().contains(q));
        if (!matchVehicle &&
            !matchDistributor &&
            !matchDriver &&
            !matchRoute &&
            !matchRemarks &&
            !matchProducts) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  /// List of unique distributor names
  List<String> get availableDistributors {
    final set = <String>{};
    for (final d in dispatches) {
      if (d.distributorName.trim().isNotEmpty) {
        set.add(d.distributorName.trim());
      }
    }
    // Add standard plant distributor templates if not present
    set.addAll(['Distributor A', 'Distributor B', 'City North Hub', 'Dispur Depot', 'Silchar Supply']);
    return set.toList()..sort();
  }

  /// Total unique vehicles dispatched on selected date
  int get totalVehiclesForSelectedDate {
    return dispatchesForSelectedDate.map((d) => d.vehicleNumber.toUpperCase()).toSet().length;
  }

  /// Total unique distributors served on selected date
  int get totalDistributorsForSelectedDate {
    return dispatchesForSelectedDate.map((d) => d.distributorName.toLowerCase()).toSet().length;
  }

  /// Total product item lines recorded on selected date
  int get totalProductLinesForSelectedDate {
    return dispatchesForSelectedDate.fold(0, (acc, d) => acc + d.items.length);
  }

  /// Total Crates dispatched on selected date
  double get totalCratesForSelectedDate {
    return dispatchesForSelectedDate.fold(0.0, (acc, d) => acc + d.totalCrates);
  }

  /// Total Pieces dispatched on selected date
  int get totalPiecesForSelectedDate {
    return dispatchesForSelectedDate.fold(0, (acc, d) => acc + d.totalPieces);
  }

  /// Total Liquid volume dispatched in Litres (e.g. Milk, Lassi)
  double get totalLitresForSelectedDate {
    return dispatchesForSelectedDate.fold(0.0, (acc, d) => acc + d.totalLitres);
  }

  /// Total Solid/Curd weight dispatched in Kilograms (e.g. Curd cups/pouches)
  double get totalKgForSelectedDate {
    return dispatchesForSelectedDate.fold(0.0, (acc, d) => acc + d.totalKg);
  }

  /// Consolidated product-wise daily summary for the selected date
  /// Computed dynamically from dispatch items to strictly prevent double counting
  List<DailyDispatchProductSummary> get dailyProductSummaries {
    final Map<String, List<DispatchItem>> groupedByProduct = {};
    final Map<String, Set<String>> productVehicles = {};
    final Map<String, Set<String>> productDistributors = {};

    for (final dispatch in dispatchesForSelectedDate) {
      for (final item in dispatch.items) {
        groupedByProduct.putIfAbsent(item.productId, () => []).add(item);
        productVehicles.putIfAbsent(item.productId, () => {}).add(dispatch.vehicleNumber);
        productDistributors.putIfAbsent(item.productId, () => {}).add(dispatch.distributorName);
      }
    }

    final List<DailyDispatchProductSummary> summaries = [];

    for (final entry in groupedByProduct.entries) {
      final items = entry.value;
      if (items.isEmpty) continue;
      final first = items.first;

      final double cratesSum = items.fold(0.0, (acc, i) => acc + i.crates);
      final int piecesSum = items.fold(0, (acc, i) => acc + i.pieces);
      final double quantitySum = items.fold(0.0, (acc, i) => acc + i.normalizedQuantity);

      summaries.add(DailyDispatchProductSummary(
        productId: first.productId,
        productName: first.productName,
        shortCode: first.shortCode,
        itemCode: first.itemCode,
        packSizeDisplay: first.packSizeDisplay,
        totalCrates: cratesSum,
        totalPieces: piecesSum,
        totalQuantity: quantitySum,
        normalizedUnit: first.normalizedUnit,
        vehicleCount: productVehicles[entry.key]?.length ?? 1,
        distributorCount: productDistributors[entry.key]?.length ?? 1,
      ));
    }

    // Sort by total quantity descending
    summaries.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    return summaries;
  }

  /// Consolidated distributor-wise summaries for selected date
  List<DistributorDailySummary> get distributorSummaries {
    final Map<String, List<VehicleDispatch>> grouped = {};
    for (final d in dispatchesForSelectedDate) {
      grouped.putIfAbsent(d.distributorName, () => []).add(d);
    }

    final List<DistributorDailySummary> list = [];
    for (final entry in grouped.entries) {
      final distName = entry.key;
      final distDispatches = entry.value;
      final uniqueVehicles = distDispatches.map((d) => d.vehicleNumber).toSet().toList();

      final Map<String, DispatchItem> productMap = {};
      for (final d in distDispatches) {
        for (final item in d.items) {
          if (productMap.containsKey(item.productId)) {
            final existing = productMap[item.productId]!;
            productMap[item.productId] = existing.copyWith(
              crates: existing.crates + item.crates,
              pieces: existing.pieces + item.pieces,
              normalizedQuantity: existing.normalizedQuantity + item.normalizedQuantity,
            );
          } else {
            productMap[item.productId] = item;
          }
        }
      }

      final totalCrates = distDispatches.fold(0.0, (acc, d) => acc + d.totalCrates);
      final totalLitres = distDispatches.fold(0.0, (acc, d) => acc + d.totalLitres);
      final totalKg = distDispatches.fold(0.0, (acc, d) => acc + d.totalKg);

      list.add(DistributorDailySummary(
        distributorName: distName,
        vehicles: uniqueVehicles,
        dispatches: distDispatches,
        productItems: productMap.values.toList(),
        totalCrates: totalCrates,
        totalLitres: totalLitres,
        totalKg: totalKg,
      ));
    }

    list.sort((a, b) => b.totalCrates.compareTo(a.totalCrates));
    return list;
  }

  /// Date-wise dispatch history aggregates
  List<DateHistorySummary> get dateWiseHistory {
    final Map<String, List<VehicleDispatch>> grouped = {};
    for (final d in dispatches) {
      grouped.putIfAbsent(d.dispatchDate, () => []).add(d);
    }

    final List<DateHistorySummary> list = [];
    for (final entry in grouped.entries) {
      final date = entry.key;
      final dateDispatches = entry.value;
      final vehicles = dateDispatches.map((d) => d.vehicleNumber.toUpperCase()).toSet().length;
      final distributors = dateDispatches.map((d) => d.distributorName.toLowerCase()).toSet().length;
      final productLines = dateDispatches.fold(0, (acc, d) => acc + d.items.length);
      final crates = dateDispatches.fold(0.0, (acc, d) => acc + d.totalCrates);
      final litres = dateDispatches.fold(0.0, (acc, d) => acc + d.totalLitres);
      final kg = dateDispatches.fold(0.0, (acc, d) => acc + d.totalKg);

      list.add(DateHistorySummary(
        date: date,
        vehiclesCount: vehicles,
        distributorsCount: distributors,
        productLinesCount: productLines,
        totalCrates: crates,
        totalLitres: litres,
        totalKg: kg,
      ));
    }

    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }
}

class DistributorDailySummary {
  final String distributorName;
  final List<String> vehicles;
  final List<VehicleDispatch> dispatches;
  final List<DispatchItem> productItems;
  final double totalCrates;
  final double totalLitres;
  final double totalKg;

  const DistributorDailySummary({
    required this.distributorName,
    required this.vehicles,
    required this.dispatches,
    required this.productItems,
    required this.totalCrates,
    required this.totalLitres,
    required this.totalKg,
  });
}

class DateHistorySummary {
  final String date;
  final int vehiclesCount;
  final int distributorsCount;
  final int productLinesCount;
  final double totalCrates;
  final double totalLitres;
  final double totalKg;

  const DateHistorySummary({
    required this.date,
    required this.vehiclesCount,
    required this.distributorsCount,
    required this.productLinesCount,
    required this.totalCrates,
    required this.totalLitres,
    required this.totalKg,
  });
}

class DispatchNotifier extends StateNotifier<DispatchState> {
  final DispatchRepository _repository;

  DispatchNotifier(this._repository)
      : super(DispatchState(
          selectedDate: _getTodayDateStr(),
          isLoading: true,
        )) {
    loadData();
  }

  static String _getTodayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true, error: () => null);
    try {
      final dispatches = await _repository.getDispatches();
      final products = await _repository.getProducts();
      state = state.copyWith(
        dispatches: dispatches,
        products: products,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: () => 'Failed to load dispatch records: $e',
      );
    }
  }

  void setSelectedDate(String date) {
    state = state.copyWith(selectedDate: date);
  }

  void setDistributorFilter(String? distributor) {
    state = state.copyWith(distributorFilter: () => distributor);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<bool> saveDispatch(VehicleDispatch dispatch) async {
    try {
      await _repository.saveDispatch(dispatch);
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(error: () => 'Failed to save vehicle dispatch: $e');
      return false;
    }
  }

  Future<bool> updateDispatch(VehicleDispatch dispatch) async {
    try {
      await _repository.updateDispatch(dispatch);
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(error: () => 'Failed to update vehicle dispatch: $e');
      return false;
    }
  }

  Future<bool> deleteDispatch(String dispatchId) async {
    try {
      await _repository.deleteDispatch(dispatchId);
      await loadData();
      return true;
    } catch (e) {
      state = state.copyWith(error: () => 'Failed to delete vehicle dispatch: $e');
      return false;
    }
  }
}

final dispatchProvider = StateNotifierProvider<DispatchNotifier, DispatchState>((ref) {
  final repo = ref.watch(dispatchRepositoryProvider);
  return DispatchNotifier(repo);
});
