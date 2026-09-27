import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product_model.dart';
import '../repositories/product_repository.dart';
import 'product_calculator_provider.dart';

class ProductsMasterState {
  final List<ProductModel> products;
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const ProductsMasterState({
    this.products = const [],
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  ProductsMasterState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProductsMasterState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearMessages ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearMessages ? null : (successMessage ?? this.successMessage),
    );
  }
}

class ProductsMasterNotifier extends StateNotifier<ProductsMasterState> {
  final ProductRepository _repo;

  ProductsMasterNotifier(this._repo) : super(const ProductsMasterState()) {
    loadProducts();
  }

  Future<void> loadProducts() async {
    state = state.copyWith(isLoading: true);
    final products = await _repo.getProducts();
    state = state.copyWith(products: products, isLoading: false);
  }

  Future<void> saveProduct(ProductModel product) async {
    await _repo.saveProduct(product);
    await loadProducts();
    state = state.copyWith(successMessage: 'Product master updated successfully.');
  }

  Future<void> deleteProduct(String productId) async {
    await _repo.deleteProduct(productId);
    await loadProducts();
    state = state.copyWith(successMessage: 'Product removed from master.');
  }
}

final productsMasterProvider =
    StateNotifierProvider<ProductsMasterNotifier, ProductsMasterState>((ref) {
  final repo = ref.watch(productRepositoryProvider);
  return ProductsMasterNotifier(repo);
});
