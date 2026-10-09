import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dispatch_record.dart';
import '../models/product_model.dart';
import '../repositories/dispatch_repository.dart';
import '../core/constants/dairy_products.dart';

final dispatchRepositoryProvider = Provider<DispatchRepository>((ref) {
  return DispatchRepository();
});

class DispatchState {
  final String selectedDate;
  final String rangeStartDate;
  final String rangeEndDate;
  final String datePreset;
  final String? distributorFilter;
  final String? productFilter;
  final String searchQuery;
  final List<VehicleDispatch> dispatches;
  final List<ProductModel> products;
  final bool isLoading;
  final String? error;

  const DispatchState({
    required this.selectedDate,
    required this.rangeStartDate,
    required this.rangeEndDate,
    this.datePreset = 'Today',
    this.distributorFilter,
    this.productFilter,
    this.searchQuery = '',
    this.dispatches = const [],
    this.products = const [],
    this.isLoading = false,
    this.error,
  });

  DispatchState copyWith({
    String? selectedDate,
    String? rangeStartDate,
    String? rangeEndDate,
    String? datePreset,
    String? Function()? distributorFilter,
    String? Function()? productFilter,
    String? searchQuery,
    List<VehicleDispatch>? dispatches,
    List<ProductModel>? products,
    bool? isLoading,
    String? Function()? error,
  }) {
    return DispatchState(
      selectedDate: selectedDate ?? this.selectedDate,
      rangeStartDate: rangeStartDate ?? this.rangeStartDate,
      rangeEndDate: rangeEndDate ?? this.rangeEndDate,
      datePreset: datePreset ?? this.datePreset,
      distributorFilter: distributorFilter != null ? distributorFilter() : this.distributorFilter,
      productFilter: productFilter != null ? productFilter() : this.productFilter,
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
      if (productFilter != null && productFilter!.isNotEmpty) {
        final hasProduct = d.items.any((i) => i.productId == productFilter || i.shortCode == productFilter);
        if (!hasProduct) return false;
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

  /// Dispatches matching the selected date range and filters
  List<VehicleDispatch> get dispatchesForDateRange {
    return dispatches.where((d) {
      if (d.dispatchDate.compareTo(rangeStartDate) < 0) return false;
      if (d.dispatchDate.compareTo(rangeEndDate) > 0) return false;
      if (distributorFilter != null && distributorFilter!.isNotEmpty) {
        if (d.distributorName.toLowerCase() != distributorFilter!.toLowerCase()) {
          return false;
        }
      }
      if (productFilter != null && productFilter!.isNotEmpty) {
        final hasProduct = d.items.any((i) => i.productId == productFilter || i.shortCode == productFilter);
        if (!hasProduct) return false;
      }
      if (searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        final matchVehicle = d.vehicleNumber.toLowerCase().contains(q);
        final matchDistributor = d.distributorName.toLowerCase().contains(q);
        final matchDriver = d.driverName.toLowerCase().contains(q);
        final matchProducts = d.items.any((i) =>
            i.productName.toLowerCase().contains(q) ||
            i.shortCode.toLowerCase().contains(q));
        if (!matchVehicle && !matchDistributor && !matchDriver && !matchProducts) {
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
    set.addAll(['Distributor A', 'Distributor B', 'City North Hub', 'Dispur Depot', 'Silchar Supply']);
    return set.toList()..sort();
  }

  /// Available products list
  List<ProductModel> get catalogProducts {
    return products.isNotEmpty ? products : DairyProducts.officialProducts;
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

  /// Total Commercial Revenue calculated for the selected date from product sales
  double get totalRevenueForSelectedDate {
    return _computeRevenueForList(dispatchesForSelectedDate);
  }

  /// Total Revenue for the date range
  double get totalRevenueForDateRange {
    return _computeRevenueForList(dispatchesForDateRange);
  }

  double _computeRevenueForList(List<VehicleDispatch> list) {
    double total = 0.0;
    final allProducts = catalogProducts;
    final productById = {for (final p in allProducts) p.productId: p};
    final productByCode = {for (final p in allProducts) p.itemCode.toLowerCase(): p};
    final productByShort = {for (final p in allProducts) p.shortCode.toLowerCase(): p};
    final productByName = {for (final p in allProducts) p.productName.toLowerCase(): p};

    for (final dispatch in list) {
      for (final item in dispatch.items) {
        final product = productById[item.productId] ??
            productByCode[item.itemCode.toLowerCase()] ??
            productByShort[item.shortCode.toLowerCase()] ??
            productByName[item.productName.toLowerCase()];

        final price = product?.pricePerPiece ?? 0.0;
        if (price > 0) {
          if (item.pieces > 0) {
            total += item.pieces * price;
          } else if (item.crates > 0 && (product?.piecesPerCrate ?? 0) > 0) {
            total += (item.crates * product!.piecesPerCrate) * price;
          } else if (item.inputQuantity > 0 && item.inputMode.toLowerCase() == 'pieces') {
            total += item.inputQuantity * price;
          }
        }
      }
    }
    return total;
  }

  /// Consolidated product-wise daily summary for the selected date
  List<DailyDispatchProductSummary> get dailyProductSummaries {
    return _aggregateProductsForList(dispatchesForSelectedDate);
  }

  /// Consolidated product-wise summary for the currently active date range
  List<DailyDispatchProductSummary> get productSummariesForDateRange {
    return _aggregateProductsForList(dispatchesForDateRange);
  }

  List<DailyDispatchProductSummary> _aggregateProductsForList(List<VehicleDispatch> list) {
    final Map<String, List<DispatchItem>> groupedByProduct = {};
    final Map<String, Set<String>> productVehicles = {};
    final Map<String, Set<String>> productDistributors = {};

    for (final dispatch in list) {
      for (final item in dispatch.items) {
        groupedByProduct.putIfAbsent(item.productId, () => []).add(item);
        productVehicles.putIfAbsent(item.productId, () => {}).add(dispatch.vehicleNumber);
        productDistributors.putIfAbsent(item.productId, () => {}).add(dispatch.distributorName);
      }
    }

    final allProducts = catalogProducts;
    final productById = {for (final p in allProducts) p.productId: p};
    final productByCode = {for (final p in allProducts) p.itemCode.toLowerCase(): p};
    final productByShort = {for (final p in allProducts) p.shortCode.toLowerCase(): p};
    final productByName = {for (final p in allProducts) p.productName.toLowerCase(): p};

    final List<DailyDispatchProductSummary> summaries = [];

    for (final entry in groupedByProduct.entries) {
      final items = entry.value;
      if (items.isEmpty) continue;
      final first = items.first;

      final double cratesSum = items.fold(0.0, (acc, i) => acc + i.crates);
      final int piecesSum = items.fold(0, (acc, i) => acc + i.pieces);
      final double quantitySum = items.fold(0.0, (acc, i) => acc + i.normalizedQuantity);

      final product = productById[first.productId] ??
          productByCode[first.itemCode.toLowerCase()] ??
          productByShort[first.shortCode.toLowerCase()] ??
          productByName[first.productName.toLowerCase()];
      final price = product?.pricePerPiece ?? 0.0;
      final double revenueSum = price > 0 ? piecesSum * price : 0.0;

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
        revenue: revenueSum,
      ));
    }

    summaries.sort((a, b) => b.totalQuantity.compareTo(a.totalQuantity));
    return summaries;
  }

  /// Consolidated distributor-wise summaries for selected date
  List<DistributorDailySummary> get distributorSummaries {
    return _aggregateDistributorsForList(dispatchesForSelectedDate);
  }

  /// Consolidated distributor-wise summaries for date range
  List<DistributorDailySummary> get distributorSummariesForDateRange {
    return _aggregateDistributorsForList(dispatchesForDateRange);
  }

  List<DistributorDailySummary> _aggregateDistributorsForList(List<VehicleDispatch> list) {
    final Map<String, List<VehicleDispatch>> grouped = {};
    for (final d in list) {
      grouped.putIfAbsent(d.distributorName, () => []).add(d);
    }

    final List<DistributorDailySummary> out = [];
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

      out.add(DistributorDailySummary(
        distributorName: distName,
        vehicles: uniqueVehicles,
        dispatches: distDispatches,
        productItems: productMap.values.toList(),
        totalCrates: totalCrates,
        totalLitres: totalLitres,
        totalKg: totalKg,
      ));
    }

    out.sort((a, b) => b.dispatches.length.compareTo(a.dispatches.length));
    return out;
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
          rangeStartDate: _getTodayDateStr(),
          rangeEndDate: _getTodayDateStr(),
          isLoading: true,
        )) {
    loadData();
  }

  static String _getTodayDateStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  static String _formatDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
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

  void setDateRange(String start, String end) {
    state = state.copyWith(
      rangeStartDate: start,
      rangeEndDate: end,
      datePreset: 'Custom',
    );
  }

  void setDatePreset(String preset) {
    final now = DateTime.now();
    String start = _formatDate(now);
    String end = _formatDate(now);

    switch (preset) {
      case 'Today':
        start = _formatDate(now);
        end = _formatDate(now);
        break;
      case 'Yesterday':
        final y = now.subtract(const Duration(days: 1));
        start = _formatDate(y);
        end = _formatDate(y);
        break;
      case 'Last 7 Days':
        final d7 = now.subtract(const Duration(days: 6));
        start = _formatDate(d7);
        end = _formatDate(now);
        break;
      case 'Last 30 Days':
        final d30 = now.subtract(const Duration(days: 29));
        start = _formatDate(d30);
        end = _formatDate(now);
        break;
      case 'All Time':
        start = '2020-01-01';
        end = '2035-12-31';
        break;
      default:
        break;
    }

    state = state.copyWith(
      rangeStartDate: start,
      rangeEndDate: end,
      datePreset: preset,
    );
  }

  void setDistributorFilter(String? distributor) {
    state = state.copyWith(distributorFilter: () => distributor);
  }

  void setProductFilter(String? product) {
    state = state.copyWith(productFilter: () => product);
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

  // --- CSV Generation Helpers ---

  String generateVehicleRecordsCsv(List<VehicleDispatch> dispatches) {
    final buffer = StringBuffer();
    buffer.writeln('Dispatch ID,Date,Dispatched At,Vehicle Number,Distributor,Driver,Route,Remarks,Status,Total Crates,Total Pieces,Total Litres,Total Kg,Products Summary');

    for (final d in dispatches) {
      final productsSummary = d.items.map((i) => '${i.shortCode}: ${i.formattedQuantity}').join('; ');
      buffer.writeln(
        '"${d.id}","${d.dispatchDate}","${d.dispatchedAt.toIso8601String()}","${d.vehicleNumber}","${d.distributorName}","${d.driverName}","${d.route}","${d.remarks.replaceAll('"', '""')}","${d.status}",${d.totalCrates},${d.totalPieces},${d.totalLitres},${d.totalKg},"${productsSummary.replaceAll('"', '""')}"',
      );
    }
    return buffer.toString();
  }

  String generateProductWiseCsv(List<DailyDispatchProductSummary> summaries, String dateRangeLabel) {
    final buffer = StringBuffer();
    buffer.writeln('Report Period: $dateRangeLabel');
    buffer.writeln('Product Code,Product Name,Pack Size,Total Crates,Total Pieces,Base Unit Equivalent,Unit,Vehicles Supplied,Distributors Served,Total Revenue (INR)');

    for (final s in summaries) {
      buffer.writeln(
        '"${s.itemCode}","${s.productName}","${s.packSizeDisplay}",${s.totalCrates},${s.totalPieces},${s.totalQuantity},"${s.normalizedUnit}",${s.vehicleCount},${s.distributorCount},${s.revenue}',
      );
    }
    return buffer.toString();
  }

  String generateDistributorWiseCsv(List<DistributorDailySummary> summaries, String dateRangeLabel) {
    final buffer = StringBuffer();
    buffer.writeln('Report Period: $dateRangeLabel');
    buffer.writeln('Distributor,Total Trips/Dispatches,Vehicles Dispatched,Total Crates,Total Litres,Total Kg,Products Breakdown');

    for (final s in summaries) {
      final vehicleList = s.vehicles.join(', ');
      final productsBreakdown = s.productItems.map((p) => '${p.shortCode}: ${p.formattedQuantity}').join('; ');
      buffer.writeln(
        '"${s.distributorName}",${s.dispatches.length},"${vehicleList.replaceAll('"', '""')}",${s.totalCrates},${s.totalLitres},${s.totalKg},"${productsBreakdown.replaceAll('"', '""')}"',
      );
    }
    return buffer.toString();
  }
}

final dispatchProvider = StateNotifierProvider<DispatchNotifier, DispatchState>((ref) {
  final repo = ref.watch(dispatchRepositoryProvider);
  return DispatchNotifier(repo);
});
