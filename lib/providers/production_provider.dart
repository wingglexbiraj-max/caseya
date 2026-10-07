import 'package:flutter/material.dart' show TimeOfDay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/app_constants.dart';
import '../core/constants/dairy_products.dart';
import '../core/utils/formatters.dart';
import '../models/operations_models.dart';
import '../models/product_model.dart';
import '../models/standardization_record.dart';
import '../repositories/production_repository.dart';
import '../services/inventory_stock_service.dart';

final productionRepositoryProvider = Provider((ref) => ProductionRepository());

final productionProvider = StateNotifierProvider<ProductionNotifier, ProductionState>((ref) {
  final repo = ref.watch(productionRepositoryProvider);
  return ProductionNotifier(repo);
});

class ProductionState {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final String selectedAuthorizedPerson;
  final String customAuthorizedPerson;
  final DateTime selectedDate;
  final TimeOfDay? selectedTime;
  final bool isLiveTime;
  final String selectedShift;
  final String batchNo;
  final double quantity;
  final double crates;
  final int pieces;
  final String remarks;

  final List<ProductionRecord> allRecords;
  final List<ProductionRecord> filteredHistory;
  final List<StandardizationRecord> standardizationBatches;
  final StandardizationRecord? selectedStandardizationBatch;

  // History filters
  final DateTime? filterDate;
  final String? filterProductId;
  final String searchQuery;

  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  static const List<String> authorizedPersonsList = [
    'Biraj Goswami',
    'Bhriguraj Borah',
    'Pranjit Das',
    'Parag Jyoti Patowary',
    'Ritul Kaushik',
    'Joydeep Chanda',
    'Navjyoti Barman',
    'Dipankar Barman',
    'Prasenjit Das',
    'Rupam Boruah',
    'Other (Type manually)',
  ];

