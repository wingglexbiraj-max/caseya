import '../models/product_model.dart';
import '../services/api_service.dart';
import '../services/local_storage_service.dart';

class ProductRepository {
  Future<List<ProductModel>> getProducts() async {
    return ApiService.fetchProducts();
  }

  Future<ProductModel?> getProductById(String id) async {
    final products = await getProducts();
    try {
      return products.firstWhere((p) => p.productId == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProduct(ProductModel product) async {
    await LocalStorageService.addOrUpdateProduct(product);
  }

  Future<void> deleteProduct(String productId) async {
    await LocalStorageService.deleteProduct(productId);
  }
}
