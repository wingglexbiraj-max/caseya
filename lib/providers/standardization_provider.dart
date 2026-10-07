import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/standardization_record.dart';
import '../models/lab_record.dart';
import '../models/batch_record_model.dart';
import '../services/milk_standardization_calculator.dart';
import '../services/local_storage_service.dart';
import '../repositories/standardization_repository.dart';
import '../repositories/lab_repository.dart';
import '../repositories/batch_repository.dart';
import '../core/utils/formatters.dart';
import 'product_calculator_provider.dart';
import 'batch_records_provider.dart';

final labRepositoryProvider = Provider((ref) => LabRepository());

class StandardizationState {
  final DateTime selectedDate;
  final double totalBatchRequired; // Total Batch Required (L)
  final double? milkTaken; // Milk Taken (L) - null if auto-calculate
  final bool autoCalculateMilk; // If true, derives milk taken from target fat
  final String inputUnit; // Litres
  final double milkFat; // Present Milk Fat (%)
  final double milkSnf; // Present Milk SNF (%)
  final List<ProductModel> targetProducts;
  final ProductModel? selectedTargetProduct;
  final double targetFat; // Target Fat %
  final double targetSnf; // Target SNF %
  final double sugarPercent; // Sugar %
  final double smpFactor; // Configurable SMP Factor (default 95.0%)
  final String waterCalculationMethod; // 'standard' | 'withSugarDisplacement'
  final bool isReverseMode; // Standard formulation vs Reverse calculation
  final double desiredFinalFat; // Reverse calculation target fat
  final double desiredTargetSnf; // Reverse calculation target SNF
  final String selectedSiloId; // 'RMST' | 'PMST' (Source silo for standardization)
  final LabRecord? fetchedLabRecord;
  final bool hasFetchedLabData;
  final String? labDataFetchStatus;
  final StandardizationResult? result;
  final List<StandardizationRecord> history;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  // Backwards compatibility getter
  double get milkQuantity => milkTaken ?? totalBatchRequired;