  const ProductionState({
    this.products = const [],
    this.selectedProduct,
    this.selectedAuthorizedPerson = 'Biraj Goswami',
    this.customAuthorizedPerson = '',
    required this.selectedDate,
    this.selectedTime,
    this.isLiveTime = true,
    this.selectedShift = 'Shift A (06:00 - 14:00)',
    this.batchNo = '',
    this.quantity = 0.0,
    this.crates = 0.0,
    this.pieces = 0,
    this.remarks = '',
    this.allRecords = const [],
    this.filteredHistory = const [],
    this.standardizationBatches = const [],
    this.selectedStandardizationBatch,
    this.filterDate,
    this.filterProductId,
    this.searchQuery = '',
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  bool isStandardizationBatchPrepared(StandardizationRecord std) {
    return allRecords.any((r) =>
        (r.standardizationRecordId != null && r.standardizationRecordId == std.recordId) ||
        (r.date == std.date &&
            (r.productName.toLowerCase().contains(std.targetProductName.toLowerCase()) ||
                std.targetProductName.toLowerCase().contains(r.productName.toLowerCase())) &&
            (r.quantityProduced - std.finalQuantity).abs() < 5));
  }

  ProductionRecord? findProductionRecordForStandardizationBatch(StandardizationRecord std) {
    try {
      return allRecords.firstWhere((r) =>
          (r.standardizationRecordId != null && r.standardizationRecordId == std.recordId) ||
          (r.date == std.date &&
              (r.productName.toLowerCase().contains(std.targetProductName.toLowerCase()) ||
                  std.targetProductName.toLowerCase().contains(r.productName.toLowerCase())) &&
              (r.quantityProduced - std.finalQuantity).abs() < 5));
    } catch (_) {
      return null;
    }
  }

  ProductModel? findBestProductMatch(dynamic target, [String targetId = '']) {
    String targetName = '';
    if (target is StandardizationRecord) {
      targetName = target.targetProductName;
      targetId = target.targetProductId;
    } else if (target is String) {
      targetName = target;
    }
    final nameLow = targetName.toLowerCase();
    final idLow = targetId.toLowerCase();

    final catalog = products.isNotEmpty ? products : DairyProducts.officialProducts;
    if (catalog.isEmpty) return null;

    for (final p in catalog) {
      if (p.productId.toLowerCase() == idLow || p.shortCode.toLowerCase() == idLow) {
        return p;
      }
    }

    if (idLow.contains('std') || nameLow.contains('std')) {
      return catalog.firstWhere(
        (p) => p.productName.toLowerCase().contains('std 500') || p.productName.toLowerCase().contains('std'),
        orElse: () => catalog.first,
      );
    }
    if (idLow.contains('army') || nameLow.contains('army') || nameLow.contains('sm+')) {
      return catalog.firstWhere(
        (p) => p.productName.toLowerCase().contains('army') || p.productName.toLowerCase().contains('sm+'),
        orElse: () => catalog.first,
      );
    }
    if (idLow.contains('lassi') || nameLow.contains('lassi')) {
      return catalog.firstWhere(
        (p) => p.productName.toLowerCase().contains('lassi'),
        orElse: () => catalog.first,
      );
    }
    if (idLow.contains('sweet_curd') || nameLow.contains('sweet curd')) {
      return catalog.firstWhere(
        (p) => p.productName.toLowerCase().contains('sweet curd cup (s400)') || p.productName.toLowerCase().contains('sweet curd'),
        orElse: () => catalog.first,
      );
    }
    if (idLow.contains('plain_curd_pouch') || (nameLow.contains('plain curd') && nameLow.contains('pouch'))) {
      return catalog.firstWhere(
        (p) => p.productName.toLowerCase().contains('plain curd pouch 400') || (p.productName.toLowerCase().contains('curd') && p.productName.toLowerCase().contains('pouch')),
        orElse: () => catalog.first,
      );
    }
    if (idLow.contains('plain_curd_cup') || (nameLow.contains('plain curd') && nameLow.contains('cup'))) {
      return catalog.firstWhere(
        (p) => p.productName.toLowerCase().contains('plain curd cup (p400)') || p.productName.toLowerCase().contains('plain curd'),
        orElse: () => catalog.first,
      );
    }

    for (final p in catalog) {
      if (p.productName.toLowerCase().contains(nameLow) || nameLow.contains(p.productName.toLowerCase())) {
        return p;
      }
    }

    return catalog.isNotEmpty ? catalog.first : null;
  }

  ProductionState copyWith({
    List<ProductModel>? products,
    ProductModel? selectedProduct,
    bool clearSelectedProduct = false,
    String? selectedAuthorizedPerson,
    String? customAuthorizedPerson,
    DateTime? selectedDate,
    TimeOfDay? selectedTime,
    bool? isLiveTime,
    bool clearSelectedTime = false,
    String? selectedShift,
    String? batchNo,
    double? quantity,
    double? crates,
    int? pieces,
    String? remarks,
    List<ProductionRecord>? allRecords,
    List<ProductionRecord>? filteredHistory,
    List<StandardizationRecord>? standardizationBatches,
    StandardizationRecord? selectedStandardizationBatch,
    bool clearSelectedStandardizationBatch = false,
    DateTime? filterDate,
    bool clearFilterDate = false,
    String? filterProductId,
    bool clearFilterProductId = false,
    String? searchQuery,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProductionState(
      products: products ?? this.products,
      selectedProduct: clearSelectedProduct ? null : (selectedProduct ?? this.selectedProduct),
      selectedAuthorizedPerson: selectedAuthorizedPerson ?? this.selectedAuthorizedPerson,
      customAuthorizedPerson: customAuthorizedPerson ?? this.customAuthorizedPerson,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedTime: clearSelectedTime ? null : (selectedTime ?? this.selectedTime),
      isLiveTime: isLiveTime ?? this.isLiveTime,
      selectedShift: selectedShift ?? this.selectedShift,
      batchNo: batchNo ?? this.batchNo,
      quantity: quantity ?? this.quantity,
      crates: crates ?? this.crates,
      pieces: pieces ?? this.pieces,
      remarks: remarks ?? this.remarks,
      allRecords: allRecords ?? this.allRecords,
      filteredHistory: filteredHistory ?? this.filteredHistory,
      standardizationBatches: standardizationBatches ?? this.standardizationBatches,
      selectedStandardizationBatch: clearSelectedStandardizationBatch
          ? null
          : (selectedStandardizationBatch ?? this.selectedStandardizationBatch),
      filterDate: clearFilterDate ? null : (filterDate ?? this.filterDate),
      filterProductId: clearFilterProductId ? null : (filterProductId ?? this.filterProductId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProductionNotifier extends StateNotifier<ProductionState> {
  final ProductionRepository _repo;

  ProductionNotifier(this._repo)
      : super(ProductionState(
          selectedDate: DateTime.now(),
          selectedShift: AppConstants.determineShift(DateTime.now()),
          filterDate: DateTime.now(), // By default show today's history
        )) {
    init();
  }

  ProductionState get currentState => state;

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    var products = await _repo.getProducts();
    if (products.isEmpty) {
      products = List<ProductModel>.from(DairyProducts.officialProducts);
    }
    final records = await _repo.getProductionRecords();
    final stdBatches = await _repo.getStandardizationRecords();

    final now = DateTime.now();
    final defaultBatch = _generateBatchNo(now, null);

    state = state.copyWith(
      products: products,
      clearSelectedProduct: true,
      batchNo: defaultBatch,
      allRecords: records,
      standardizationBatches: stdBatches,
      isLoading: false,
    );
    _applyFilters();
  }

  Future<void> reloadStandardizationBatches() async {
    final stdBatches = await _repo.getStandardizationRecords();
    state = state.copyWith(standardizationBatches: stdBatches);
  }

  String _generateBatchNo(DateTime date, ProductModel? product) {
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final code = product?.shortCode.replaceAll(' ', '').toUpperCase() ?? 'PRD';
    final suffix = (state.allRecords.length + 1).toString().padLeft(2, '0');
    return 'BT-$y$m$d-$code-$suffix';
  }

  void selectProduct(ProductModel product) {
    final newBatch = _generateBatchNo(state.selectedDate, product);
    // If crates were entered, recalculate pieces and quantity for new product
    double qty = state.quantity;
    int pcs = state.pieces;
    if (state.crates > 0) {
      pcs = (state.crates * product.piecesPerCrate).round();
      qty = pcs * product.packSizeInBaseUnit;
    } else if (pcs > 0) {
      qty = pcs * product.packSizeInBaseUnit;
    }

    state = state.copyWith(
      selectedProduct: product,
      batchNo: newBatch,
      pieces: pcs,
      quantity: qty,
      clearMessages: true,
    );
  }

  void setAuthorizedPerson(String person) {
    state = state.copyWith(
      selectedAuthorizedPerson: person,
      clearMessages: true,
    );
  }

  void setCustomAuthorizedPerson(String name) {
    state = state.copyWith(
      customAuthorizedPerson: name,
      clearMessages: true,
    );
  }

  void setDate(DateTime date) {
    final newBatch = _generateBatchNo(date, state.selectedProduct);
    state = state.copyWith(
      selectedDate: date,
      batchNo: newBatch,
      clearMessages: true,
    );
  }

  void setTime(TimeOfDay time) {
    state = state.copyWith(
      selectedTime: time,
      isLiveTime: false,
      clearMessages: true,
    );
  }

  void resetToLiveTime() {
    state = state.copyWith(
      isLiveTime: true,
      clearSelectedTime: true,
      clearMessages: true,
    );
  }

  void setShift(String shift) {
    state = state.copyWith(
      selectedShift: shift,
      clearMessages: true,
    );
  }

  void setBatchNo(String batch) {
    state = state.copyWith(
      batchNo: batch,
      clearMessages: true,
    );
  }

  void setRemarks(String remarks) {
    state = state.copyWith(
      remarks: remarks,
      clearMessages: true,
    );
  }

  /// Called when user inputs Crates: updates pieces & quantity
  void updateFromCrates(double crates) {
    final p = state.selectedProduct;
    if (p == null) {
      state = state.copyWith(crates: crates);
      return;
    }
    final pcs = (crates * p.piecesPerCrate).round();
    final qty = pcs * p.packSizeInBaseUnit;
    state = state.copyWith(
      crates: crates,
      pieces: pcs,
      quantity: qty,
      clearMessages: true,
    );
  }

  /// Called when user inputs Pieces: updates crates & quantity
  void updateFromPieces(int pieces) {
    final p = state.selectedProduct;
    if (p == null) {
      state = state.copyWith(pieces: pieces);
      return;
    }
    final crates = p.piecesPerCrate > 0 ? (pieces / p.piecesPerCrate) : 0.0;
    final qty = pieces * p.packSizeInBaseUnit;
    state = state.copyWith(
      pieces: pieces,
      crates: crates,
      quantity: qty,
      clearMessages: true,
    );
  }

  /// Called when user inputs Quantity (Litres / Kg): updates pieces & crates
  void updateFromQuantity(double quantity) {
    final p = state.selectedProduct;
    if (p == null) {
      state = state.copyWith(quantity: quantity);
      return;
    }
    final pcs = p.packSizeInBaseUnit > 0 ? (quantity / p.packSizeInBaseUnit).round() : 0;
    final crates = p.piecesPerCrate > 0 ? (pcs / p.piecesPerCrate) : 0.0;
    state = state.copyWith(
      quantity: quantity,
      pieces: pcs,
      crates: crates,
      clearMessages: true,
    );
  }

  // Filter actions
  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
    _applyFilters();
  }

  void setFilterDate(DateTime? date) {
    state = state.copyWith(filterDate: date);
    _applyFilters();
  }

  void clearFilterDate() {
    state = state.copyWith(clearFilterDate: true);
    _applyFilters();
  }

  void setFilterProduct(String? productId) {
    state = state.copyWith(
      filterProductId: productId,
      clearFilterProductId: productId == null || productId.isEmpty,
    );
    _applyFilters();
  }

  void _applyFilters() {
    var list = List<ProductionRecord>.from(state.allRecords);

    // 1. Date Filter (by default today)
    if (state.filterDate != null) {
      final targetDateStr = Formatters.formatIsoDate(state.filterDate!);
      list = list.where((r) => r.date == targetDateStr).toList();
    }

    // 2. Product Filter
    if (state.filterProductId != null && state.filterProductId!.isNotEmpty) {
      list = list.where((r) =>
        r.productId == state.filterProductId ||
        r.productName.toLowerCase() == state.filterProductId!.toLowerCase()
      ).toList();
    }

    // 3. Search Query Filter
    if (state.searchQuery.trim().isNotEmpty) {
      final q = state.searchQuery.trim().toLowerCase();
      list = list.where((r) {
        return r.productName.toLowerCase().contains(q) ||
            r.batchNo.toLowerCase().contains(q) ||
            r.employeeName.toLowerCase().contains(q) ||
            r.shift.toLowerCase().contains(q) ||
            r.remarks.toLowerCase().contains(q);
      }).toList();
    }

    state = state.copyWith(filteredHistory: list);
  }

  void selectStandardizationBatch(StandardizationRecord batch) {
    final matchedProduct = state.findBestProductMatch(batch) ?? state.selectedProduct;
    final qty = batch.finalQuantity > 0 ? batch.finalQuantity : batch.totalBatchRequired;
    int pcs = 0;
    double crates = 0.0;
    if (matchedProduct != null && matchedProduct.packSizeInBaseUnit > 0) {
      pcs = (qty / matchedProduct.packSizeInBaseUnit).round();
      crates = matchedProduct.piecesPerCrate > 0 ? (pcs / matchedProduct.piecesPerCrate) : 0.0;
    }

    final newBatch = matchedProduct != null ? _generateBatchNo(state.selectedDate, matchedProduct) : state.batchNo;

    state = state.copyWith(
      selectedStandardizationBatch: batch,
      selectedProduct: matchedProduct,
      batchNo: newBatch,
      quantity: qty,
      pieces: pcs,
      crates: crates,
      clearMessages: true,
    );
  }

  void clearStandardizationBatch() {
    state = state.copyWith(
      clearSelectedStandardizationBatch: true,
      clearMessages: true,
    );
  }

  String get effectiveAuthorizedPerson {
    if (state.selectedAuthorizedPerson == 'Other (Type manually)' &&
        state.customAuthorizedPerson.trim().isNotEmpty) {
      return state.customAuthorizedPerson.trim();
    }
    return state.selectedAuthorizedPerson;
  }

  Future<bool> recordProductionEntry({required String employeeId}) async {
    if (state.selectedProduct == null) {
      state = state.copyWith(errorMessage: 'Please select a product first.');
      return false;
    }

    if (state.quantity <= 0 && state.crates <= 0 && state.pieces <= 0) {
      state = state.copyWith(errorMessage: 'Please enter a valid quantity, crates, or pieces count.');
      return false;
    }

    final p = state.selectedProduct!;
    final now = DateTime.now();
    final effectivePerson = effectiveAuthorizedPerson;
    final String timeStr;
    if (state.isLiveTime) {
      timeStr = DateFormat('hh:mm a').format(DateTime.now());
    } else if (state.selectedTime != null) {
      final hour = state.selectedTime!.hour;
      final minute = state.selectedTime!.minute;
      final dt = DateTime(now.year, now.month, now.day, hour, minute);
      timeStr = DateFormat('hh:mm a').format(dt);
    } else {
      timeStr = AppConstants.alignTimeForShift(now, state.selectedShift);
    }
    final effectiveShift = state.isLiveTime
        ? AppConstants.determineShift(DateTime.now())
        : (state.selectedTime != null
            ? AppConstants.determineShift(DateTime(now.year, now.month, now.day, state.selectedTime!.hour, state.selectedTime!.minute))
            : state.selectedShift);

    final record = ProductionRecord(
      recordId: 'PR-${now.millisecondsSinceEpoch}-${const Uuid().v4().substring(0, 4).toUpperCase()}',
      standardizationRecordId: state.selectedStandardizationBatch?.recordId,
      date: Formatters.formatIsoDate(state.selectedDate),
      time: timeStr,
      shift: effectiveShift,
      employeeId: employeeId,
      employeeName: effectivePerson,
      productId: p.productId,
      productName: p.productName,
      batchNo: state.batchNo.trim().isNotEmpty
          ? state.batchNo.trim()
          : _generateBatchNo(state.selectedDate, p),
      quantityProduced: state.quantity,
      unit: p.baseUnitLabel,
      cratesProduced: state.crates,
      piecesProduced: state.pieces,
      remarks: state.remarks.trim(),
    );

    await _repo.addProductionRecord(record);
    final updatedRecords = await _repo.getProductionRecords();

    final nextBatch = _generateBatchNo(state.selectedDate, state.selectedProduct);

    // Calculate consumed packaging materials for immediate feedback
    final consumedList = InventoryStockService.getConsumedPackagingForRecord(record);
    final String consumedSummary;
    if (consumedList.isNotEmpty) {
      final itemsText = consumedList
          .map((c) => '${Formatters.formatSmart(c.quantity)} ${c.unit} ${c.itemName}')
          .join(', ');
      consumedSummary = '\n📦 Consumed Packaging: $itemsText';
    } else {
      consumedSummary = '';
    }

    state = state.copyWith(
      allRecords: updatedRecords,
      filterDate: state.selectedDate,
      quantity: 0.0,
      crates: 0.0,
      pieces: 0,
      remarks: '',
      batchNo: nextBatch,
      clearSelectedProduct: true,
      clearSelectedStandardizationBatch: true,
      successMessage: '✓ Production logged for ${p.productName} (${Formatters.formatSmart(record.quantityProduced)} ${record.unit}).$consumedSummary',
      clearMessages: false,
    );

    _applyFilters();
    return true;
  }

  Future<void> deleteRecord(String recordId) async {
    await _repo.deleteProductionRecord(recordId);
    final updatedRecords = await _repo.getProductionRecords();
    state = state.copyWith(
      allRecords: updatedRecords,
      successMessage: 'Production record deleted successfully.',
    );
    _applyFilters();
  }

  void clearForm() {
    final nextBatch = _generateBatchNo(state.selectedDate, null);
    state = state.copyWith(
      quantity: 0.0,
      crates: 0.0,
      pieces: 0,
      remarks: '',
      batchNo: nextBatch,
      clearSelectedProduct: true,
      clearSelectedStandardizationBatch: true,
      clearMessages: true,
    );
  }
}
