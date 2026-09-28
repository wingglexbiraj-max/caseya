import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/standardization_record.dart';
import '../models/lab_record.dart';
import '../services/milk_standardization_calculator.dart';
import '../repositories/product_repository.dart';
import '../repositories/standardization_repository.dart';
import '../repositories/lab_repository.dart';
import '../core/utils/formatters.dart';
import 'product_calculator_provider.dart';

final labRepositoryProvider = Provider((ref) => LabRepository());

class StandardizationState {
  final DateTime selectedDate;
  final double milkQuantity;
  final String inputUnit; // Litres
  final double milkFat;
  final double milkSnf;
  final List<ProductModel> targetProducts;
  final ProductModel? selectedTargetProduct;
  final double targetFat;
  final double targetSnf;
  final LabRecord? fetchedLabRecord;
  final bool hasFetchedLabData;
  final String? labDataFetchStatus;
  final StandardizationResult? result;
  final List<StandardizationRecord> history;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const StandardizationState({
    required this.selectedDate,
    this.milkQuantity = 5000.0,
    this.inputUnit = 'Litres',
    this.milkFat = 3.8,
    this.milkSnf = 8.4,
    this.targetProducts = const [],
    this.selectedTargetProduct,
    this.targetFat = 2.5,
    this.targetSnf = 9.0,
    this.fetchedLabRecord,
    this.hasFetchedLabData = false,
    this.labDataFetchStatus,
    this.result,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  StandardizationState copyWith({
    DateTime? selectedDate,
    double? milkQuantity,
    String? inputUnit,
    double? milkFat,
    double? milkSnf,
    List<ProductModel>? targetProducts,
    ProductModel? selectedTargetProduct,
    double? targetFat,
    double? targetSnf,
    LabRecord? fetchedLabRecord,
    bool? hasFetchedLabData,
    String? labDataFetchStatus,
    StandardizationResult? result,
    List<StandardizationRecord>? history,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearResult = false,
    bool clearMessages = false,
  }) {
    return StandardizationState(
      selectedDate: selectedDate ?? this.selectedDate,
      milkQuantity: milkQuantity ?? this.milkQuantity,
      inputUnit: inputUnit ?? this.inputUnit,
      milkFat: milkFat ?? this.milkFat,
      milkSnf: milkSnf ?? this.milkSnf,
      targetProducts: targetProducts ?? this.targetProducts,
      selectedTargetProduct: selectedTargetProduct ?? this.selectedTargetProduct,
      targetFat: targetFat ?? this.targetFat,
      targetSnf: targetSnf ?? this.targetSnf,
      fetchedLabRecord: fetchedLabRecord ?? this.fetchedLabRecord,
      hasFetchedLabData: hasFetchedLabData ?? this.hasFetchedLabData,
      labDataFetchStatus: labDataFetchStatus ?? this.labDataFetchStatus,
      result: clearResult ? null : (result ?? this.result),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class StandardizationNotifier extends StateNotifier<StandardizationState> {
  final StandardizationRepository _stdRepo;
  final ProductRepository _productRepo;
  final LabRepository _labRepo;

  StandardizationNotifier(this._stdRepo, this._productRepo, this._labRepo)
      : super(StandardizationState(selectedDate: DateTime.now())) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    // Use official dairy plant standardization target products
    final targets = MilkStandardizationCalculator.standardizationProducts;
    final history = await _stdRepo.getRecords();

    ProductModel? defaultTarget;
    if (targets.isNotEmpty) {
      defaultTarget = targets.firstWhere(
        (p) => p.productName.toLowerCase().contains('std milk'),
        orElse: () => targets.first,
      );
    }

    state = state.copyWith(
      targetProducts: targets,
      selectedTargetProduct: defaultTarget,
      targetFat: defaultTarget?.targetFat ?? 4.5,
      targetSnf: defaultTarget?.targetSnf ?? 8.5,
      history: history,
      isLoading: false,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date, clearResult: true);
  }

  void setMilkQuantity(double qty) {
    state = state.copyWith(milkQuantity: qty, clearResult: true);
  }

  void setMilkFat(double fat) {
    state = state.copyWith(milkFat: fat, clearResult: true);
  }

  void setMilkSnf(double snf) {
    state = state.copyWith(milkSnf: snf, clearResult: true);
  }

  void selectTargetProduct(ProductModel product) {
    state = state.copyWith(
      selectedTargetProduct: product,
      targetFat: product.targetFat ?? 2.5,
      targetSnf: product.targetSnf ?? 9.0,
      clearResult: true,
    );
  }

  void setCustomTargetSpecs({required double fat, required double snf}) {
    state = state.copyWith(
      targetFat: fat,
      targetSnf: snf,
      clearResult: true,
    );
  }

  Future<void> fetchTodayLabData() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    final dateStr = Formatters.formatIsoDate(state.selectedDate);
    final labData = await _labRepo.getTodayLabData(dateStr);

    if (labData != null) {
      state = state.copyWith(
        milkQuantity: labData.milkQuantity,
        milkFat: labData.fatPercent,
        milkSnf: labData.snfPercent,
        fetchedLabRecord: labData,
        hasFetchedLabData: true,
        labDataFetchStatus:
            '✓ Today\'s lab data fetched (${labData.batchOrSiloNo} • Tested at ${labData.sampleTime} by ${labData.analystName})',
        isLoading: false,
        clearResult: true,
      );
    } else {
      state = state.copyWith(
        hasFetchedLabData: false,
        labDataFetchStatus: 'Today\'s lab data not available. Please enter values manually.',
        isLoading: false,
      );
    }
  }

  void calculate() {
    if (state.milkQuantity <= 0) {
      state = state.copyWith(errorMessage: 'Milk quantity must be greater than zero.');
      return;
    }
    if (state.milkFat <= 0 || state.milkFat > 15.0) {
      state = state.copyWith(errorMessage: 'Milk FAT must be between 0.1% and 15.0%.');
      return;
    }
    if (state.milkSnf <= 0 || state.milkSnf > 16.0) {
      state = state.copyWith(errorMessage: 'Milk SNF must be between 5.0% and 16.0%.');
      return;
    }

    final result = MilkStandardizationCalculator.calculate(
      milkQuantity: state.milkQuantity,
      milkFat: state.milkFat,
      milkSnf: state.milkSnf,
      targetProduct: state.selectedTargetProduct?.productName ?? 'Standardized Milk',
      targetFat: state.targetFat,
      targetSnf: state.targetSnf,
      sugarPercent: state.selectedTargetProduct?.targetSugar ?? 0.0,
    );

    state = state.copyWith(
      result: result,
      clearMessages: true,
    );
  }

  Future<bool> saveRecord({
    required String employeeId,
    required String employeeName,
    String notes = '',
  }) async {
    if (state.result == null || state.selectedTargetProduct == null) return false;

    final now = DateTime.now();
    final record = StandardizationRecord(
      recordId: 'STD-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      date: Formatters.formatIsoDate(state.selectedDate),
      time: Formatters.formatTime(now),
      employeeId: employeeId,
      employeeName: employeeName,
      inputMilkQuantity: state.milkQuantity,
      inputUnit: state.inputUnit,
      inputFat: state.milkFat,
      inputSnf: state.milkSnf,
      targetProductId: state.selectedTargetProduct!.productId,
      targetProductName: state.selectedTargetProduct!.productName,
      targetFat: state.targetFat,
      targetSnf: state.targetSnf,
      waterRequired: state.result!.waterRequired,
      smpRequired: state.result!.smpRequired,
      sugarRequired: state.result!.sugarRequired,
      finalQuantity: state.result!.finalQuantity,
      finalFat: state.result!.finalFat,
      finalSnf: state.result!.finalSnf,
      calculationFormulaVersion: state.result!.formulaVersion,
      notes: notes,
      createdAt: now,
    );

    await _stdRepo.saveRecord(record);
    final history = await _stdRepo.getRecords();

    state = state.copyWith(
      history: history,
      successMessage: '✓ Standardization calculation saved to plant historical records.',
    );
    return true;
  }

  Future<void> deleteRecord(String recordId) async {
    await _stdRepo.deleteRecord(recordId);
    final history = await _stdRepo.getRecords();
    state = state.copyWith(history: history);
  }
}

final standardizationProvider =
    StateNotifierProvider<StandardizationNotifier, StandardizationState>((ref) {
  final stdRepo = ref.watch(stdRepositoryProvider);
  final productRepo = ref.watch(productRepositoryProvider);
  final labRepo = ref.watch(labRepositoryProvider);
  return StandardizationNotifier(stdRepo, productRepo, labRepo);
});