  const StandardizationState({
    required this.selectedDate,
    this.totalBatchRequired = 1700.0,
    this.milkTaken = 1400.0,
    this.autoCalculateMilk = false,
    this.inputUnit = 'Litres',
    this.milkFat = 4.30,
    this.milkSnf = 8.33,
    this.targetProducts = const [],
    this.selectedTargetProduct,
    this.targetFat = 3.5,
    this.targetSnf = 8.5,
    this.sugarPercent = 0.0,
    this.smpFactor = 95.0,
    this.waterCalculationMethod = 'standard',
    this.isReverseMode = false,
    this.desiredFinalFat = 3.5,
    this.desiredTargetSnf = 8.5,
    this.selectedSiloId = 'RMST',
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
    double? totalBatchRequired,
    double? milkTaken,
    bool clearMilkTaken = false,
    bool? autoCalculateMilk,
    String? inputUnit,
    double? milkFat,
    double? milkSnf,
    List<ProductModel>? targetProducts,
    ProductModel? selectedTargetProduct,
    double? targetFat,
    double? targetSnf,
    double? sugarPercent,
    double? smpFactor,
    String? waterCalculationMethod,
    bool? isReverseMode,
    double? desiredFinalFat,
    double? desiredTargetSnf,
    String? selectedSiloId,
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
    bool clearSelectedTargetProduct = false,
  }) {
    return StandardizationState(
      selectedDate: selectedDate ?? this.selectedDate,
      totalBatchRequired: totalBatchRequired ?? this.totalBatchRequired,
      milkTaken: clearMilkTaken ? null : (milkTaken ?? this.milkTaken),
      autoCalculateMilk: autoCalculateMilk ?? this.autoCalculateMilk,
      inputUnit: inputUnit ?? this.inputUnit,
      milkFat: milkFat ?? this.milkFat,
      milkSnf: milkSnf ?? this.milkSnf,
      targetProducts: targetProducts ?? this.targetProducts,
      selectedTargetProduct: clearSelectedTargetProduct ? null : (selectedTargetProduct ?? this.selectedTargetProduct),
      targetFat: targetFat ?? this.targetFat,
      targetSnf: targetSnf ?? this.targetSnf,
      sugarPercent: sugarPercent ?? this.sugarPercent,
      smpFactor: smpFactor ?? this.smpFactor,
      waterCalculationMethod: waterCalculationMethod ?? this.waterCalculationMethod,
      isReverseMode: isReverseMode ?? this.isReverseMode,
      desiredFinalFat: desiredFinalFat ?? this.desiredFinalFat,
      desiredTargetSnf: desiredTargetSnf ?? this.desiredTargetSnf,
      selectedSiloId: selectedSiloId ?? this.selectedSiloId,
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
  final LabRepository _labRepo;
  final BatchRepository _batchRepo;

  StandardizationNotifier(
    this._stdRepo,
    this._labRepo,
    this._batchRepo,
  ) : super(StandardizationState(selectedDate: DateTime.now())) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);

    // 1. Load custom plant formula configs if saved
    final config = await LocalStorageService.getStandardizationConfig();
    final double configuredSmpFactor = (config['smp_factor'] as num?)?.toDouble() ?? 95.0;
    final String configuredWaterMethod = config['water_method']?.toString() ?? 'standard';
    final Map<String, dynamic>? productSpecs = config['product_specs'] as Map<String, dynamic>?;

    // 2. Load standard products with custom overrides from settings if configured
    // Strictly keep only the 6 official standardization products
    final targets = MilkStandardizationCalculator.standardizationProducts.map((p) {
      if (productSpecs != null && productSpecs.containsKey(p.productId)) {
        final spec = productSpecs[p.productId] as Map<String, dynamic>;
        return p.copyWith(
          targetSnf: (spec['target_snf'] as num?)?.toDouble() ?? p.targetSnf,
          targetSugar: (spec['sugar_percent'] as num?)?.toDouble() ?? p.targetSugar,
          targetFat: (spec['target_fat'] as num?)?.toDouble() ?? p.targetFat,
        );
      }
      return p;
    }).toList();

    final history = await _stdRepo.getRecords();
    if (!mounted) return;

    state = state.copyWith(
      targetProducts: targets,
      clearSelectedTargetProduct: true,
      smpFactor: configuredSmpFactor,
      waterCalculationMethod: configuredWaterMethod,
      history: history,
      isLoading: false,
    );
  }

  void setDate(DateTime date) {
    state = state.copyWith(selectedDate: date, clearResult: true);
  }

  void setTotalBatch(double qty) {
    state = state.copyWith(totalBatchRequired: qty, clearResult: true);
  }

  void setMilkTaken(double? qty) {
    if (qty == null || qty <= 0) {
      state = state.copyWith(clearMilkTaken: true, clearResult: true);
    } else {
      state = state.copyWith(milkTaken: qty, clearResult: true);
    }
  }

  void setAutoCalculateMilk(bool value) {
    state = state.copyWith(autoCalculateMilk: value, clearResult: true);
  }

  void setMilkFat(double fat) {
    state = state.copyWith(milkFat: fat, clearResult: true);
  }

  void setMilkSnf(double snf) {
    state = state.copyWith(milkSnf: snf, clearResult: true);
  }

  void setTargetFat(double fat) {
    state = state.copyWith(targetFat: fat, clearResult: true);
  }

  void setTargetSnf(double snf) {
    state = state.copyWith(targetSnf: snf, clearResult: true);
  }

  void setSugarPercent(double sugar) {
    state = state.copyWith(sugarPercent: sugar, clearResult: true);
  }

  void setSmpFactor(double factor) {
    state = state.copyWith(smpFactor: factor, clearResult: true);
    _saveCurrentConfig();
  }

  void setWaterMethod(String method) {
    state = state.copyWith(waterCalculationMethod: method, clearResult: true);
    _saveCurrentConfig();
  }

  void setReverseMode(bool reverse) {
    state = state.copyWith(isReverseMode: reverse, clearResult: true);
  }

  void setDesiredFinalFat(double fat) {
    state = state.copyWith(desiredFinalFat: fat, clearResult: true);
  }

