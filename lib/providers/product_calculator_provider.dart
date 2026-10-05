import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/product_model.dart';
import '../models/product_calculation_record.dart';
import '../services/calculation_service.dart';
import '../repositories/product_repository.dart';
import '../repositories/standardization_repository.dart';
import '../core/utils/formatters.dart';

final productRepositoryProvider = Provider((ref) => ProductRepository());
final stdRepositoryProvider = Provider((ref) => StandardizationRepository());

class ProductCalculatorState {
  final List<ProductModel> products;
  final ProductModel? selectedProduct;
  final String selectedInputMode;
  final double enteredQuantity;
  final ProductCalculationResult? result;
  final List<ProductCalculationRecord> history;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ProductCalculatorState({
    this.products = const [],
    this.selectedProduct,
    this.selectedInputMode = 'Pieces',
    this.enteredQuantity = 0.0,
    this.result,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ProductCalculatorState copyWith({
    List<ProductModel>? products,
    ProductModel? selectedProduct,
    String? selectedInputMode,
    double? enteredQuantity,
    ProductCalculationResult? result,
    List<ProductCalculationRecord>? history,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearResult = false,
    bool clearMessages = false,
    bool clearSelectedProduct = false,
  }) {
    return ProductCalculatorState(
      products: products ?? this.products,
      selectedProduct: clearSelectedProduct ? null : (selectedProduct ?? this.selectedProduct),
      selectedInputMode: selectedInputMode ?? this.selectedInputMode,
      enteredQuantity: enteredQuantity ?? this.enteredQuantity,
      result: clearResult ? null : (result ?? this.result),
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProductCalculatorNotifier extends StateNotifier<ProductCalculatorState> {
  final ProductRepository _productRepo;
  final StandardizationRepository _stdRepo;

  ProductCalculatorNotifier(this._productRepo, this._stdRepo)
      : super(const ProductCalculatorState()) {
    init();
  }

  Future<void> init() async {
    state = state.copyWith(isLoading: true);
    final products = await _productRepo.getProducts();
    final history = await _stdRepo.getProductCalcRecords();

    state = state.copyWith(
      products: products,
      clearSelectedProduct: true,
      selectedInputMode: 'Pieces',
      history: history,
      isLoading: false,
    );
  }

  void selectProduct(ProductModel? product) {
    if (product == null) {
      state = state.copyWith(
        clearSelectedProduct: true,
        clearResult: true,
        clearMessages: true,
      );
      return;
    }
    // If current mode is not allowed for the new product, switch to its first allowed mode
    String newMode = state.selectedInputMode;
    if (!product.allowedInputModes.contains(newMode)) {
      newMode = product.allowedInputModes.isNotEmpty
          ? product.allowedInputModes.first
          : 'Pieces';
    }

    ProductCalculationResult? result;
    if (state.enteredQuantity > 0) {
      result = CalculationService.calculateProduct(
        product: product,
        inputMode: newMode,
        inputQuantity: state.enteredQuantity,
      );
    }

    state = state.copyWith(
      selectedProduct: product,
      selectedInputMode: newMode,
      result: result,
      clearResult: result == null,
      clearMessages: true,
    );
  }

  void setInputMode(String mode) {
    ProductCalculationResult? result;
    if (state.selectedProduct != null && state.enteredQuantity > 0) {
      result = CalculationService.calculateProduct(
        product: state.selectedProduct!,
        inputMode: mode,
        inputQuantity: state.enteredQuantity,
      );
    }
    state = state.copyWith(
      selectedInputMode: mode,
      result: result,
      clearResult: result == null,
      clearMessages: true,
    );
  }

  void setQuantity(double qty) {
    ProductCalculationResult? result;
    if (state.selectedProduct != null && qty > 0) {
      result = CalculationService.calculateProduct(
        product: state.selectedProduct!,
        inputMode: state.selectedInputMode,
        inputQuantity: qty,
      );
    }
    state = state.copyWith(
      enteredQuantity: qty,
      result: result,
      clearResult: result == null,
      clearMessages: true,
    );
  }

  void calculate() {
    if (state.selectedProduct == null) {
      state = state.copyWith(errorMessage: 'Please select a product first.');
      return;
    }
    if (state.enteredQuantity <= 0) {
      state = state.copyWith(errorMessage: 'Please enter a valid quantity greater than zero.');
      return;
    }

    final result = CalculationService.calculateProduct(
      product: state.selectedProduct!,
      inputMode: state.selectedInputMode,
      inputQuantity: state.enteredQuantity,
    );

    state = state.copyWith(
      result: result,
      clearMessages: true,
    );
  }

  Future<bool> saveCalculation({required String employeeId, required String employeeName}) async {
    if (state.result == null || state.selectedProduct == null) return false;

    final now = DateTime.now();
    final record = ProductCalculationRecord(
      recordId: 'PC-${const Uuid().v4().substring(0, 8).toUpperCase()}',
      date: Formatters.formatIsoDate(now),
      time: Formatters.formatTime(now),
      employeeId: employeeId,
      employeeName: employeeName,
      productId: state.selectedProduct!.productId,
      productName: state.selectedProduct!.productName,
      productNameWithQuantity: state.result!.productNameWithQuantity,
      inputMode: state.selectedInputMode,
      inputQuantity: state.enteredQuantity,
      pieces: state.result!.pieces,
      crates: state.result!.crates,
      packingNeeded: state.result!.packingNeeded,
      volumeLitres: state.result!.volumeLitres,
      weightKg: state.result!.weightKg,
      totalQuantityDisplay: state.result!.totalQuantityDisplay,
      pricePerPiece: state.result!.pricePerPiece,
      totalPrice: state.result!.totalPrice,
      totalPriceDisplay: state.result!.totalPriceDisplay,
      breakdownText: state.result!.summaryText,
      createdAt: now,
    );

    await _stdRepo.saveProductCalcRecord(record);
    final history = await _stdRepo.getProductCalcRecords();

    state = state.copyWith(
      history: history,
      successMessage: '✓ Calculation record saved to plant operational history.',
    );
    return true;
  }

  void resetForm() {
    state = state.copyWith(
      clearSelectedProduct: true,
      selectedInputMode: 'Pieces',
      enteredQuantity: 0.0,
      clearResult: true,
      clearMessages: true,
    );
  }
}

final productCalculatorProvider =
    StateNotifierProvider<ProductCalculatorNotifier, ProductCalculatorState>((ref) {
  final productRepo = ref.watch(productRepositoryProvider);
  final stdRepo = ref.watch(stdRepositoryProvider);
  return ProductCalculatorNotifier(productRepo, stdRepo);
});