  void setDesiredTargetSnf(double snf) {
    state = state.copyWith(desiredTargetSnf: snf, clearResult: true);
  }

  void selectTargetProduct(ProductModel product) {
    final double sugar = product.targetSugar ??
        (product.productName.toLowerCase().contains('lassi')
            ? 15.0
            : (product.productName.toLowerCase().contains('sweet') ? 12.0 : 0.0));

    state = state.copyWith(
      selectedTargetProduct: product,
      targetFat: product.targetFat ?? 3.5,
      targetSnf: product.targetSnf ?? 8.5,
      sugarPercent: sugar,
      desiredFinalFat: product.targetFat ?? 3.5,
      desiredTargetSnf: product.targetSnf ?? 8.5,
      clearResult: true,
      clearMessages: true,
    );
  }

  Future<void> updateProductFormula(
    String productId, {
    required double targetSnf,
    required double sugarPercent,
    double? targetFat,
  }) async {
    final updatedList = state.targetProducts.map((p) {
      if (p.productId == productId) {
        return p.copyWith(
          targetSnf: targetSnf,
          targetSugar: sugarPercent,
          targetFat: targetFat ?? p.targetFat,
        );
      }
      return p;
    }).toList();

    ProductModel? updatedSelected = state.selectedTargetProduct;
    if (updatedSelected?.productId == productId) {
      updatedSelected = updatedSelected!.copyWith(
        targetSnf: targetSnf,
        targetSugar: sugarPercent,
        targetFat: targetFat ?? updatedSelected.targetFat,
      );
    }

    state = state.copyWith(
      targetProducts: updatedList,
      selectedTargetProduct: updatedSelected,
      targetSnf: updatedSelected?.targetSnf ?? state.targetSnf,
      targetFat: updatedSelected?.targetFat ?? state.targetFat,
      sugarPercent: updatedSelected?.targetSugar ?? state.sugarPercent,
      clearResult: true,
    );

    await _saveCurrentConfig();
  }

  Future<void> _saveCurrentConfig() async {
    final Map<String, dynamic> specs = {};
    for (final p in state.targetProducts) {
      specs[p.productId] = {
        'target_snf': p.targetSnf,
        'sugar_percent': p.targetSugar ?? 0.0,
        'target_fat': p.targetFat,
      };
    }

    await LocalStorageService.saveStandardizationConfig({
      'smp_factor': state.smpFactor,
      'water_method': state.waterCalculationMethod,
      'product_specs': specs,
    });
  }

  void setSiloId(String siloId) {
    state = state.copyWith(selectedSiloId: siloId);
  }

  void applyLabReading({
    required String siloName,
    required String testTime,
    required double fat,
    required double snf,
    String? siloId,
  }) {
    final resolvedSiloId = siloId ??
        (siloName.toUpperCase().contains('PMST') ? 'PMST' : 'RMST');
    state = state.copyWith(
      selectedSiloId: resolvedSiloId,
      milkFat: fat,
      milkSnf: snf,
      hasFetchedLabData: true,
      labDataFetchStatus: 'Source: $siloName • Lab tested $testTime',
      clearMessages: true,
    );
    calculate();
  }

  void clearLabDataStatus() {
    state = state.copyWith(
      hasFetchedLabData: false,
      labDataFetchStatus: null,
    );
  }

  Future<void> fetchTodayLabData() async {
    state = state.copyWith(isLoading: true, clearMessages: true);
    final dateStr = Formatters.formatIsoDate(state.selectedDate);
    final labData = await _labRepo.getTodayLabData(dateStr);

    if (labData != null) {
      state = state.copyWith(
        milkFat: labData.fatPercent,
        milkSnf: labData.snfPercent,
        fetchedLabRecord: labData,
        hasFetchedLabData: true,
        labDataFetchStatus:
            '✓ Today\'s QC Lab Data fetched (${labData.batchOrSiloNo} • Tested at ${labData.sampleTime} by ${labData.analystName})',
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

  void clear() {
    state = state.copyWith(
      milkTaken: 1400.0,
      totalBatchRequired: 1700.0,
      milkFat: 4.30,
      milkSnf: 8.33,
      autoCalculateMilk: false,
      clearResult: true,
      clearMessages: true,
    );
  }

  void calculate() {
    // Validation
    if (state.totalBatchRequired <= 0) {
      state = state.copyWith(errorMessage: 'Total Batch Required must be greater than zero.');
      return;
    }
    if (state.milkFat < 0 || state.milkFat > 15.0) {
      state = state.copyWith(errorMessage: 'Milk FAT% cannot be negative and must be within 0% - 15%.');
      return;
    }
    if (state.milkSnf < 0 || state.milkSnf > 16.0) {
      state = state.copyWith(errorMessage: 'Milk SNF% cannot be negative and must be within 0% - 16%.');
      return;
    }
    if (!state.autoCalculateMilk && state.milkTaken != null && state.milkTaken! > state.totalBatchRequired) {
      state = state.copyWith(
        errorMessage: 'Milk Taken (${Formatters.formatDecimal(state.milkTaken!)} L) cannot be greater than Total Batch (${Formatters.formatDecimal(state.totalBatchRequired)} L).',
      );
      return;
    }

    final double? effectiveMilkTaken = state.autoCalculateMilk ? null : state.milkTaken;

    StandardizationResult result;
    if (state.isReverseMode) {
      result = MilkStandardizationCalculator.reverseCalculate(
        totalBatch: state.totalBatchRequired,
        milkTaken: effectiveMilkTaken,
        presentFat: state.milkFat,
        presentSnf: state.milkSnf,
        desiredFinalFat: state.desiredFinalFat,
        desiredTargetSnf: state.desiredTargetSnf,
        sugarPercent: state.sugarPercent,
        smpFactor: state.smpFactor,
        targetProduct: state.selectedTargetProduct?.productName ?? 'Custom Specification',
        waterCalculationMethod: state.waterCalculationMethod,
      );
    } else {
      result = MilkStandardizationCalculator.calculate(
        totalBatch: state.totalBatchRequired,
        milkTaken: effectiveMilkTaken,
        presentFat: state.milkFat,
        presentSnf: state.milkSnf,
        targetProduct: state.selectedTargetProduct?.productName ?? 'Standardized Batch',
        targetFat: state.targetFat,
        targetSnf: state.targetSnf,
        sugarPercent: state.sugarPercent,
        smpFactor: state.smpFactor,
        waterCalculationMethod: state.waterCalculationMethod,
      );
    }

    state = state.copyWith(
      result: result,
      clearMessages: true,
    );
  }

  Future<bool> saveRecord({
    required String employeeId,
    required String employeeName,
    String notes = '',
    String? testedBy,
  }) async {
    // 1. Ensure target product is assigned
    if (state.selectedTargetProduct == null) {
      if (state.targetProducts.isNotEmpty) {
        selectTargetProduct(state.targetProducts.first);
      } else if (MilkStandardizationCalculator.standardizationProducts.isNotEmpty) {
        selectTargetProduct(MilkStandardizationCalculator.standardizationProducts.first);
      }
    }

    // 2. Ensure calculation result is ready
    if (state.result == null) {
      calculate();
    }

    final res = state.result;
    final product = state.selectedTargetProduct;
    if (res == null || product == null) {
      state = state.copyWith(
        errorMessage: state.errorMessage ?? 'Please enter valid batch numbers and calculate before recording.',
      );
      return false;
    }

    final now = DateTime.now();
    final recordId = 'STD-${const Uuid().v4().substring(0, 8).toUpperCase()}';

    // 1. Save to Standardization Records (Historical audit log)
    final record = StandardizationRecord(
      recordId: recordId,
      date: Formatters.formatIsoDate(state.selectedDate),
      time: Formatters.formatTime(now),
      employeeId: employeeId,
      employeeName: employeeName,
      totalBatchRequired: res.totalBatch,
      inputMilkQuantity: res.milkTaken,
      inputUnit: state.inputUnit,
      inputFat: res.presentFat,
      inputSnf: res.presentSnf,
      targetProductId: product.productId,
      targetProductName: product.productName,
      targetFat: res.targetFat,
      targetSnf: res.targetSnf,
      availableFatKg: res.availableFatKg,
      availableSnfKg: res.availableSnfKg,
      requiredSnfKg: res.requiredSnfKg,
      snfDeficitKg: res.snfDeficitKg,
      waterRequired: res.waterRequired,
      smpRequired: res.smpRequired,
      sugarRequired: res.sugarRequired,
      finalQuantity: res.finalQuantity,
      finalFat: res.finalFat,
      finalSnf: res.finalSnf,
      smpFactor: res.smpFactor,
      calculationFormulaVersion: res.formulaVersion,
      siloId: state.selectedSiloId,
      notes: notes,
      testedBy: (testedBy != null && testedBy.trim().isNotEmpty) ? testedBy.trim() : employeeName,
      createdAt: now,
    );

    await _stdRepo.saveRecord(record);

    // 2. Save directly to Batch Records section with all ingredient components!
    final batchId = 'BATCH-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final batchIngredients = <BatchIngredientModel>[
      BatchIngredientModel(
        id: const Uuid().v4(),
        batchId: batchId,
        ingredientName: '${state.selectedSiloId} Milk (${Formatters.formatPercent(res.presentFat)} F, ${Formatters.formatPercent(res.presentSnf)} SNF)',
        quantity: res.milkTaken,
        unit: 'L',
      ),
      if (res.smpRequired > 0.0)
        BatchIngredientModel(
          id: const Uuid().v4(),
          batchId: batchId,
          ingredientName: 'Skimmed Milk Powder (SMP ${Formatters.formatDecimal(res.smpFactor)}% SNF)',
          quantity: double.parse(res.smpRequired.toStringAsFixed(2)),
          unit: 'kg',
        ),
      if (res.sugarRequired > 0.0)
        BatchIngredientModel(
          id: const Uuid().v4(),
          batchId: batchId,
          ingredientName: 'Granulated Sugar (${Formatters.formatPercent(res.sugarPercent)})',
          quantity: double.parse(res.sugarRequired.toStringAsFixed(2)),
          unit: 'kg',
        ),
      if (res.waterRequired > 0.0)
        BatchIngredientModel(
          id: const Uuid().v4(),
          batchId: batchId,
          ingredientName: 'Potable Process Water',
          quantity: double.parse(res.waterRequired.toStringAsFixed(2)),
          unit: 'L',
        ),
    ];

    final batchRecord = BatchRecordModel(
      id: batchId,
      productionDate: Formatters.formatIsoDate(state.selectedDate),
      productId: product.productId,
      productName: product.productName,
      batchNumber: 'STD-${now.millisecondsSinceEpoch.toString().substring(7)}',
      batchQuantity: res.totalBatch,
      batchUnit: 'L',
      shift: 'General',
      operatorName: employeeName,
      siloId: state.selectedSiloId,
      notes: notes.isNotEmpty
          ? '$notes [Silo: ${state.selectedSiloId}]'
          : 'Standardized Batch: ${state.selectedSiloId} Milk ${Formatters.formatPercent(res.presentFat)} F, ${Formatters.formatPercent(res.presentSnf)} SNF → Target Batch: ${Formatters.formatSmart(res.totalBatch)} L (Final Fat ${Formatters.formatPercent(res.finalFat)}, Final SNF ${Formatters.formatPercent(res.finalSnf)}). SMP: ${Formatters.formatDecimal(res.smpRequired)} kg, Water: ${Formatters.formatDecimal(res.waterRequired)} L. [Silo: ${state.selectedSiloId}]',
      ingredients: batchIngredients,
      createdAt: now,
      updatedAt: now,
    );

    await _batchRepo.addBatch(batchRecord);

    final history = await _stdRepo.getRecords();
    state = state.copyWith(
      history: history,
      successMessage: '✓ Standardization calculation saved and added to Batch Records archive.',
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
  final labRepo = ref.watch(labRepositoryProvider);
  final batchRepo = ref.watch(batchRepositoryProvider);
  return StandardizationNotifier(stdRepo, labRepo, batchRepo);
});
